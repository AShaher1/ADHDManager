import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_task_service.dart';
import '../controllers/task_controller.dart';
import '../controllers/ai_task_controller.dart';
import '../models/task_model.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskController _taskController = TaskController();
  final AITaskController _aiController = AITaskController();
  final TextEditingController _taskInputController = TextEditingController();

  final FirestoreTaskService _firestoreTaskService = FirestoreTaskService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _checkUserAuthentication();
  }

  Future<void> _checkUserAuthentication() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadTasks(user.uid);
    }
  }

  Future<void> _loadTasks(String userId) async {
    try {
      final tasks = await _firestoreTaskService.getUserTasks(userId);
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: $e')),
      );
    }
  }

  Future<void> _handleAddTask() async {
    final title = _taskInputController.text.trim();
    if (title.isEmpty) return;

    setState(() {
  _isLoading = true;
  _taskInputController.text = 'Thinking... 🤖';
});


    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final subtasks = await _aiController.generateSubtasks(title);
      final newTask = Task(
        title: title,
        subtasks: subtasks,
        isDoneList: List.filled(subtasks.length, false),
      );

      await _firestoreTaskService.addTask(newTask);
      _taskInputController.clear();
      await _loadTasks(user.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleSubtask(Task task, int index) async {
    await _taskController.toggleSubtask(task, index);
    final user = _auth.currentUser;
    if (user != null) {
      await _loadTasks(user.uid);
    }
  }

  Future<void> _editTask(Task task) async {
    final controller = TextEditingController(text: task.title);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Task'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final updated = Task(
        id: task.id,
        title: result.trim(),
        subtasks: task.subtasks,
        isDoneList: task.isDoneList,
      );
      await _firestoreTaskService.updateTask(updated);
      final user = _auth.currentUser;
      if (user != null) {
        await _loadTasks(user.uid);
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    if (task.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreTaskService.deleteTask(task.id!);
      final user = _auth.currentUser;
      if (user != null) {
        await _loadTasks(user.uid);
      }
    }
  }

  Future<void> _deleteAllCompletedTasks() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _taskController.deleteAllCompletedTasks();
      await _loadTasks(user.uid);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All completed tasks have been deleted.')),
    );
  }

  List<Task> _filteredTasks() {
    if (_filter == 'All') return _tasks;
    if (_filter == 'Completed') {
      return _tasks.where((t) => t.isDoneList.every((e) => e)).toList();
    } else {
      return _tasks.where((t) => t.isDoneList.any((e) => !e)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Tasks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Need a quick pick-me-up?',
            onPressed: () {
              Navigator.pushNamed(context, '/advice');
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sign Out',
            onPressed: () async {
              await _auth.signOut();
              setState(() {
                _tasks = [];
              });
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskInputController,
                      decoration: const InputDecoration(
                        hintText: 'Enter a big task...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _handleAddTask,
                          child: const Text('Add'),
                        ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter and Delete Completed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _filter,
                    onChanged: (val) {
                      setState(() => _filter = val!);
                    },
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("Delete All Completed"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _deleteAllCompletedTasks,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Task List
              if (filtered.isEmpty)
                const Center(child: Text("No tasks match your filter."))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return TaskTile(
                      task: task,
                      onToggle: (i) => _toggleSubtask(task, i),
                      onEdit: () => _editTask(task),
                      onDelete: () => _deleteTask(task),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
