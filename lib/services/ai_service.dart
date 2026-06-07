import 'dart:math';

class AIService {
  static final Random _random = Random();

  /// Calculates the best index (0 to boardSize^2 - 1) for the AI to play.
  /// [board] is the list representing the board state.
  /// [aiPlayer] is the symbol the AI is playing ('X' or 'O').
  /// [boardSize] is the current board dimension (3 to 15).
  static int getBestMove(List<String?> board, String aiPlayer, String difficulty, int boardSize) {
    final opponent = aiPlayer == 'X' ? 'O' : 'X';

    switch (difficulty.toLowerCase()) {
      case 'easy':
        return _getRandomMove(board);
      case 'medium':
        // 50% chance to make a heuristic move, 50% random
        if (_random.nextDouble() > 0.5) {
          return _getHeuristicMove(board, aiPlayer, opponent, boardSize);
        } else {
          return _getRandomMove(board);
        }
      case 'hard':
      default:
        return _getHeuristicMove(board, aiPlayer, opponent, boardSize);
    }
  }

  static int _getRandomMove(List<String?> board) {
    final availableMoves = <int>[];
    for (var i = 0; i < board.length; i++) {
      if (board[i] == null) {
        availableMoves.add(i);
      }
    }
    if (availableMoves.isEmpty) return -1;
    return availableMoves[_random.nextInt(availableMoves.length)];
  }

  static int _getHeuristicMove(List<String?> board, String aiPlayer, String opponent, int boardSize) {
    int bestMove = -1;
    double bestScore = -1.0;
    final candidates = <int>[];

    for (int i = 0; i < boardSize * boardSize; i++) {
      if (board[i] == null) {
        double score = _evaluateCell(board, i, aiPlayer, opponent, boardSize);
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
          candidates.clear();
          candidates.add(i);
        } else if (score == bestScore) {
          candidates.add(i);
        }
      }
    }

    if (candidates.isNotEmpty) {
      // Pick randomly among moves with the same highest score to avoid robotic playing
      return candidates[_random.nextInt(candidates.length)];
    }

    return bestMove != -1 ? bestMove : _getRandomMove(board);
  }

  static double _evaluateCell(List<String?> board, int index, String aiPlayer, String opponent, int boardSize) {
    final int row = index ~/ boardSize;
    final int col = index % boardSize;

    // Determine the win length rule dynamically
    int winLength;
    if (boardSize == 3) {
      winLength = 3;
    } else if (boardSize == 4) {
      winLength = 4;
    } else if (boardSize >= 5 && boardSize <= 10) {
      winLength = 5;
    } else {
      winLength = 7;
    }

    double cellScore = 0.0;

    // 4 directions: Horizontal, Vertical, Diagonal (Top-Left to Bottom-Right), Anti-Diagonal (Top-Right to Bottom-Left)
    final directions = [
      [0, 1],   // Horizontal
      [1, 0],   // Vertical
      [1, 1],   // Diagonal
      [1, -1]   // Anti-Diagonal
    ];

    for (var dir in directions) {
      final stepRow = dir[0];
      final stepCol = dir[1];

      // A window of [winLength] consecutive cells containing the target cell (row, col)
      // The target cell can be at any of the [winLength] positions within the window
      for (int k = -(winLength - 1); k <= 0; k++) {
        final startRow = row + k * stepRow;
        final startCol = col + k * stepCol;

        // Check if the entire [winLength]-cell window fits inside the board boundaries
        bool validWindow = true;
        int countAI = 0;
        int countOpponent = 0;

        for (int j = 0; j < winLength; j++) {
          final r = startRow + j * stepRow;
          final c = startCol + j * stepCol;

          if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) {
            validWindow = false;
            break;
          }

          final cellIndex = r * boardSize + c;
          if (cellIndex == index) {
            // This is the target cell we are evaluating (it's currently empty)
            continue;
          }

          final val = board[cellIndex];
          if (val == aiPlayer) {
            countAI++;
          } else if (val == opponent) {
            countOpponent++;
          }
        }

        if (validWindow) {
          // If the window contains both tokens, it is blocked and worth 0 points
          if (countAI > 0 && countOpponent > 0) {
            continue;
          }

          if (countAI > 0 && countOpponent == 0) {
            // Offensive: builds towards AI's win
            if (countAI == winLength - 1) {
              cellScore += 100000.0; // Win immediately
            } else if (countAI == winLength - 2) {
              cellScore += 1500.0;   // High priority attack
            } else if (countAI == winLength - 3) {
              cellScore += 150.0;
            } else if (countAI == winLength - 4) {
              cellScore += 15.0;
            } else {
              cellScore += 2.0 * countAI;
            }
          } else if (countOpponent > 0 && countAI == 0) {
            // Defensive: blocks opponent's lines
            if (countOpponent == winLength - 1) {
              cellScore += 25000.0;  // Must block immediately
            } else if (countOpponent == winLength - 2) {
              cellScore += 1000.0;   // Block potential open threats
            } else if (countOpponent == winLength - 3) {
              cellScore += 100.0;
            } else if (countOpponent == winLength - 4) {
              cellScore += 10.0;
            } else {
              cellScore += 1.0 * countOpponent;
            }
          } else {
            // Completely empty window
            cellScore += 1.0;
          }
        }
      }
    }

    return cellScore;
  }
}
