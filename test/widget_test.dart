import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caro_game/models/game_provider.dart';
import 'package:caro_game/services/ai_service.dart';
import 'package:caro_game/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Caro Bàn Cờ Động GameProvider Tests', () {
    late GameProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AudioService.isTesting = true;
      provider = GameProvider();
    });

    test('Thay đổi kích thước bàn cờ khởi tạo lại mảng ô cờ chính xác', () {
      provider.setBoardSize(3);
      expect(provider.board.length, 9);
      expect(provider.board, List.filled(9, null));

      provider.setBoardSize(5);
      expect(provider.board.length, 25);

      provider.setBoardSize(15);
      expect(provider.board.length, 225);
    });

    test('Luật 3 quân thắng trên bàn cờ 3x3', () {
      provider.setBoardSize(3);
      provider.setGameMode('PvP');

      // Chuỗi 3 quân hàng ngang của X: 0, 1, 2
      // O đánh ô khác không chặn: 3, 4
      provider.makeMove(0); // X
      provider.makeMove(3); // O
      provider.makeMove(1); // X
      provider.makeMove(4); // O
      provider.makeMove(2); // X

      expect(provider.status, GameStatus.won);
      expect(provider.winningLine, [0, 1, 2]);
    });

    test('Luật 5 quân thắng trên bàn cờ 10x10', () {
      provider.setBoardSize(10);
      provider.setGameMode('PvP');

      // Chuỗi 5 quân hàng ngang của X: 0, 1, 2, 3, 4
      // O đánh ô khác: 10, 11, 12, 13
      provider.makeMove(0);  // X
      provider.makeMove(10); // O
      provider.makeMove(1);  // X
      provider.makeMove(11); // O
      provider.makeMove(2);  // X
      provider.makeMove(12); // O
      provider.makeMove(3);  // X
      provider.makeMove(13); // O
      provider.makeMove(4);  // X

      expect(provider.status, GameStatus.won);
      expect(provider.winningLine, [0, 1, 2, 3, 4]);
    });

    test('Luật 7 quân thắng trên bàn cờ 15x15', () {
      provider.setBoardSize(15);
      provider.setGameMode('PvP');

      // Chuỗi 7 quân hàng dọc của X:
      // X đánh các ô: 0, 15, 30, 45, 60, 75, 90
      // O đánh các ô không chặn: 1, 2, 3, 4, 5, 6
      provider.makeMove(0);  // X
      provider.makeMove(1);  // O
      provider.makeMove(15); // X
      provider.makeMove(2);  // O
      provider.makeMove(30); // X
      provider.makeMove(3);  // O
      provider.makeMove(45); // X
      provider.makeMove(4);  // O
      provider.makeMove(60); // X
      provider.makeMove(5);  // O
      provider.makeMove(75); // X
      provider.makeMove(6);  // O
      provider.makeMove(90); // X (Đủ 7 quân)

      expect(provider.status, GameStatus.won);
      expect(provider.winningLine, [0, 15, 30, 45, 60, 75, 90]);
    });

    test('Cộng đá quý miễn phí hoạt động chính xác', () {
      expect(provider.gems, 20);
      provider.addFreeGems(15);
      expect(provider.gems, 35);
    });

    test('Thắng trận PvP được cộng 3 đá quý kèm 1 đá quý thưởng chuỗi thắng', () {
      provider.setGameMode('PvP');
      provider.setBoardSize(3);

      provider.makeMove(0); // X
      provider.makeMove(3); // O
      provider.makeMove(1); // X
      provider.makeMove(4); // O
      provider.makeMove(2); // X thắng

      expect(provider.status, GameStatus.won);
      expect(provider.gems, 24); // 20 + 3 (base) + 1 (streak bonus)
      expect(provider.lastEarnedGems, 4);
    });
  });

  group('AIService Heuristic Tests cho bàn cờ động', () {
    test('AI chặn đòn 4 quân trên bàn cờ 10x10 (cần 5 quân để thắng)', () {
      final board = List<String?>.filled(100, null);
      // Đối thủ (X) xếp chuỗi 4 quân ngang tại 0, 1, 2, 3. Điểm thắng là ô số 4.
      board[0] = 'X';
      board[1] = 'X';
      board[2] = 'X';
      board[3] = 'X';

      final aiMove = AIService.getBestMove(board, 'O', 'Hard', 10);
      expect(aiMove, 4); // AI phải chặn ở ô số 4
    });

    test('AI chặn đòn 6 quân trên bàn cờ 15x15 (cần 7 quân để thắng)', () {
      final board = List<String?>.filled(225, null);
      // Đối thủ (X) có chuỗi 6 quân dọc tại 0, 15, 30, 45, 60, 75. Điểm thắng là ô số 90.
      board[0] = 'X';
      board[15] = 'X';
      board[30] = 'X';
      board[45] = 'X';
      board[60] = 'X';
      board[75] = 'X';

      final aiMove = AIService.getBestMove(board, 'O', 'Hard', 15);
      expect(aiMove, 90); // AI phải chặn ở ô số 90
    });
  });
}
