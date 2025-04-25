import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AITaskController {
  late String _openaiApiKey;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  AITaskController() {
    _initializeApiKey();
  }

  Future<void> _initializeApiKey() async {
    if (kIsWeb) {
      // Web: Fetch OpenAI API key from Firebase Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults({'openai_api_key': ''});
      await remoteConfig.fetchAndActivate();
      _openaiApiKey = remoteConfig.getString('openai_api_key');
    } else {
      // Non-web (Android/iOS): Load OpenAI API key from .env file
      _openaiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    }

    print("DEBUG: OpenAI API Key loaded: $_openaiApiKey");
  }

  Future<List<String>> generateSubtasks(String bigTask) async {
    // Wait for the API key initialization (needed for web)
    await _initializeApiKey();
    
    print('DEBUG: Using OpenAI GPT-3.5 Turbo');
    print('DEBUG: Input task: $bigTask');

    if (_openaiApiKey.isEmpty) {
      return ['Error: Missing API key. Please try again later.'];
    }

    if (_isGenericTask(bigTask)) {
      print('DEBUG: Task was too generic. Using fallback.');
      return _getSmartFallback(bigTask);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_openaiApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that breaks down tasks into practical subtasks.'
            },
            {
              'role': 'user',
              'content': '''
Break down the following task into clear, actionable steps:

Task: "$bigTask"

Instructions:
- Provide 5 to 7 concise, actionable, and task-specific steps.
- Each step must be practical and easy to follow.
- Ensure that each step is distinct, actionable, and adds value to the completion of the task.
- Avoid using overly general advice like "start the task" or "complete the task".
- Ensure the steps are tailored to the specific task, including tools, resources, or strategies needed for each action.

Steps:
'''
            }
          ],
          'temperature': 0.5,
          'max_tokens': 500,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        print("🧪 Raw model output:\n$content");

        final processedSteps = processSubtasks(content, bigTask);
        if (_areStepsLowQuality(processedSteps, bigTask)) {
          print("⚠️ Low quality steps detected. Using fallback.");
          return _getSmartFallback(bigTask);
        }

        return processedSteps;
      } else {
        print("❌ API error. Using fallback.");
        return _getSmartFallback(bigTask);
      }
    } catch (e) {
      print('Request error: $e');
      return _getSmartFallback(bigTask);
    }
  }

  List<String> processSubtasks(String text, String originalTask) {
    final promptEnd = "Steps:";
    if (text.contains(promptEnd)) {
      text = text.substring(text.indexOf(promptEnd) + promptEnd.length);
    }

    List<String> steps = _parseWithRegex(text);
    if (steps.isEmpty || steps.length < 3) {
      print("⚠️ Regex parsing produced insufficient results, trying line split.");
      steps = _parseWithLineSplit(text);
    }
    if (steps.isEmpty || steps.length < 3) {
      print("⚠️ Line split failed, trying sentence splitting.");
      steps = _parseWithSentenceSplit(text);
    }

    steps = _filterVagueSteps(steps);
    steps = _filterAndRemoveRepetitions(steps);

    print("✅ Matched steps: $steps");

    if (steps.isEmpty || steps.length < 3 || _areStepsLowQuality(steps, originalTask)) {
      print("❌ No usable steps found or low quality. Using fallback.");
      return _getSmartFallback(originalTask);
    }

    return steps.length > 7 ? steps.sublist(0, 7) : steps;
  }

  List<String> _parseWithRegex(String text) {
    final regex = RegExp(r'(\d+[\.\):]?\s*|\*|\-)\s*(.*)');
    final matches = regex.allMatches(text);

    List<String> steps = [];
    for (final match in matches) {
      if (match.groupCount > 1) {
        final step = match.group(2)?.trim() ?? '';
        if (step.isNotEmpty) {
          steps.add(step);
        }
      }
    }

    return steps;
  }

  List<String> _parseWithLineSplit(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length > 3)
        .map((line) => line.replaceFirst(RegExp(r'^\d+[\.\):]?\s*|\*\s*|\-\s*'), '').trim())
        .toList();
  }

  List<String> _parseWithSentenceSplit(String text) {
    return text
        .split('.')
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty)
        .toList();
  }

  List<String> _getSmartFallback(String task) {
    final t = task.toLowerCase();

    if (t.contains('birthday party') || t.contains('organize party') || t.contains('plan party')) {
      return [
        'Choose a date and time for the party',
        'Create a guest list and send invitations',
        'Select a theme and purchase decorations',
        'Order or bake a cake and prepare food',
        'Plan games and entertainment activities',
        'Arrange for music and sound system',
        'Set up the venue on party day',
      ];
    } else if (t.contains('laundry') || t.contains('wash clothes')) {
      return [
        'Sort clothes by color and fabric type',
        'Check pockets and remove items',
        'Pre-treat stains with stain remover',
        'Load washer with appropriate detergent',
        'Select correct wash settings',
        'Transfer to dryer or hang to dry',
        'Fold and store clean clothes',
      ];
    } else {
      return [
        'Break down the task into smaller parts',
        'Gather necessary tools and materials',
        'Start with the first manageable action',
        'Work step-by-step through each portion',
        'Take short breaks when needed',
        'Track your progress and adjust as needed',
        'Complete final details and review your work',
      ];
    }
  }

  bool _isGenericTask(String task) {
    return task.toLowerCase().contains('task') || task.toLowerCase().contains('thing');
  }

  List<String> _filterVagueSteps(List<String> steps) {
    return steps.where((step) => step.length > 5).toList();
  }

  List<String> _filterAndRemoveRepetitions(List<String> steps) {
    Set<String> uniqueSteps = {};
    return steps.where((step) => uniqueSteps.add(step)).toList();
  }

  bool _areStepsLowQuality(List<String> steps, String task) {
    return steps.length < 3 || steps.any((step) => step.contains('start') || step.contains('finish'));
  }
}
