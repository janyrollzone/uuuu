import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';

enum GameStatus { playing, won, draw }

class GameProvider extends ChangeNotifier {
  int _boardSize = 10; // Default 10x10
  List<String?> _board = List.filled(100, null);
  String _currentPlayer = 'X'; // 'X' always starts
  String _gameMode = 'PvC'; // 'PvC' (Computer) or 'PvP' (Local)
  String _difficulty = 'Hard'; // 'Easy', 'Medium', 'Hard'
  GameStatus _status = GameStatus.playing;
  List<int> _winningLine = [];
  bool _isAiThinking = false;

  // Persistence stats
  int _xWins = 0;
  int _oWins = 0;
  int _draws = 0;
  int _gems = 20; // Default 20 gems
  int _lastEarnedGems = 0;
  int _winStreak = 0;
  int _bestWinStreak = 0;

  // Settings
  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  // Supabase states
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userProfile;
  bool _isSyncing = false;
  String? _onlineMatchId;
  String _onlineRole = 'X';
  String _onlineOpponentName = '';
  bool _isSearchingMatch = false;
  Timer? _onlineMatchTimer;

  // Shop states
  List<String> _unlockedItems = ['theme_cyberpunk', 'marker_cyan_magenta'];
  String _selectedTheme = 'theme_cyberpunk';
  String _selectedMarker = 'marker_cyan_magenta';

  // History for Undo
  final List<List<String?>> _history = [];
  final List<String> _playerHistory = []; // Tracks who made the moves

  // Getters
  int get boardSize => _boardSize;
  List<String?> get board => _board;
  String get currentPlayer => _currentPlayer;
  String get gameMode => _gameMode;
  String get gameModeLabel {
    if (_gameMode == 'PvC') return 'ĐẤU VỚI MÁY';
    if (_gameMode == 'Online') return 'ĐẤU ONLINE';
    return 'CHƠI 2 NGƯỜI';
  }
  String get difficulty => _difficulty;
  GameStatus get status => _status;
  List<int> get winningLine => _winningLine;
  bool get isAiThinking => _isAiThinking;
  int get xWins => _xWins;
  int get oWins => _oWins;
  int get losses => _oWins;
  int get draws => _draws;
  int get gems => _gems;
  int get lastEarnedGems => _lastEarnedGems;
  int get winStreak => _winStreak;
  int get bestWinStreak => _bestWinStreak;
  int get nextWinReward => _baseWinGemReward() + min<int>(_winStreak + 1, 5);
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;

  // Supabase getters
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isSyncing => _isSyncing;
  bool get isLoggedIn => _supabase.auth.currentUser != null;
  String? get onlineMatchId => _onlineMatchId;
  String get onlineRole => _onlineRole;
  String get onlineOpponentName => _onlineOpponentName;
  bool get isSearchingMatch => _isSearchingMatch;
  bool get isOnlineMatch => _gameMode == 'Online';
  bool get canPlayOnline => isOnlineMatch &&
      !_isSearchingMatch &&
      _onlineMatchId != null &&
      _status == GameStatus.playing &&
      _currentPlayer == _onlineRole;

  // Shop getters
  List<String> get unlockedItems => _unlockedItems;
  String get selectedTheme => _selectedTheme;
  String get selectedMarker => _selectedMarker;

  bool get canUndo => _history.isNotEmpty;

  GameProvider() {
    _loadStatsAndSettings();
  }

  Future<void> _loadStatsAndSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _xWins = prefs.getInt('xWins') ?? 0;
    _oWins = prefs.getInt('oWins') ?? 0;
    _draws = prefs.getInt('draws') ?? 0;
    _gems = prefs.getInt('gems') ?? 20;
    _winStreak = prefs.getInt('winStreak') ?? 0;
    _bestWinStreak = prefs.getInt('bestWinStreak') ?? 0;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _hapticEnabled = prefs.getBool('hapticEnabled') ?? true;
    _boardSize = prefs.getInt('boardSize') ?? 10;
    
    // Shop load
    _unlockedItems = prefs.getStringList('unlockedItems') ?? ['theme_cyberpunk', 'marker_cyan_magenta'];
    _selectedTheme = prefs.getString('selectedTheme') ?? 'theme_cyberpunk';
    _selectedMarker = prefs.getString('selectedMarker') ?? 'marker_cyan_magenta';
    
    // Safety check for boardSize limits
    if (_boardSize < 3 || _boardSize > 15) {
      _boardSize = 10;
    }
    
    _board = List.filled(_boardSize * _boardSize, null);
    
    // Fetch profile if already logged in on startup
    if (_supabase.auth.currentUser != null) {
      await _fetchProfile();
    }
    
    notifyListeners();
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xWins', _xWins);
    await prefs.setInt('oWins', _oWins);
    await prefs.setInt('draws', _draws);
    await prefs.setInt('gems', _gems);
    await prefs.setInt('winStreak', _winStreak);
    await prefs.setInt('bestWinStreak', _bestWinStreak);
    
    if (_supabase.auth.currentUser != null) {
      _pushStatsToCloud();
    }
  }

  Future<void> _saveShopSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlockedItems', _unlockedItems);
    await prefs.setString('selectedTheme', _selectedTheme);
    await prefs.setString('selectedMarker', _selectedMarker);
    
    if (_supabase.auth.currentUser != null) {
      _pushStatsToCloud();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('hapticEnabled', _hapticEnabled);
  }

  Future<void> _saveBoardSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('boardSize', _boardSize);
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    _saveSettings();
    notifyListeners();
  }

  void toggleHaptic() {
    _hapticEnabled = !_hapticEnabled;
    _saveSettings();
    notifyListeners();
  }

  void setGameMode(String mode) {
    if (mode == 'PvC' || mode == 'PvP' || mode == 'Online') {
      if (_gameMode == 'Online' && mode != 'Online') {
        _stopOnlineMatchPolling();
        _onlineMatchId = null;
        _onlineOpponentName = '';
        _isSearchingMatch = false;
      }
      _gameMode = mode;
      resetBoard();
    }
  }

  void setDifficulty(String diff) {
    if (diff == 'Easy' || diff == 'Medium' || diff == 'Hard') {
      _difficulty = diff;
      resetBoard();
    }
  }

  void setBoardSize(int size) {
    if (size >= 3 && size <= 15) {
      _boardSize = size;
      _saveBoardSize();
      resetBoard();
    }
  }

  /// Reset the scoreboard
  void clearScores() {
    _xWins = 0;
    _oWins = 0;
    _draws = 0;
    _winStreak = 0;
    _bestWinStreak = 0;
    _saveStats();
    notifyListeners();
  }

  /// Reset the game board for a new game
  void resetBoard() {
    _board = List.filled(_boardSize * _boardSize, null);
    _currentPlayer = 'X';
    _status = GameStatus.playing;
    _winningLine = [];
    _isAiThinking = false;
    _history.clear();
    _playerHistory.clear();
    _lastEarnedGems = 0;
    notifyListeners();
  }

  /// Make a player move at [index]
  void makeMove(int index) {
    if (_gameMode == 'Online') {
      _submitOnlineMove(index);
      return;
    }

    if (_board[index] != null || _status != GameStatus.playing || _isAiThinking) {
      return;
    }

    // Save state for undo
    _saveStateToHistory();

    _board[index] = _currentPlayer;
    _checkGameState();

    if (_status == GameStatus.playing) {
      _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
      notifyListeners();

      // If computer mode, trigger computer move
      if (_gameMode == 'PvC' && _currentPlayer == 'O') {
        _makeComputerMove();
      }
    } else {
      notifyListeners();
    }
  }

  void _saveStateToHistory() {
    _history.add(List.from(_board));
    _playerHistory.add(_currentPlayer);
  }

  void undoMove() {
    if (_history.isEmpty || _isAiThinking) return;

    if (_gameMode == 'PvC') {
      // In PvC mode, undo both the AI's move and the Player's move.
      int playerMoveIndex = -1;
      for (int i = _playerHistory.length - 1; i >= 0; i--) {
        if (_playerHistory[i] == 'X') {
          playerMoveIndex = i;
          break;
        }
      }

      if (playerMoveIndex != -1) {
        _board = List.from(_history[playerMoveIndex]);
        _currentPlayer = 'X';
        _status = GameStatus.playing;
        _winningLine = [];
        
        _history.removeRange(playerMoveIndex, _history.length);
        _playerHistory.removeRange(playerMoveIndex, _playerHistory.length);
      }
    } else {
      // In PvP, just undo the single last move
      _board = List.from(_history.removeLast());
      _currentPlayer = _playerHistory.removeLast();
      _status = GameStatus.playing;
      _winningLine = [];
    }

    notifyListeners();
  }

  Future<void> _makeComputerMove() async {
    _isAiThinking = true;
    notifyListeners();

    // Small delay so AI doesn't feel instant
    await Future.delayed(const Duration(milliseconds: 600));

    if (_status != GameStatus.playing) {
      _isAiThinking = false;
      return;
    }

    final aiIndex = AIService.getBestMove(_board, 'O', _difficulty, _boardSize);
    if (aiIndex != -1) {
      _saveStateToHistory();
      _board[aiIndex] = 'O';
      _checkGameState();

      if (_status == GameStatus.playing) {
        _currentPlayer = 'X';
      }
    }

    _isAiThinking = false;
    notifyListeners();
  }

  void _checkGameState() {
    // Determine the winning length rule dynamically based on board size
    int winLength;
    if (_boardSize == 3) {
      winLength = 3;
    } else if (_boardSize == 4) {
      winLength = 4;
    } else if (_boardSize >= 5 && _boardSize <= 10) {
      winLength = 5;
    } else {
      winLength = 7;
    }

    // Scan the board to check for matching lines
    for (int r = 0; r < _boardSize; r++) {
      for (int c = 0; c < _boardSize; c++) {
        final index = r * _boardSize + c;
        final token = _board[index];
        if (token == null) continue;

        // 1. Horizontal win check (rightwards)
        if (c + winLength - 1 < _boardSize) {
          final line = List.generate(winLength, (k) => index + k);
          if (line.every((idx) => _board[idx] == token)) {
            _setWinner(token, line);
            return;
          }
        }

        // 2. Vertical win check (downwards)
        if (r + winLength - 1 < _boardSize) {
          final line = List.generate(winLength, (k) => index + k * _boardSize);
          if (line.every((idx) => _board[idx] == token)) {
            _setWinner(token, line);
            return;
          }
        }

        // 3. Diagonal win check (down-right)
        if (r + winLength - 1 < _boardSize && c + winLength - 1 < _boardSize) {
          final line = List.generate(winLength, (k) => index + k * (_boardSize + 1));
          if (line.every((idx) => _board[idx] == token)) {
            _setWinner(token, line);
            return;
          }
        }

        // 4. Anti-diagonal win check (down-left)
        if (r + winLength - 1 < _boardSize && c - (winLength - 1) >= 0) {
          final line = List.generate(winLength, (k) => index + k * (_boardSize - 1));
          if (line.every((idx) => _board[idx] == token)) {
            _setWinner(token, line);
            return;
          }
        }
      }
    }

    // Check for draw
    if (!_board.contains(null)) {
      _status = GameStatus.draw;
      _draws++;
      _winStreak = 0;
      _lastEarnedGems = 0;
      _saveStats();
    }
  }

  int _baseWinGemReward() {
    if (_gameMode == 'PvC') {
      if (_difficulty == 'Easy') {
        return 2;
      } else if (_difficulty == 'Medium') {
        return 5;
      } else if (_difficulty == 'Hard') {
        return 10;
      }
    }
    return 3;
  }

  void _setWinner(String token, List<int> line) {
    _status = GameStatus.won;
    _winningLine = line;
    if (token == 'X') {
      _xWins++;
    } else {
      _oWins++;
    }

    final bool localWin = _gameMode != 'Online' || _onlineRole == token;
    if (localWin) {
      _winStreak++;
      if (_winStreak > _bestWinStreak) {
        _bestWinStreak = _winStreak;
      }
      final gemReward = _baseWinGemReward() + min<int>(_winStreak, 5);
      _gems += gemReward;
      _lastEarnedGems = gemReward;
    } else {
      _winStreak = 0;
      _lastEarnedGems = 0;
    }
    _saveStats();
  }

  /// Hồi sinh người chơi bằng cách trừ đá quý và hoàn tác nước đi chiến thắng của máy
  void revive() {
    if (_gems < 5 || _status != GameStatus.won || _gameMode != 'PvC') return;

    final winner = _board[_winningLine.first];
    if (winner != 'O') return;

    _gems -= 5;
    
    if (_oWins > 0) {
      _oWins--;
    }
    
    if (_history.isNotEmpty) {
      _board = List.from(_history.removeLast());
      _playerHistory.removeLast();
    }
    
    _currentPlayer = 'X';
    _status = GameStatus.playing;
    _winningLine = [];
    _lastEarnedGems = 0;
    _saveStats();
    notifyListeners();
  }

  /// Nhận đá quý miễn phí để kiểm thử
  void addFreeGems(int count) {
    _gems += count;
    _saveStats();
    notifyListeners();
  }

  List<String?> _boardFromRemote(dynamic remoteBoard) {
    if (remoteBoard is List) {
      return remoteBoard.map<String?>((item) {
        if (item == null) return null;
        return item.toString();
      }).toList();
    }

    return List.filled(_boardSize * _boardSize, null);
  }

  void _stopOnlineMatchPolling() {
    _onlineMatchTimer?.cancel();
    _onlineMatchTimer = null;
  }

  void _startOnlineMatchPolling() {
    _stopOnlineMatchPolling();
    _onlineMatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollOnlineMatch();
    });
  }

  void _applyOnlineMatch(Map<String, dynamic> data) {
    _onlineMatchId = data['id']?.toString();
    _onlineOpponentName = '';

    final user = _supabase.auth.currentUser;
    if (user != null) {
      final playerXId = data['player_x_id']?.toString();
      _onlineRole = playerXId == user.id ? 'X' : 'O';
      _onlineOpponentName = _onlineRole == 'X'
          ? (data['player_o_name']?.toString().isNotEmpty == true
              ? data['player_o_name'].toString()
              : 'Đang chờ...')
          : (data['player_x_name']?.toString() ?? 'Đối thủ');
    }

    final remoteBoardSize = data['board_size'];
    if (remoteBoardSize is int && remoteBoardSize >= 3 && remoteBoardSize <= 15) {
      _boardSize = remoteBoardSize;
      _board = _boardFromRemote(data['board']);
      if (_board.length != _boardSize * _boardSize) {
        _board = List.filled(_boardSize * _boardSize, null);
      }
    }

    final status = data['status']?.toString() ?? 'waiting';
    final winner = data['winner']?.toString();
    final winningLine = data['winning_line'];

    if (winningLine is List) {
      _winningLine = winningLine
          .whereType<num>()
          .map((value) => value.toInt())
          .toList();
    } else {
      _winningLine = [];
    }

    if (status == 'finished') {
      if (_status == GameStatus.playing) {
        if (winner == 'X') {
          _xWins++;
        } else if (winner == 'O') {
          _oWins++;
        } else {
          _draws++;
        }
        _winStreak = 0;
        _lastEarnedGems = 0;
        _saveStats();
      }

      _status = winner == null ? GameStatus.draw : GameStatus.won;
      _currentPlayer = data['current_player']?.toString() ?? _currentPlayer;
      _isSearchingMatch = false;
      _stopOnlineMatchPolling();
      _onlineMatchId = null;
    } else {
      _status = GameStatus.playing;
      _currentPlayer = data['current_player']?.toString() ?? 'X';
      _isSearchingMatch = status == 'waiting';
    }
  }

  Future<bool> startOnlineMatch() async {
    if (!isLoggedIn) {
      return false;
    }

    _isSearchingMatch = true;
    _onlineOpponentName = '';
    _onlineMatchId = null;
    _onlineRole = 'X';
    resetBoard();
    notifyListeners();

    try {
      final match = await _supabase.rpc(
        'find_or_create_online_match',
        params: {
          'p_board_size': _boardSize,
        },
      );

      if (match is Map) {
        _applyOnlineMatch(Map<String, dynamic>.from(match));
        _startOnlineMatchPolling();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error starting online match: $e');
    }

    _isSearchingMatch = false;
    notifyListeners();
    return false;
  }

  Future<void> _pollOnlineMatch() async {
    if (_onlineMatchId == null || _supabase.auth.currentUser == null) {
      return;
    }

    try {
      final data = await _supabase
          .from('online_matches')
          .select()
          .eq('id', _onlineMatchId!)
          .maybeSingle();

      if (data == null) {
        _stopOnlineMatchPolling();
        _onlineMatchId = null;
        _isSearchingMatch = false;
        notifyListeners();
        return;
      }

      _applyOnlineMatch(Map<String, dynamic>.from(data));
      notifyListeners();
    } catch (e) {
      debugPrint('Error polling online match: $e');
    }
  }

  Future<void> leaveOnlineMatch() async {
    if (_onlineMatchId == null || _supabase.auth.currentUser == null) {
      _stopOnlineMatchPolling();
      _onlineMatchId = null;
      _isSearchingMatch = false;
      _onlineOpponentName = '';
      notifyListeners();
      return;
    }

    final matchId = _onlineMatchId!;
    _stopOnlineMatchPolling();

    try {
      await _supabase.from('online_matches').update({
        'status': 'finished',
        'winner': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', matchId);
    } catch (e) {
      debugPrint('Error leaving online match: $e');
    }

    _onlineMatchId = null;
    _isSearchingMatch = false;
    _onlineOpponentName = '';
    _winningLine = [];
    notifyListeners();
  }

  Future<void> _submitOnlineMove(int index) async {
    final user = _supabase.auth.currentUser;
    if (user == null || _onlineMatchId == null || _status != GameStatus.playing) {
      return;
    }

    if (index < 0 || index >= _board.length) {
      return;
    }

    if (_isSearchingMatch || _board[index] != null || _currentPlayer != _onlineRole) {
      return;
    }

    final playingToken = _currentPlayer;
    _saveStateToHistory();
    _board[index] = playingToken;
    _checkGameState();

    if (_status == GameStatus.playing) {
      _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
    }

    notifyListeners();

    try {
      await _supabase.from('online_matches').update({
        'board': _board,
        'current_player': _currentPlayer,
        'status': _status == GameStatus.playing ? 'active' : 'finished',
        'winner': _status == GameStatus.won ? _board[_winningLine.first] : null,
        'winning_line': _winningLine,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _onlineMatchId!).eq('current_player', playingToken);
    } catch (e) {
      debugPrint('Error submitting online move: $e');
      await _pollOnlineMatch();
    }
  }

  // ==========================================
  // SUPABASE METHODS
  // ==========================================

  Future<void> _fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        _userProfile = data;
        // Merge stats by taking the maximum to ensure no offline progress is lost
        _gems = (_gems > (data['gems'] as int)) ? _gems : data['gems'] as int;
        _xWins = (_xWins > (data['x_wins'] as int)) ? _xWins : data['x_wins'] as int;
        _oWins = (_oWins > (data['o_wins'] as int)) ? _oWins : data['o_wins'] as int;
        _draws = (_draws > (data['draws'] as int)) ? _draws : data['draws'] as int;
        final cloudBestStreak = (data['best_win_streak'] as int?) ?? 0;
        _bestWinStreak = (_bestWinStreak > cloudBestStreak) ? _bestWinStreak : cloudBestStreak;
        
        // Merge unlocked items
        final cloudUnlocked = List<String>.from(data['unlocked_items'] ?? []);
        for (final item in cloudUnlocked) {
          if (!_unlockedItems.contains(item)) {
            _unlockedItems.add(item);
          }
        }
        _selectedTheme = data['selected_theme'] ?? _selectedTheme;
        _selectedMarker = data['selected_marker'] ?? _selectedMarker;
        
        // Save the merged stats locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('xWins', _xWins);
        await prefs.setInt('oWins', _oWins);
        await prefs.setInt('draws', _draws);
        await prefs.setInt('gems', _gems);
        await prefs.setInt('winStreak', _winStreak);
        await prefs.setInt('bestWinStreak', _bestWinStreak);
        await prefs.setStringList('unlockedItems', _unlockedItems);
        await prefs.setString('selectedTheme', _selectedTheme);
        await prefs.setString('selectedMarker', _selectedMarker);

        // If local was higher than cloud, push it to update cloud database
        bool needsPush = _gems > data['gems'] || 
            _xWins > data['x_wins'] || 
            _oWins > data['o_wins'] || 
            _draws > data['draws'] ||
            _unlockedItems.length > cloudUnlocked.length ||
            _bestWinStreak > cloudBestStreak;

        if (needsPush) {
          await _pushStatsToCloud();
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _pushStatsToCloud() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('profiles').update({
        'gems': _gems,
        'x_wins': _xWins,
        'o_wins': _oWins,
        'draws': _draws,
        'best_win_streak': _bestWinStreak,
        'unlocked_items': _unlockedItems,
        'selected_theme': _selectedTheme,
        'selected_marker': _selectedMarker,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);

      // Update cached userProfile dictionary
      if (_userProfile != null) {
        _userProfile!['gems'] = _gems;
        _userProfile!['x_wins'] = _xWins;
        _userProfile!['o_wins'] = _oWins;
        _userProfile!['draws'] = _draws;
        _userProfile!['unlocked_items'] = _unlockedItems;
        _userProfile!['selected_theme'] = _selectedTheme;
        _userProfile!['selected_marker'] = _selectedMarker;
      }
    } catch (e) {
      debugPrint('Error pushing stats to cloud: $e');
    }
  }

  Future<void> register(String email, String password, String username) async {
    _isSyncing = true;
    notifyListeners();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'gems': _gems,
          'x_wins': _xWins,
          'o_wins': _oWins,
          'draws': _draws,
        },
      );

      if (response.user != null) {
        // Wait briefly for trigger execution to create profiles row
        await Future.delayed(const Duration(milliseconds: 600));
        await _fetchProfile();
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isSyncing = true;
    notifyListeners();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _fetchProfile();
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isSyncing = true;
    notifyListeners();
    try {
      if (_onlineMatchId != null) {
        await leaveOnlineMatch();
      }
      await _supabase.auth.signOut();
      _userProfile = null;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> updateUsername(String newUsername) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isSyncing = true;
    notifyListeners();
    try {
      await _supabase.from('profiles').update({
        'username': newUsername,
      }).eq('id', user.id);

      if (_userProfile != null) {
        _userProfile!['username'] = newUsername;
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception('Không lấy được email tài khoản.');
    }

    _isSyncing = true;
    notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('username, x_wins, gems')
          .order('x_wins', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  // ==========================================
  // SHOP METHODS
  // ==========================================

  Future<bool> buyItem(ShopItem item) async {
    if (_gems < item.price || _unlockedItems.contains(item.id)) {
      return false;
    }
    
    _gems -= item.price;
    _unlockedItems.add(item.id);
    
    // Auto-equip the bought item
    if (item.category == 'theme') {
      _selectedTheme = item.id;
    } else {
      _selectedMarker = item.id;
    }
    
    await _saveStats();
    await _saveShopSettings();
    notifyListeners();
    return true;
  }

  void equipItem(String itemId, String category) {
    if (!_unlockedItems.contains(itemId)) return;
    
    if (category == 'theme') {
      _selectedTheme = itemId;
    } else {
      _selectedMarker = itemId;
    }
    
    _saveShopSettings();
    notifyListeners();
  }
}

// ==========================================
// SHOP ITEM MODEL & DATA
// ==========================================

class ShopItem {
  final String id;
  final String name;
  final String category; // 'theme' or 'marker'
  final int price;
  final String description;
  final Color previewColor1;
  final Color previewColor2;

  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.previewColor1,
    required this.previewColor2,
  });
}

const List<ShopItem> shopItems = [
  ShopItem(
    id: 'theme_cyberpunk',
    name: 'Cyberpunk Glow',
    category: 'theme',
    price: 0,
    description: 'Bàn cờ Neon cổ điển với tông màu Cyberpunk tối.',
    previewColor1: Color(0xFF0F172A),
    previewColor2: Color(0xFF1E293B),
  ),
  ShopItem(
    id: 'theme_royal_gold',
    name: 'Royal Purple',
    category: 'theme',
    price: 15,
    description: 'Bàn cờ hoàng gia với viền tím đậm và vàng kim.',
    previewColor1: Color(0xFF2E1065),
    previewColor2: Color(0xFF3B0764),
  ),
  ShopItem(
    id: 'theme_emerald_matrix',
    name: 'Emerald Matrix',
    category: 'theme',
    price: 25,
    description: 'Tông màu xanh lục bảo của ma trận huyền bí.',
    previewColor1: Color(0xFF022C22),
    previewColor2: Color(0xFF064E3B),
  ),
  ShopItem(
    id: 'theme_sunset_orange',
    name: 'Sunset Orange',
    category: 'theme',
    price: 30,
    description: 'Màu hoàng hôn ấm áp trên nền gỗ tối màu.',
    previewColor1: Color(0xFF2D1B10),
    previewColor2: Color(0xFF432818),
  ),
  ShopItem(
    id: 'marker_cyan_magenta',
    name: 'Neon Cyan & Magenta',
    category: 'marker',
    price: 0,
    description: 'X màu Cyan và O màu Magenta phát sáng.',
    previewColor1: Color(0xFF00E5FF),
    previewColor2: Color(0xFFFF007F),
  ),
  ShopItem(
    id: 'marker_gold_silver',
    name: 'Gold & Silver',
    category: 'marker',
    price: 20,
    description: 'X màu Vàng hoàng gia và O màu Bạc ánh kim.',
    previewColor1: Color(0xFFD4AF37),
    previewColor2: Color(0xFFC0C0C0),
  ),
  ShopItem(
    id: 'marker_green_red',
    name: 'Toxic & Crimson',
    category: 'marker',
    price: 15,
    description: 'X màu Xanh lá độc tố và O màu Đỏ thẫm.',
    previewColor1: Color(0xFF39FF14),
    previewColor2: Color(0xFFFF073A),
  ),
  ShopItem(
    id: 'marker_neon_purple_yellow',
    name: 'Purple & Acid',
    category: 'marker',
    price: 20,
    description: 'X màu Tím Neon và O màu Vàng chanh phát sáng.',
    previewColor1: Color(0xFFBD00FF),
    previewColor2: Color(0xFFCCFF00),
  ),
];
