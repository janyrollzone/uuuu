import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_provider.dart';
import '../widgets/game_board.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final Color borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 12.0,
    this.opacity = 0.4,
    this.borderColor = const Color(0xFF334155),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(opacity),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowingDot extends StatefulWidget {
  final Color color;
  const _GlowingDot({required this.color});

  @override
  State<_GlowingDot> createState() => _GlowingDotState();
}

class _GlowingDotState extends State<_GlowingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_animation.value),
                blurRadius: 8 * _animation.value,
                spreadRadius: 1 * _animation.value,
              )
            ],
          ),
        );
      },
    );
  }
}

class _HologramEmblem extends StatefulWidget {
  final Color glowColor;
  final bool isDraw;
  final GameProvider provider;

  const _HologramEmblem({
    required this.glowColor,
    required this.isDraw,
    required this.provider,
  });

  @override
  State<_HologramEmblem> createState() => _HologramEmblemState();
}

class _HologramEmblemState extends State<_HologramEmblem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.glowColor.withOpacity(0.08),
          border: Border.all(
            color: widget.glowColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Icon(
          widget.isDraw
              ? Icons.balance_rounded
              : (widget.provider.board[widget.provider.winningLine.first] == 'X'
                  ? Icons.close_rounded
                  : Icons.radio_button_unchecked_rounded),
          size: 48,
          color: widget.glowColor,
        ),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  Widget _buildGemBadge(int gems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF007F).withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF007F).withOpacity(0.08),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.diamond_rounded,
            color: Color(0xFFFF007F),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$gems',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountBadge(GameProvider provider) {
    if (!provider.isLoggedIn) {
      return const SizedBox.shrink();
    }

    final username = provider.userProfile?['username'] as String? ?? 'Player';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_rounded,
            color: Color(0xFF00E5FF),
            size: 14,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GameProvider provider) {
    int winLength;
    if (provider.boardSize == 3) {
      winLength = 3;
    } else if (provider.boardSize == 4) {
      winLength = 4;
    } else if (provider.boardSize >= 5 && provider.boardSize <= 10) {
      winLength = 5;
    } else {
      winLength = 7;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () async {
            if (provider.isOnlineMatch && provider.onlineMatchId != null) {
              await provider.leaveOnlineMatch();
              if (context.mounted) {
                Navigator.pop(context);
              }
              return;
            }

            if (provider.status == GameStatus.playing && provider.board.contains(null) && provider.board.any((element) => element != null)) {
              _showExitConfirmation(context);
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          tooltip: 'Quay lại Trang Chủ',
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.gameModeLabel,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'BÀN CỜ ${provider.boardSize}X${provider.boardSize} - LUẬT: $winLength QUÂN',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00E5FF),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildAccountBadge(provider),
            if (provider.isLoggedIn) const SizedBox(height: 6),
            _buildGemBadge(provider.gems),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreBoard(GameProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderColor: Colors.white.withOpacity(0.08),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreBadge(
            label: provider.isOnlineMatch
                ? (provider.onlineRole == 'X' ? 'BẠN (X)' : 'ĐỐI THỦ X')
                : (provider.gameMode == 'PvC' ? 'BẠN (X)' : 'NGƯỜI CHƠI X'),
            score: '${provider.xWins}',
            color: const Color(0xFF00E5FF),
          ),
          Container(width: 1.5, height: 24, color: Colors.white10),
          _buildScoreBadge(
            label: 'HÒA',
            score: '${provider.draws}',
            color: const Color(0xFF94A3B8),
          ),
          Container(width: 1.5, height: 24, color: Colors.white10),
          _buildScoreBadge(
            label: provider.isOnlineMatch
                ? (provider.onlineRole == 'O' ? 'BẠN (O)' : 'ĐỐI THỦ O')
                : (provider.gameMode == 'PvC' ? 'MÁY (O)' : 'NGƯỜI CHƠI O'),
            score: '${provider.oWins}',
            color: const Color(0xFFFF007F),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge({
    required String label,
    required String score,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          score,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
              )
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTurnIndicator(GameProvider provider) {
    final isXTurn = provider.currentPlayer == 'X';
    final activeColor = isXTurn ? const Color(0xFF00E5FF) : const Color(0xFFFF007F);
    
    String statusText = '';
    if (provider.status == GameStatus.playing) {
      if (provider.gameMode == 'PvC') {
        statusText = provider.isAiThinking ? 'MÁY ĐANG SUY NGHĨ...' : (isXTurn ? 'LƯỢT CỦA BẠN' : 'LƯỢT CỦA MÁY');
      } else if (provider.gameMode == 'Online') {
        if (provider.isSearchingMatch) {
          statusText = 'ĐANG TÌM TRẬN...';
        } else {
          statusText = isXTurn == (provider.onlineRole == 'X') ? 'LƯỢT CỦA BẠN' : 'LƯỢT CỦA ĐỐI THỦ';
        }
      } else {
        statusText = isXTurn ? 'LƯỢT CỦA NGƯỜI CHƠI X' : 'LƯỢT CỦA NGƯỜI CHƠI O';
      }
    } else if (provider.status == GameStatus.draw) {
      statusText = 'KẾT QUẢ HÒA!';
    } else {
      statusText = 'CHIẾN THẮNG!';
    }

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: provider.status == GameStatus.playing
              ? activeColor.withOpacity(0.06)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: provider.status == GameStatus.playing
                ? activeColor.withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: provider.status == GameStatus.playing
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.12),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.isAiThinking && provider.status == GameStatus.playing) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF007F),
                ),
              ),
              const SizedBox(width: 12),
            ] else if (provider.status == GameStatus.playing) ...[
              _GlowingDot(color: activeColor),
              const SizedBox(width: 12),
            ],
            Text(
              statusText,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.5,
                shadows: provider.status == GameStatus.playing
                    ? [
                        Shadow(
                          color: activeColor.withOpacity(0.8),
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, GameProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _ControlButton(
            label: 'CHƠI LẠI',
            icon: Icons.refresh_rounded,
            onPressed: provider.resetBoard,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ControlButton(
            label: 'ĐI LẠI',
            icon: Icons.undo_rounded,
            onPressed: provider.canUndo ? provider.undoMove : null,
            color: const Color(0xFF00E5FF),
            isDisabled: !provider.canUndo,
          ),
        ),
      ],
    );
  }

  Widget _buildResultOverlay(BuildContext context, GameProvider provider) {
    final isDraw = provider.status == GameStatus.draw;
    String titleText = '';
    String subtitleText = '';
    Color glowColor;

    if (isDraw) {
      titleText = 'HÒA TRẬN';
      subtitleText = 'Trận đấu cân sức cân tài!';
      glowColor = const Color(0xFF94A3B8);
    } else {
      final winner = provider.board[provider.winningLine.first];
      glowColor = winner == 'X' ? const Color(0xFF00E5FF) : const Color(0xFFFF007F);
      
      if (provider.gameMode == 'PvC') {
        titleText = winner == 'X' ? 'CHIẾN THẮNG!' : 'THẤT BẠI!';
        subtitleText = winner == 'X'
            ? 'Bạn đã chinh phục thành công!'
            : 'Máy tính đã giành chiến thắng!';
      } else if (provider.gameMode == 'Online') {
        final localWin = winner == provider.onlineRole;
        titleText = localWin ? 'CHIẾN THẮNG!' : 'THẤT BẠI!';
        subtitleText = localWin
            ? 'Bạn đã thắng trận online.'
            : 'Đối thủ ${provider.onlineOpponentName.isNotEmpty ? provider.onlineOpponentName : ''} đã thắng.';
      } else {
        titleText = 'CHIẾN THẮNG!';
        subtitleText = 'Người chơi $winner đã chiến thắng!';
      }
    }

    return Container(
      color: Colors.black.withOpacity(0.55),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: GlassCard(
              borderColor: glowColor,
              blur: 16,
              opacity: 0.65,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HologramEmblem(glowColor: glowColor, isDraw: isDraw, provider: provider),
                  const SizedBox(height: 20),
                  
                  Text(
                    titleText,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.5,
                      shadows: [
                        Shadow(
                          color: glowColor.withOpacity(0.6),
                          blurRadius: 10,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    subtitleText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                  
                  if (!isDraw &&
                      provider.winningLine.isNotEmpty &&
                      (provider.gameMode == 'Online'
                          ? provider.board[provider.winningLine.first] == provider.onlineRole
                          : provider.board[provider.winningLine.first] == 'X')) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_rounded, color: Color(0xFFFF007F), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '+${provider.lastEarnedGems} ĐÁ QUÝ',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chuỗi thắng',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${provider.winStreak}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ván tới +${provider.nextWinReward} 💎',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (provider.gameMode == 'PvC' && !isDraw && provider.board[provider.winningLine.first] == 'O') ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: provider.gems >= 5
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF007F).withOpacity(0.35),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: provider.gems >= 5 ? () => provider.revive() : null,
                          icon: const Icon(Icons.autorenew_rounded, color: Colors.white),
                          label: Text(
                            provider.gems >= 5
                                ? 'HỒI SINH (Dùng 5 💎)'
                                : 'HỒI SINH (Cần 5 💎 - Không đủ)',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFFFF007F),
                            disabledBackgroundColor: const Color(0xFF334155),
                            disabledForegroundColor: const Color(0xFF64748B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 28),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.resetBoard();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF64748B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'TRANG CHỦ',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: provider.resetBoard,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: glowColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            shadowColor: glowColor.withOpacity(0.4),
                          ),
                          child: Text(
                            'CHƠI TIẾP',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rời trận đấu?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Trận đấu đang diễn ra sẽ bị hủy bỏ. Bạn có chắc chắn muốn thoát?',
          style: GoogleFonts.outfit(color: const Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('HỦY', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text('THOÁT', style: GoogleFonts.outfit(color: const Color(0xFFFF007F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: 100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF007F).withOpacity(0.08),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D2FF).withOpacity(0.08),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, provider),
                  
                  const SizedBox(height: 24),
                  
                  _buildScoreBoard(provider),
                  
                  const SizedBox(height: 24),
                  
                  _buildTurnIndicator(provider),
                  
                  const SizedBox(height: 24),
                  
                  const Expanded(
                    child: Center(
                      child: GameBoard(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildControlPanel(context, provider),
                  
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          if (provider.status != GameStatus.playing)
            _buildResultOverlay(context, provider),

          if (provider.status == GameStatus.won &&
              provider.winningLine.isNotEmpty &&
              (provider.gameMode == 'Online'
                  ? provider.board[provider.winningLine.first] == provider.onlineRole
                  : provider.board[provider.winningLine.first] == 'X'))
            const ConfettiParticles(),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isDisabled;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final finalColor = isDisabled ? const Color(0xFF334155) : color;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: !isDisabled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: const Color(0xFF334155),
          side: BorderSide(
            color: finalColor.withOpacity(isDisabled ? 0.2 : 0.45),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: !isDisabled ? color.withOpacity(0.03) : Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDisabled ? const Color(0xFF475569) : color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDisabled ? const Color(0xFF475569) : Colors.white,
                  letterSpacing: 1.5,
                  shadows: !isDisabled
                      ? [
                          Shadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 6,
                          )
                        ]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfettiParticles extends StatefulWidget {
  final Color color1;
  final Color color2;

  const ConfettiParticles({
    super.key,
    this.color1 = const Color(0xFF00E5FF),
    this.color2 = const Color(0xFFFF007F),
  });

  @override
  State<ConfettiParticles> createState() => _ConfettiParticlesState();
}

class _ConfettiParticlesState extends State<ConfettiParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    for (int i = 0; i < 60; i++) {
      _particles.add(_createParticle(isInitial: true));
    }

    _controller.addListener(_updateParticles);
  }

  _Particle _createParticle({bool isInitial = false}) {
    final double x = _random.nextDouble();
    final double y = isInitial ? _random.nextDouble() * -0.5 : -0.1;
    return _Particle(
      x: x,
      y: y,
      speedY: 0.004 + _random.nextDouble() * 0.006,
      speedX: -0.0015 + _random.nextDouble() * 0.003,
      size: 4.0 + _random.nextDouble() * 8.0,
      color: _random.nextBool() ? widget.color1 : widget.color2,
      rotation: _random.nextDouble() * pi * 2,
      spinSpeed: -0.04 + _random.nextDouble() * 0.08,
      isDiamond: _random.nextBool(),
    );
  }

  void _updateParticles() {
    if (mounted) {
      setState(() {
        for (int i = 0; i < _particles.length; i++) {
          final p = _particles[i];
          p.y += p.speedY;
          p.x += p.speedX;
          p.rotation += p.spinSpeed;

          if (p.y > 1.1 || p.x < -0.1 || p.x > 1.1) {
            _particles[i] = _createParticle();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParticles);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ParticlePainter(particles: _particles),
        ),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double speedY;
  double speedX;
  double size;
  Color color;
  double rotation;
  double spinSpeed;
  bool isDiamond;

  _Particle({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.color,
    required this.rotation,
    required this.spinSpeed,
    required this.isDiamond,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final double px = p.x * size.width;
      final double py = p.y * size.height;

      final paint = Paint()
        ..color = p.color.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = p.color.withOpacity(0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      if (p.isDiamond) {
        final path = Path()
          ..moveTo(0, -p.size)
          ..lineTo(p.size * 0.7, 0)
          ..lineTo(0, p.size)
          ..lineTo(-p.size * 0.7, 0)
          ..close();
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, paint);
      } else {
        final rect = Rect.fromCenter(center: Offset.zero, width: p.size * 1.3, height: p.size * 0.65);
        canvas.drawRect(rect, glowPaint);
        canvas.drawRect(rect, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
