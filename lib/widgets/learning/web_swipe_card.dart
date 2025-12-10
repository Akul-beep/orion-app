import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebSwipeCard extends StatefulWidget {
  final String question;
  final String answer;
  final String explanation;
  final String type; // 'stock', 'price', 'risk', 'pattern'
  final VoidCallback? onCorrect;
  final VoidCallback? onIncorrect;

  const WebSwipeCard({
    Key? key,
    required this.question,
    required this.answer,
    required this.explanation,
    required this.type,
    this.onCorrect,
    this.onIncorrect,
  }) : super(key: key);

  @override
  _WebSwipeCardState createState() => _WebSwipeCardState();
}

class _WebSwipeCardState extends State<WebSwipeCard> {
  bool _showAnswer = false;
  bool _showFeedback = false;
  bool _isCorrect = false;

  void _revealAnswer() {
    setState(() {
      _showAnswer = true;
    });
  }

  void _giveFeedback(bool correct) {
    setState(() {
      _isCorrect = correct;
      _showFeedback = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (correct) {
        widget.onCorrect?.call();
      } else {
        widget.onIncorrect?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      color: const Color(0xFF2C2C54),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.question,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            if (_showAnswer)
              Column(
                children: [
                  Text(
                    'Answer: ${widget.answer}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.explanation,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _giveFeedback(true),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          'I Got It!',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _giveFeedback(false),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: Text(
                          'Teach Me!',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _revealAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Reveal Answer',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            if (_showFeedback)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _isCorrect ? 'Awesome! Keep it up!' : 'No worries, you\'ll get it!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isCorrect ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}