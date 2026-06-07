import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_provider.dart';
import '../widgets/supabase_auth_dialog.dart';
import '../widgets/leaderboard_dialog.dart';
import 'game_screen.dart';

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

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  Widget _buildGemBadge(int gems) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final double pulse = _glowAnimation.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF007F).withOpacity(0.3 + (pulse * 0.2)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF007F).withOpacity(0.1 + (pulse * 0.15)),
                blurRadius: 8 + (pulse * 8),
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$gems',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Ambient neon glows in background
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D2FF).withOpacity(0.18),
                    blurRadius: 130,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF007F).withOpacity(0.15),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Leaderboard Button
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const LeaderboardDialog(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'BXH',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Right Side: Cloud Sync Icon + Gems Badge
                      Row(
                        children: [
                          // Cloud Sync Status
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => const SupabaseAuthDialog(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withOpacity(0.65),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: (provider.isLoggedIn ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8)).withOpacity(0.3),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    provider.isLoggedIn ? Icons.person_rounded : Icons.cloud_off_rounded,
                                    color: provider.isLoggedIn ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 96),
                                    child: Text(
                                      provider.isLoggedIn
                                          ? (provider.userProfile?['username'] ?? 'Player')
                                          : 'Đồng bộ',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildGemBadge(provider.gems),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Animated Breathing Neon Title
                  Center(
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        final pulse = _glowAnimation.value;
                        return Column(
                          children: [
                            Text(
                              'XOXOXO',
                              style: GoogleFonts.outfit(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFFFF007F)],
                                  ).createShader(const Rect.fromLTWH(0.0, 0.0, 300.0, 50.0)),
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.2 + (pulse * 0.35)),
                                    blurRadius: 10 + (pulse * 15),
                                    offset: const Offset(0, 4),
                                  ),
                                  Shadow(
                                    color: const Color(0xFFFF007F).withOpacity(0.15 + (pulse * 0.3)),
                                    blurRadius: 12 + (pulse * 18),
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'ĐẤU TRƯỜNG CÔNG NGHỆ',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Game Mode Picker
                  const _SectionHeader(title: 'CHẾ ĐỘ CHƠI'),
                  const SizedBox(height: 10),
                  _GameModeSelector(),
                  const SizedBox(height: 16),
                  const _OnlineMatchPanel(),

                  const SizedBox(height: 24),

                  // Board Size Selector
                  const _SectionHeader(title: 'KÍCH THƯỚC BÀN CỜ'),
                  const SizedBox(height: 10),
                  _BoardSizeSelector(),

                  const SizedBox(height: 24),

                  // Difficulty Level (Only shows if PvC is selected)
                  if (provider.gameMode == 'PvC') ...[
                    const _SectionHeader(title: 'ĐỘ KHÓ MÁY'),
                    const SizedBox(height: 10),
                    _DifficultySelector(),
                    const SizedBox(height: 24),
                  ],

                  // Stats Dashboard
                  const _SectionHeader(title: 'THÀNH TÍCH ĐẤU TRƯỜNG'),
                  const SizedBox(height: 10),
                  _StatsDashboard(),

                  const SizedBox(height: 36),

                  // Pulsing Play Button
                  _PlayButton(
                    glowAnimation: _glowAnimation,
                    label: provider.gameMode == 'Online'
                        ? (provider.isSearchingMatch ? 'ĐANG TÌM TRẬN...' : 'TÌM TRẬN')
                        : 'BẮT ĐẦU CHƠI',
                    onPressed: () async {
                      if (provider.gameMode == 'Online') {
                        if (!provider.isLoggedIn) {
                          showDialog(
                            context: context,
                            builder: (context) => const SupabaseAuthDialog(),
                          );
                          return;
                        }

                        if (provider.onlineMatchId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GameScreen()),
                          );
                          return;
                        }

                        final joined = await provider.startOnlineMatch();
                        if (joined && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GameScreen()),
                          );
                        }
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GameScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  // Bottom Settings Bar
                  const _QuickSettings(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF94A3B8),
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}

class _GameModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final isPvC = provider.gameMode == 'PvC';

    return GlassCard(
      padding: EdgeInsets.zero,
      borderColor: isPvC ? const Color(0xFF00E5FF) : const Color(0xFFFF007F),
      child: Container(
        height: 58,
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Sliding indicator background pill
            AnimatedAlign(
              alignment: isPvC ? Alignment.centerLeft : Alignment.centerRight,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPvC
                          ? [const Color(0xFF00E5FF).withOpacity(0.2), const Color(0xFF00E5FF).withOpacity(0.04)]
                          : [const Color(0xFFFF007F).withOpacity(0.2), const Color(0xFFFF007F).withOpacity(0.04)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPvC ? const Color(0xFF00E5FF).withOpacity(0.4) : const Color(0xFFFF007F).withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isPvC ? const Color(0xFF00E5FF) : const Color(0xFFFF007F)).withOpacity(0.12),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ),
            ),
            // Tap boundaries
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => provider.setGameMode('PvC'),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.computer_rounded,
                            size: 20,
                            color: isPvC ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ĐẤU VỚI MÁY',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: isPvC ? FontWeight.bold : FontWeight.w500,
                              color: isPvC ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => provider.setGameMode('PvP'),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 20,
                            color: !isPvC ? const Color(0xFFFF007F) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CHƠI 2 NGƯỜI',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: !isPvC ? FontWeight.bold : FontWeight.w500,
                              color: !isPvC ? Colors.white : const Color(0xFFFF007F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineMatchPanel extends StatelessWidget {
  const _OnlineMatchPanel();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final isOnline = provider.gameMode == 'Online';

    return GlassCard(
      borderColor: isOnline ? const Color(0xFF10B981) : const Color(0xFF334155),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi_tethering_rounded,
                color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'TÌM TRẬN ONLINE',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            provider.isLoggedIn
                ? (provider.isSearchingMatch
                    ? 'Đang ghép cặp với người chơi khác...'
                    : 'Chọn để vào hàng chờ và ghép với 1 người chơi khác.')
                : 'Cần đăng nhập để chơi online.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: provider.isLoggedIn
                ? () => provider.setGameMode('Online')
                : null,
            icon: const Icon(Icons.person_search_rounded, size: 18),
            label: Text(
              isOnline ? 'ĐÃ CHỌN ONLINE' : 'CHỌN CHẾ ĐỘ ONLINE',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOnline ? const Color(0xFF10B981) : const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF334155),
              disabledForegroundColor: const Color(0xFF64748B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardSizeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    final profile = _boardSizeProfile(provider.boardSize);
    const presets = [
      _BoardSizePreset(
        size: 3,
        label: '3x3',
        subtitle: 'Fast',
        icon: Icons.flash_on_rounded,
        color: Color(0xFF10B981),
      ),
      _BoardSizePreset(
        size: 4,
        label: '4x4',
        subtitle: 'Short',
        icon: Icons.timelapse_rounded,
        color: Color(0xFFF59E0B),
      ),
      _BoardSizePreset(
        size: 10,
        label: '10x10',
        subtitle: 'Standard',
        icon: Icons.grid_view_rounded,
        color: Color(0xFF00E5FF),
      ),
      _BoardSizePreset(
        size: 15,
        label: '15x15',
        subtitle: 'Epic',
        icon: Icons.explore_rounded,
        color: Color(0xFFFF007F),
      ),
    ];

    return GlassCard(
      borderColor: const Color(0xFF00E5FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOARD SIZE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${provider.boardSize} x ${provider.boardSize}',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bigger boards create longer, more tactical matches.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      '${profile.winLength} IN A ROW',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E5FF),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: profile.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: profile.color.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      profile.label.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: profile.color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: presets.map((preset) {
              final isSelected = provider.boardSize == preset.size;
              return GestureDetector(
                onTap: () => provider.setBoardSize(preset.size),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 116,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              preset.color.withOpacity(0.24),
                              preset.color.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : const Color(0xFF1E293B).withOpacity(0.38),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? preset.color.withOpacity(0.75)
                          : Colors.white.withOpacity(0.08),
                      width: 1.4,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: preset.color.withOpacity(0.2),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            preset.icon,
                            size: 18,
                            color: isSelected ? preset.color : const Color(0xFF94A3B8),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Color(0xFF00E5FF),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        preset.label,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isSelected ? preset.color : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fine tune',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${provider.boardSize} x ${provider.boardSize}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00E5FF),
                    inactiveTrackColor: const Color(0xFF334155),
                    thumbColor: const Color(0xFFFF007F),
                    overlayColor: const Color(0xFFFF007F).withOpacity(0.12),
                    valueIndicatorColor: const Color(0xFF1E293B),
                    valueIndicatorTextStyle: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    trackHeight: 4.0,
                  ),
                  child: Slider(
                    value: provider.boardSize.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    label: '${provider.boardSize}x${provider.boardSize}',
                    onChanged: (value) {
                      provider.setBoardSize(value.round());
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '3x3',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '15x15',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: smaller boards are faster; bigger boards reward long-term strategy.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

int _boardSizeWinLength(int boardSize) {
  if (boardSize == 3) return 3;
  if (boardSize == 4) return 4;
  if (boardSize >= 5 && boardSize <= 10) return 5;
  return 7;
}

_BoardSizeProfile _boardSizeProfile(int boardSize) {
  final winLength = _boardSizeWinLength(boardSize);

  if (boardSize <= 3) {
    return _BoardSizeProfile(
      label: 'Lightning',
      color: const Color(0xFF10B981),
      winLength: winLength,
    );
  }

  if (boardSize == 4) {
    return _BoardSizeProfile(
      label: 'Quick Duel',
      color: const Color(0xFFF59E0B),
      winLength: winLength,
    );
  }

  if (boardSize <= 10) {
    return _BoardSizeProfile(
      label: 'Balanced',
      color: const Color(0xFF00E5FF),
      winLength: winLength,
    );
  }

  return _BoardSizeProfile(
    label: 'Marathon',
    color: const Color(0xFFFF007F),
    winLength: winLength,
  );
}

class _BoardSizePreset {
  final int size;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _BoardSizePreset({
    required this.size,
    required this.label,
    required this.subtitle,
    required this.icon,
    this.color = const Color(0xFF00E5FF),
  });
}

class _BoardSizeProfile {
  final String label;
  final Color color;
  final int winLength;

  const _BoardSizeProfile({
    required this.label,
    required this.color,
    required this.winLength,
  });
}

class _DifficultySelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final levels = [
      {'key': 'Easy', 'label': 'DỄ'},
      {'key': 'Medium', 'label': 'VỪA'},
      {'key': 'Hard', 'label': 'KHÓ'},
    ];

    return Row(
      children: levels.map((level) {
        final isSelected = provider.difficulty == level['key'];
        Color color;
        if (level['key'] == 'Easy') {
          color = const Color(0xFF10B981);
        } else if (level['key'] == 'Medium') {
          color = const Color(0xFFF59E0B);
        } else {
          color = const Color(0xFFFF007F);
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => provider.setDifficulty(level['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : const Color(0xFF1E293B).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                child: Text(
                  level['label']!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    letterSpacing: 1,
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                            )
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatsDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return GlassCard(
      borderColor: const Color(0xFFFF007F),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'THẮNG (X)',
                value: '${provider.xWins}',
                color: const Color(0xFF00E5FF),
              ),
              _StatItem(
                label: 'THUA',
                value: '${provider.losses}',
                color: const Color(0xFFFF6B6B),
              ),
              _StatItem(
                label: 'HÒA',
                value: '${provider.draws}',
                color: const Color(0xFF94A3B8),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'CHUỖI THẮNG',
                    value: '${provider.winStreak}',
                    color: const Color(0xFFFF007F),
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white10),
                Expanded(
                  child: _StatItem(
                    label: 'KỶ LỤC',
                    value: '${provider.bestWinStreak}',
                    color: const Color(0xFF00E5FF),
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.white10),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '+${provider.nextWinReward}',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF10B981).withOpacity(0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'THƯỞNG VÁN TỚI',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  provider.addFreeGems(10);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1E293B),
                      content: Text(
                        'Đã nhận +10 đá quý miễn phí! 💎',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 4),
                    Text(
                      'NHẬN 10 ĐÁ QUÝ 💎',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E5FF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.xWins > 0 || provider.oWins > 0 || provider.draws > 0) ...[
                Container(width: 1, height: 16, color: Colors.white10),
                GestureDetector(
                  onTap: () => _showClearStatsDialog(context, provider),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'XÓA LỊCH SỬ',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          )
        ],
      ),
    );
  }

  void _showClearStatsDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xóa lịch sử đấu?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Thao tác này sẽ xóa vĩnh viễn toàn bộ điểm số tích lũy của các người chơi.',
          style: GoogleFonts.outfit(color: const Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('HỦY', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () {
              provider.clearScores();
              Navigator.pop(context);
            },
            child: Text('XÓA', style: GoogleFonts.outfit(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
              )
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final Animation<double> glowAnimation;
  final String label;
  final VoidCallback onPressed;

  const _PlayButton({
    required this.glowAnimation,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        final double scale = 1.0 + (glowAnimation.value * 0.02);
        final double glowRadius = 15.0 + (glowAnimation.value * 15.0);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.25 * glowAnimation.value),
                  blurRadius: glowRadius,
                  spreadRadius: 2,
                  offset: const Offset(-4, 0),
                ),
                BoxShadow(
                  color: const Color(0xFFFF007F).withOpacity(0.25 * glowAnimation.value),
                  blurRadius: glowRadius,
                  spreadRadius: 2,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                onPressed();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFFFF007F)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickSettings extends StatelessWidget {
  const _QuickSettings();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: provider.toggleSound,
          icon: Icon(
            provider.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: provider.soundEnabled ? const Color(0xFF00E5FF) : const Color(0xFF475569),
          ),
          tooltip: 'Bật/Tắt Âm Thanh',
        ),
        const SizedBox(width: 24),
        IconButton(
          onPressed: provider.toggleHaptic,
          icon: Icon(
            provider.hapticEnabled ? Icons.vibration_rounded : Icons.vibration_outlined,
            color: provider.hapticEnabled ? const Color(0xFFFF007F) : const Color(0xFF475569),
          ),
          tooltip: 'Bật/Tắt Rung',
        ),
      ],
    );
  }
}
