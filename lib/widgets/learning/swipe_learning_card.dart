import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SwipeLearningCard extends StatefulWidget {
  final String question;
  final String answer;
  final String explanation;
  final String type; // 'stock', 'price', 'risk', 'pattern'
  final VoidCallback? onCorrect;
  final VoidCallback? onIncorrect;

  const SwipeLearningCard({
    Key? key,
    required this.question,
    required this.answer,
    required this.explanation,
    required this.type,
    this.onCorrect,
    this.onIncorrect,
  }) : super(key: key);

  @override
  _SwipeLearningCardState createState() => _SwipeLearningCardState();
}

class _SwipeLearningCardState extends State<SwipeLearningCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;

  double _dragDistance = 0;
  bool _isDragging = false;
  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * _dragDistance / 100,
              child: Transform.translate(
                offset: Offset(_dragDistance, 0),
                child: _buildCard(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _showFeedback ? _buildFeedback() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildQuestionHeader(),
          const SizedBox(height: 24),
          _buildQuestionContent(),
          const SizedBox(height: 32),
          _buildSwipeInstructions(),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getTypeLabel(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getTypeColor(),
            ),
          ),
        ),
        Icon(
          _getTypeIcon(),
          color: _getTypeColor(),
          size: 24,
        ),
      ],
    );
  }

  Widget _buildQuestionContent() {
    return Column(
      children: [
        Text(
          widget.question,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.type == 'stock') ...[
          const SizedBox(height: 16),
          _buildStockSymbol(),
        ],
        if (widget.type == 'price') ...[
          const SizedBox(height: 16),
          _buildPriceDisplay(),
        ],
        if (widget.type == 'pattern') ...[
          const SizedBox(height: 16),
          _buildChartPattern(),
        ],
      ],
    );
  }

  Widget _buildStockSymbol() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'AAPL',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildPriceDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            '+\$2.45 (+1.2%)',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPattern() {
    return Container(
      height: 60,
      width: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: ChartPatternPainter(),
      ),
    );
  }

  Widget _buildSwipeInstructions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSwipeInstruction('Swipe Left', 'Don\'t Know', Colors.red, Icons.arrow_back),
        _buildSwipeInstruction('Swipe Right', 'Got It!', Colors.green, Icons.arrow_forward),
      ],
    );
  }

  Widget _buildSwipeInstruction(String action, String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          action,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            color: _isCorrect ? Colors.green : Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _isCorrect ? 'Correct!' : 'Not quite',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isCorrect ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.explanation,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showFeedback = false;
                _dragDistance = 0;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCorrect ? Colors.green : Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Next Question',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance += details.delta.dx;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final velocity = details.velocity.pixelsPerSecond.dx;
    final threshold = 200.0;

    if (velocity.abs() > threshold) {
      if (velocity > 0) {
        // Swiped right - "Got it"
        _handleSwipeRight();
      } else {
        // Swiped left - "Don't know"
        _handleSwipeLeft();
      }
    } else {
      // Return to center
      _resetCard();
    }
  }

  void _handleSwipeRight() {
    setState(() {
      _isCorrect = true;
      _showFeedback = true;
    });
    widget.onCorrect?.call();
    _controller.forward();
  }

  void _handleSwipeLeft() {
    setState(() {
      _isCorrect = false;
      _showFeedback = true;
    });
    widget.onIncorrect?.call();
    _controller.forward();
  }

  void _resetCard() {
    setState(() {
      _dragDistance = 0;
    });
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case 'stock':
        return Colors.blue;
      case 'price':
        return Colors.green;
      case 'risk':
        return Colors.orange;
      case 'pattern':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel() {
    switch (widget.type) {
      case 'stock':
        return 'Stock Symbol';
      case 'price':
        return 'Price Movement';
      case 'risk':
        return 'Risk Level';
      case 'pattern':
        return 'Chart Pattern';
      default:
        return 'Question';
    }
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case 'stock':
        return Icons.business;
      case 'price':
        return Icons.trending_up;
      case 'risk':
        return Icons.warning;
      case 'pattern':
        return Icons.show_chart;
      default:
        return Icons.help;
    }
  }
}

class ChartPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.6);
    path.lineTo(size.width * 0.4, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
