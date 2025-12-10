import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/posthog_surveys_service.dart';

/// Widget to display PostHog surveys (NPS, feedback, etc.)
class PostHogSurveyWidget extends StatefulWidget {
  final Map<String, dynamic> survey;
  
  const PostHogSurveyWidget({
    super.key,
    required this.survey,
  });

  @override
  State<PostHogSurveyWidget> createState() => _PostHogSurveyWidgetState();
}

class _PostHogSurveyWidgetState extends State<PostHogSurveyWidget> {
  int? _selectedScore;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (_selectedScore == null) return;
    
    setState(() => _isSubmitting = true);
    
    final success = await PostHogSurveysService.submitNPS(
      score: _selectedScore!,
      feedback: _feedbackController.text.trim(),
    );
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Thank you for your feedback!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surveyType = widget.survey['type'] ?? 'nps';
    
    if (surveyType == 'nps') {
      return _buildNPSSurvey();
    }
    
    // Add other survey types here
    return _buildGenericSurvey();
  }

  Widget _buildNPSSurvey() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.survey['question'] ?? 'How likely are you to recommend Orion StockSense to a friend?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // Score selector (0-10)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(11, (index) {
                final isSelected = _selectedScore == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedScore = index),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF1E3A8A)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Not likely',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Very likely',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Optional feedback field
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                labelText: 'Tell us more (optional)',
                hintText: 'What do you love? What could be better?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedScore != null && !_isSubmitting
                    ? _submitResponse
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe later'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericSurvey() {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.survey['name'] ?? 'Survey',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Survey implementation coming soon...'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Service to check and show surveys at appropriate times
class SurveyPrompter {
  /// Check if we should show a survey and show it
  static Future<void> checkAndShowSurvey(BuildContext context) async {
    try {
      // Check for NPS survey
      final shouldShowNPS = await PostHogSurveysService.shouldShowNPSSurvey();
      
      if (shouldShowNPS && context.mounted) {
        // Show NPS survey
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PostHogSurveyWidget(
            survey: {
              'type': 'nps',
              'id': 'nps_survey',
              'question': 'How likely are you to recommend Orion StockSense to a friend?',
            },
          ),
        );
      }
    } catch (e) {
      print('Error checking surveys: $e');
    }
  }
}

