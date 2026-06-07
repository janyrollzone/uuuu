import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_provider.dart';

class LeaderboardDialog extends StatefulWidget {
  const LeaderboardDialog({super.key});

  @override
  State<LeaderboardDialog> createState() => _LeaderboardDialogState();
}

class _LeaderboardDialogState extends State<LeaderboardDialog> {
  late Future<List<Map<String, dynamic>>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<GameProvider>(context, listen: false);
    _leaderboardFuture = provider.fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFF007F).withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF007F).withOpacity(0.1),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'BẢNG XẾP HẠNG',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              
              // FutureBuilder to load profiles
              Flexible(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _leaderboardFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: Color(0xFFFF007F))),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'Lỗi khi tải bảng xếp hạng 😢',
                            style: GoogleFonts.outfit(color: Colors.red.shade300),
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data ?? [];

                    if (data.isEmpty) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'Chưa có người chơi nào trên bảng xếp hạng.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final player = data[index];
                        final rank = index + 1;
                        final username = player['username'] ?? 'Anonymous';
                        final wins = player['x_wins'] ?? 0;
                        final gems = player['gems'] ?? 0;
                        
                        return _buildLeaderboardRow(rank, username, wins, gems);
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Đăng nhập và chiến thắng Đấu Với Máy để thăng hạng!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(int rank, String username, int wins, int gems) {
    Color rankColor;
    Widget rankWidget;
    
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      rankWidget = const Icon(Icons.looks_one_rounded, color: Color(0xFFFFD700), size: 24);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankWidget = const Icon(Icons.looks_two_rounded, color: Color(0xFFC0C0C0), size: 24);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankWidget = const Icon(Icons.looks_3_rounded, color: Color(0xFFCD7F32), size: 24);
    } else {
      rankColor = const Color(0xFF94A3B8);
      rankWidget = Container(
        width: 24,
        alignment: Alignment.center,
        child: Text(
          '$rank',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF94A3B8),
            fontSize: 15,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rank <= 3 
            ? rankColor.withOpacity(0.08) 
            : const Color(0xFF0F172A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3 
              ? rankColor.withOpacity(0.3) 
              : Colors.white.withOpacity(0.05),
          width: rank <= 3 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          rankWidget,
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$wins Wins',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '💎 $gems',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFFFF007F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
