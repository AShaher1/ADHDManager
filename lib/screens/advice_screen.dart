import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_background/animated_background.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb

class AdviceScreen extends StatefulWidget {
  const AdviceScreen({Key? key}) : super(key: key);

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> with TickerProviderStateMixin {
  String quote = "Loading mindfulness quote...";
  String author = "";
  double _opacity = 0.0;

  late AnimationController _fadeController;

  // Hardcoded mindfulness quotes for web
  final List<Map<String, String>> webQuotes = [
    {'quote': '“The mind is everything. What you think you become.”', 'author': 'Buddha'},
    {'quote': '“Mindfulness is a way of befriending ourselves and our experience.”', 'author': 'Jon Kabat-Zinn'},
    {'quote': '“You can\'t stop the waves, but you can learn to surf.”', 'author': 'Jon Kabat-Zinn'},
    {'quote': '“The greatest weapon against stress is our ability to choose one thought over another.”', 'author': 'William James'},
    {'quote': '“The only way to deal with this life meaningfully is to find one\'s passion and pursue it.”', 'author': 'Viktor Frankl'},
    {'quote': '“Be yourself; everyone else is already taken.”', 'author': 'Oscar Wilde'},
    {'quote': '“Don\'t believe everything you think.”', 'author': 'Unknown'},
    {'quote': '“When you realize nothing is lacking, the whole world belongs to you.”', 'author': 'Lao Tzu'},
    {'quote': '“In the process of letting go you will lose many things from the past, but you will find yourself.”', 'author': 'Deepak Chopra'},
    {'quote': '“True freedom is the ability to let go of who we think we are, and be who we are.”', 'author': 'Tara Brach'},
    {'quote': '“The mind that opens to a new idea never returns to its original size.”', 'author': 'Albert Einstein'},
    {'quote': '“Your task is not to seek for love, but merely to seek and find all the barriers within yourself that you have built against it.”', 'author': 'Rumi'},
    {'quote': '“The present moment is the only moment available to us, and it is the door to all moments.”', 'author': 'Thich Nhat Hanh'},
    {'quote': '“To live in the present moment is the only way to experience true freedom.”', 'author': 'Eckhart Tolle'},
    {'quote': '“Mindfulness means being awake. It means knowing what you are doing.”', 'author': 'Jon Kabat-Zinn'}
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    fetchQuote();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchQuote() async {
    setState(() => _opacity = 0.0); // Start fade-out before fetch

    try {
      if (kIsWeb) {
        // If the app is running on the web, use the hardcoded quotes
        final randomQuote = (webQuotes..shuffle()).first;  // Randomize the quote
        setState(() {
          quote = randomQuote['quote']!;
          author = randomQuote['author']!;
        });
      } else {
        // For mobile (Android/iOS), fetch the quote from the ZenQuotes API
        final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            quote = data[0]['q'];
            author = data[0]['a'];
          });
        } else {
          setState(() {
            quote = "Oops! Couldn't fetch a quote.";
            author = "";
            _opacity = 1.0;
          });
        }
      }

      await Future.delayed(const Duration(milliseconds: 100)); // Smooth transition
      setState(() => _opacity = 1.0); // Fade-in
    } catch (e) {
      setState(() {
        quote = "Something went wrong. Please try again later.";
        author = "";
        _opacity = 1.0;
      });
      print('Error fetching quote: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Mindful Moments",
          style: GoogleFonts.playfairDisplay(
            textStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: ParticleOptions(
            baseColor: Colors.blueGrey.shade100,
            spawnOpacity: 0.2,
            opacityChangeRate: 0.25,
            minOpacity: 0.1,
            maxOpacity: 0.4,
            spawnMinSpeed: 10.0,
            spawnMaxSpeed: 30.0,
            spawnMinRadius: 2.0,
            spawnMaxRadius: 6.0,
            particleCount: 60,
          ),
        ),
        vsync: this,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            '"$quote"',
                            style: GoogleFonts.lora(
                              textStyle: const TextStyle(
                                fontSize: 22,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          if (author.isNotEmpty)
                            Text(
                              "- $author",
                              style: GoogleFonts.robotoSlab(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: fetchQuote,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8E0FF),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
