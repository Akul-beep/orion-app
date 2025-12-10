import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/feedback_service.dart';
import '../../services/analytics_service.dart';

/// Feedback Board Screen - Users can submit and upvote feature requests
class FeedbackBoardScreen extends StatefulWidget {
  const FeedbackBoardScreen({super.key});

  @override
  State<FeedbackBoardScreen> createState() => _FeedbackBoardScreenState();
}

class _FeedbackBoardScreenState extends State<FeedbackBoardScreen> {
  final List<Map<String, dynamic>> _feedbackItems = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'open', 'in_progress', 'completed'

  @override
  void initState() {
    super.initState();
    _loadFeedback();
    AnalyticsService.trackScreenView('FeedbackBoardScreen');
  }

  Future<void> _loadFeedback() async {
    setState(() => _isLoading = true);
    try {
      await FeedbackService.init();
      final feedback = await FeedbackService.getFeedback(
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      setState(() {
        _feedbackItems.clear();
        _feedbackItems.addAll(feedback);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading feedback: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSubmitFeedbackDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'feature_request';
    String selectedPriority = 'medium';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Submit Feedback'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Brief title for your feedback',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe your feature request or feedback...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  maxLength: 1000,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'feature_request', child: Text('Feature Request')),
                    DropdownMenuItem(value: 'bug_report', child: Text('Bug Report')),
                    DropdownMenuItem(value: 'improvement', child: Text('Improvement')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value ?? 'feature_request');
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedPriority = value ?? 'medium');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Close dialog immediately
                Navigator.pop(context);
                
                // Show immediate success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Feedback submitted!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                
                // Submit in background (non-blocking)
                FeedbackService.submitFeedback(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  category: selectedCategory,
                  priority: selectedPriority,
                ).then((success) {
                  if (context.mounted) {
                    if (success) {
                      _loadFeedback(); // Reload list silently
                    } else {
                      // Show error if it failed silently
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Feedback saved locally. Will sync when online.'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      _loadFeedback(); // Still reload to show local feedback
                    }
                  }
                }).catchError((e) {
                  print('Error submitting feedback: $e');
                  // Don't show error to user - it's saved locally anyway
                  if (context.mounted) {
                    _loadFeedback();
                  }
                });
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpvote(String feedbackId, int currentUpvotes) async {
    final success = await FeedbackService.upvoteFeedback(feedbackId);
    if (success) {
      _loadFeedback(); // Reload to update upvote count
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Board'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('open', 'Open'),
                        const SizedBox(width: 8),
                        _buildFilterChip('in_progress', 'In Progress'),
                        const SizedBox(width: 8),
                        _buildFilterChip('completed', 'Completed'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Feedback list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _feedbackItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.feedback_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No feedback yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to share your ideas!',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFeedback,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _feedbackItems.length,
                          itemBuilder: (context, index) {
                            final item = _feedbackItems[index];
                            return _buildFeedbackCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitFeedbackDialog,
        icon: const Icon(Icons.add),
        label: const Text('Submit Feedback'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _loadFeedback();
      },
      selectedColor: const Color(0xFF1E3A8A).withOpacity(0.2),
      checkmarkColor: const Color(0xFF1E3A8A),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'open';
    final upvotes = item['upvotes'] ?? 0;
    final feedbackId = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.build;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.circle_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showFeedbackDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['title'] ?? 'Untitled',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FutureBuilder<bool>(
                    future: FeedbackService.hasUserUpvoted(feedbackId),
                    builder: (context, snapshot) {
                      final hasUpvoted = snapshot.data ?? false;
                      return InkWell(
                        onTap: () => _handleUpvote(feedbackId, upvotes),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: hasUpvoted
                                ? const Color(0xFF1E3A8A).withOpacity(0.1)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasUpvoted
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 18,
                                color: hasUpvoted
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                upvotes.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: hasUpvoted
                                      ? const Color(0xFF1E3A8A)
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  if (item['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (item['category'] as String).replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (item['created_at'] != null)
                    Text(
                      _formatDate(item['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['title'] ?? 'Untitled',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['description'] ?? '',
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildDetailChip('Category', item['category'] ?? 'N/A'),
                        const SizedBox(width: 8),
                        _buildDetailChip('Priority', item['priority'] ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: ${(item['status'] ?? 'open').toString().replaceAll('_', ' ').toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item['created_at'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Submitted: ${_formatDate(item['created_at'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${value.toString().replaceAll('_', ' ').toUpperCase()}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    try {
      if (dateString is String) {
        final date = DateTime.parse(dateString);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays == 0) {
          return 'Today';
        } else if (difference.inDays == 1) {
          return 'Yesterday';
        } else if (difference.inDays < 7) {
          return '${difference.inDays} days ago';
        } else {
          return '${date.day}/${date.month}/${date.year}';
        }
      }
    } catch (e) {
      return 'Recently';
    }
    return 'Recently';
  }
}

