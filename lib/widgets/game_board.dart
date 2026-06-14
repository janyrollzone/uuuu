import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_provider.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with SingleTickerProviderStateMixin {
  late AnimationController _winningLineController;
  late Animation<double> _winningLineAnimation;

  @override
  void initState() {
    super.initState();
    _winningLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _winningLineAnimation = CurvedAnimation(
      parent: _winningLineController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _winningLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    // Trigger winning line animation if a player has won
    if (provider.status == GameStatus.won && provider.winningLine.isNotEmpty) {
      if (!_winningLineController.isAnimating && _winningLineController.value == 0.0) {
        _winningLineController.forward();
      }
    } else {
      if (_winningLineController.value > 0.0) {
        _winningLineController.reset();
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = min(constraints.maxWidth, constraints.maxHeight);
        
        return Center(
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Custom Painter for Grid Lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridLinesPainter(boardSize: provider.boardSize),
                  ),
                ),

                // Interactive dynamic grid
                Positioned.fill(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: provider.boardSize,
                    ),
                    itemCount: provider.boardSize * provider.boardSize,
                    itemBuilder: (context, index) {
                      final token = provider.board[index];
                      final isWinningCell = provider.status == GameStatus.won &&
                          provider.winningLine.contains(index);

                      Widget cellWidget = AnimatedTokenCell(
                        token: token,
                        boardSize: provider.boardSize,
                      );

                      // Hiệu ứng nhấp nháy cho các ô thuộc hàng thắng
                      if (isWinningCell) {
                        final winnerToken = provider.board[provider.winningLine.first];
                        final highlightColor = winnerToken == 'X'
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFFFF007F);
                        cellWidget = PulsingCellHighlight(
                          color: highlightColor,
                          child: cellWidget,
                        );
                      }

                      return GestureDetector(
                        onTap: () {
                          if (token == null &&
                              provider.status == GameStatus.playing &&
                              !provider.isAiThinking &&
                              (provider.gameMode == 'Online' ? provider.canPlayOnline : true)) {
                            
                            // Haptic Feedback
                            if (provider.hapticEnabled) {
                              HapticFeedback.lightImpact();
                            }

                             provider.makeMove(index);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: cellWidget,
                        ),
                      );
                    },
                  ),
                ),

                // Animated Winning Line Overlay
                if (provider.status == GameStatus.won && provider.winningLine.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _winningLineAnimation,
                        builder: (context, child) {
                          final winnerToken = provider.board[provider.winningLine.first];
                          final color = winnerToken == 'X'
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFFFF007F);

                          return CustomPaint(
                            painter: WinningLinePainter(
                              winningPattern: provider.winningLine,
                              animationValue: _winningLineAnimation.value,
                              color: color,
                              boardSize: provider.boardSize,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Painter for drawing dynamic grid lines
class GridLinesPainter extends CustomPainter {
  final int boardSize;
  const GridLinesPainter({required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = max(1.0, 2.5 / (boardSize / 5))
      ..strokeCap = StrokeCap.round;

    final energyPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.02)
      ..strokeWidth = max(2.0, 5.0 / (boardSize / 5))
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

    final cellWidth = size.width / boardSize;
    final cellHeight = size.height / boardSize;

    // Draw vertical lines
    for (int i = 1; i < boardSize; i++) {
      final x = cellWidth * i;
      canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), energyPaint);
      canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), paint);
    }

    // Draw horizontal lines
    for (int i = 1; i < boardSize; i++) {
      final y = cellHeight * i;
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), energyPaint);
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridLinesPainter oldDelegate) {
    return oldDelegate.boardSize != boardSize;
  }
}

/// Widget wrapping the animated rendering of 'X' or 'O' in a dynamic cell
class AnimatedTokenCell extends StatefulWidget {
  final String? token;
  final int boardSize;
  const AnimatedTokenCell({super.key, this.token, required this.boardSize});

  @override
  State<AnimatedTokenCell> createState() => _AnimatedTokenCellState();
}

class _AnimatedTokenCellState extends State<AnimatedTokenCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String? _displayedToken;

  @override
  void initState() {
    super.initState();
    // Khởi tạo thời gian chạy hiệu ứng phóng to là 200ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _displayedToken = widget.token;
    if (_displayedToken != null) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedTokenCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token) {
      if (widget.token == null) {
        _controller.reverse().then((_) {
          if (mounted) {
            setState(() {
              _displayedToken = null;
            });
          }
        });
      } else {
        setState(() {
          _displayedToken = widget.token;
        });
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedToken == null) return const SizedBox.shrink();
    
    // Tính toán khoảng cách căn lề ô cờ dựa trên kích thước bàn cờ
    final double paddingVal = max(1.5, 30.0 / widget.boardSize);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Áp dụng hiệu ứng ScaleTransition (phóng to từ 0 đến kích thước gốc)
        return ScaleTransition(
          scale: _animation,
          child: Padding(
            padding: EdgeInsets.all(paddingVal),
            child: CustomPaint(
              painter: TokenPainter(
                token: _displayedToken!,
                progress: _animation.value,
                boardSize: widget.boardSize,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

/// Custom Painter to draw animated 'X' and 'O' with size-adaptive strokes
class TokenPainter extends CustomPainter {
  final String token;
  final double progress;
  final int boardSize;

  TokenPainter({required this.token, required this.progress, required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final isX = token == 'X';
    final color = isX ? const Color(0xFF00E5FF) : const Color(0xFFFF007F);
    
    // Scale stroke widths dynamically
    final double stroke = max(1.2, 9.0 / boardSize);
    final double glowStroke1 = stroke * 4.0;
    final double glowStroke2 = stroke * 2.0;

    final Color coreColor = Color.lerp(color, Colors.white, 0.45)!;

    // 1. Broad outer ambient glow
    final glowPaint1 = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = glowStroke1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // 2. Tight intense neon glow
    final glowPaint2 = Paint()
      ..color = color.withOpacity(0.45)
      ..strokeWidth = glowStroke2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    // 3. Bright core light
    final corePaint = Paint()
      ..color = coreColor
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    void drawPath(Paint p1, Paint p2, Paint coreP) {
      if (isX) {
        if (progress <= 0.5) {
          final p = progress / 0.5;
          final start = const Offset(0, 0);
          final end = Offset(width * p, height * p);
          canvas.drawLine(start, end, p1);
          canvas.drawLine(start, end, p2);
          canvas.drawLine(start, end, coreP);
        } else {
          final start1 = const Offset(0, 0);
          final end1 = Offset(width, height);
          canvas.drawLine(start1, end1, p1);
          canvas.drawLine(start1, end1, p2);
          canvas.drawLine(start1, end1, coreP);

          final p = (progress - 0.5) / 0.5;
          final start2 = Offset(width, 0);
          final end2 = Offset(width - (width * p), height * p);
          canvas.drawLine(start2, end2, p1);
          canvas.drawLine(start2, end2, p2);
          canvas.drawLine(start2, end2, coreP);
        }
      } else {
        final rect = Rect.fromLTWH(0, 0, width, height);
        final startAngle = -pi / 2;
        final sweepAngle = 2 * pi * progress;
        
        canvas.drawArc(rect, startAngle, sweepAngle, false, p1);
        canvas.drawArc(rect, startAngle, sweepAngle, false, p2);
        canvas.drawArc(rect, startAngle, sweepAngle, false, coreP);
      }
    }

    drawPath(glowPaint1, glowPaint2, corePaint);
  }

  @override
  bool shouldRepaint(covariant TokenPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.token != token || oldDelegate.boardSize != boardSize;
  }
}

/// Custom Painter to draw the glowing winning connection line
class WinningLinePainter extends CustomPainter {
  final List<int> winningPattern;
  final double animationValue;
  final Color color;
  final int boardSize;

  WinningLinePainter({
    required this.winningPattern,
    required this.animationValue,
    required this.color,
    required this.boardSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (winningPattern.isEmpty) return;

    final cellWidth = size.width / boardSize;
    final cellHeight = size.height / boardSize;

    Offset getCellCenter(int idx) {
      final row = idx ~/ boardSize;
      final col = idx % boardSize;
      return Offset(
        col * cellWidth + cellWidth / 2,
        row * cellHeight + cellHeight / 2,
      );
    }

    final start = getCellCenter(winningPattern.first);
    final end = getCellCenter(winningPattern.last);
    final currentEnd = Offset.lerp(start, end, animationValue)!;

    final double stroke = max(2.5, 18.0 / boardSize);
    final double glowStroke = stroke * 2.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = glowStroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawLine(start, currentEnd, shadowPaint);
    canvas.drawLine(start, currentEnd, paint);
  }

  @override
  bool shouldRepaint(covariant WinningLinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.winningPattern != winningPattern ||
        oldDelegate.color != color ||
        oldDelegate.boardSize != boardSize;
  }
}

/// Widget tạo hiệu ứng nhấp nháy/phát xung nhẹ cho nền của ô cờ chiến thắng
class PulsingCellHighlight extends StatefulWidget {
  final Widget child;
  final Color color;

  const PulsingCellHighlight({
    super.key,
    required this.child,
    required this.color,
  });

  @override
  State<PulsingCellHighlight> createState() => _PulsingCellHighlightState();
}

class _PulsingCellHighlightState extends State<PulsingCellHighlight> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Tạo hiệu ứng lặp đi lặp lại (reverse: true để tự động mờ dần rồi sáng lại)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // Điều chỉnh độ mờ (opacity) nhấp nháy nhẹ nhàng từ 0.12 đến 0.40
    _animation = Tween<double>(begin: 0.12, end: 0.40).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(4),
          ),
          child: widget.child,
        );
      },
    );
  }
}
