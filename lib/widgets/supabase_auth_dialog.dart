import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_provider.dart';

class SupabaseAuthDialog extends StatefulWidget {
  const SupabaseAuthDialog({super.key});

  @override
  State<SupabaseAuthDialog> createState() => _SupabaseAuthDialogState();
}

class _SupabaseAuthDialogState extends State<SupabaseAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _isSignUp = false;
  bool _isEditingUsername = false;
  bool _isChangingPassword = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _errorMessage = '';
    });

    final provider = Provider.of<GameProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      if (_isSignUp) {
        await provider.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _usernameController.text.trim(),
        );
      } else {
        await provider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            content: Text(
              _isSignUp ? 'Đăng ký và đồng bộ thành công! 🎉' : 'Đăng nhập thành công! ⚡',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _saveUsername() async {
    if (_usernameController.text.trim().isEmpty) return;
    
    final provider = Provider.of<GameProvider>(context, listen: false);
    try {
      await provider.updateUsername(_usernameController.text.trim());
      setState(() {
        _isEditingUsername = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<GameProvider>(context, listen: false);
    try {
      await provider.changePassword(
        _currentPasswordController.text.trim(),
        _newPasswordController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isChangingPassword = false;
        _errorMessage = '';
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E293B),
          content: Text(
            'Đổi mật khẩu thành công!',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final userProfile = provider.userProfile;
    final isLoggedIn = provider.isLoggedIn;
    
    if (isLoggedIn && _usernameController.text.isEmpty && userProfile != null) {
      _usernameController.text = userProfile['username'] ?? '';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isLoggedIn ? 'TÀI KHOẢN CLOUD' : (_isSignUp ? 'ĐĂNG KÝ MỚI' : 'ĐĂNG NHẬP CLOUD'),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 20),

                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.outfit(color: Colors.red.shade300, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (isLoggedIn) ...[
                  // Logged In Profile UI
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E5FF).withOpacity(0.1),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 2),
                      ),
                      child: const Icon(
                        Icons.cloud_done_rounded,
                        color: Color(0xFF00E5FF),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username Field
                  Row(
                    children: [
                      Expanded(
                        child: _isEditingUsername
                            ? TextFormField(
                                controller: _usernameController,
                                style: GoogleFonts.outfit(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Biệt danh',
                                  labelStyle: GoogleFonts.outfit(color: const Color(0xFF00E5FF)),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF00E5FF)),
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BIỆT DANH',
                                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8), letterSpacing: 1),
                                  ),
                                  Text(
                                    userProfile?['username'] ?? 'Người chơi',
                                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isEditingUsername ? Icons.check_circle_outline_rounded : Icons.edit_rounded,
                          color: const Color(0xFF00E5FF),
                        ),
                        onPressed: () {
                          if (_isEditingUsername) {
                            _saveUsername();
                          } else {
                            setState(() {
                              _isEditingUsername = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isChangingPassword) ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildInputDecoration('Mật khẩu hiện tại', Icons.lock_outline_rounded),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Nhập mật khẩu hiện tại' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildInputDecoration('Mật khẩu mới', Icons.lock_reset_rounded),
                            validator: (val) => val == null || val.length < 6 ? 'Mật khẩu mới phải từ 6 ký tự' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildInputDecoration('Xác nhận mật khẩu', Icons.verified_user_outlined),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Xác nhận mật khẩu mới';
                              if (val != _newPasswordController.text.trim()) return 'Mật khẩu xác nhận không khớp';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stats overview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'DỮ LIỆU ĐÃ ĐỒNG BỘ',
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFFF007F), letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat('Wins', '${provider.xWins}', const Color(0xFF00E5FF)),
                            _buildMiniStat('Lose', '${provider.losses}', const Color(0xFFFF6B6B)),
                            _buildMiniStat('Gems', '💎 ${provider.gems}', const Color(0xFFFF007F)),
                            _buildMiniStat('Draws', '${provider.draws}', const Color(0xFF94A3B8)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (provider.isSyncing)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isChangingPassword = !_isChangingPassword;
                                _errorMessage = '';
                                _currentPasswordController.clear();
                                _newPasswordController.clear();
                                _confirmPasswordController.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _isChangingPassword ? 'HUỶ ĐỔI MK' : 'ĐỔI MẬT KHẨU',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isChangingPassword
                                ? _savePassword
                                : () async => _confirmLogout(context, provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isChangingPassword
                                  ? const Color(0xFF00E5FF).withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              foregroundColor: _isChangingPassword ? const Color(0xFF00E5FF) : Colors.red.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: (_isChangingPassword ? const Color(0xFF00E5FF) : Colors.red).withOpacity(0.3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _isChangingPassword ? 'LƯU MẬT KHẨU' : 'ĐĂNG XUẤT',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                ] else ...[
                  // Authentication form (Login / Signup)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _usernameController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildInputDecoration('Tên hiển thị (Username)', Icons.person_outline_rounded),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng điền tên hiển thị' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: _buildInputDecoration('Email', Icons.email_outlined),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Vui lòng điền Email';
                            if (!val.contains('@')) return 'Email không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: _buildInputDecoration('Mật khẩu', Icons.lock_outline_rounded),
                          validator: (val) => val == null || val.length < 6 ? 'Mật khẩu phải từ 6 ký tự' : null,
                        ),
                        if (_isSignUp) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildInputDecoration('Xác nhận mật khẩu', Icons.verified_user_outlined),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                              if (val != _passwordController.text.trim()) return 'Mật khẩu xác nhận không khớp';
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        
                        if (provider.isSyncing)
                          const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                        else
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00D2FF), Color(0xFFFF007F)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Container(
                                height: 50,
                                alignment: Alignment.center,
                                child: Text(
                                  _isSignUp ? 'ĐĂNG KÝ & ĐỒNG BỘ' : 'ĐĂNG NHẬP & ĐỒNG BỘ',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              _errorMessage = '';
                            });
                          },
                          child: Text(
                            _isSignUp ? 'Đã có tài khoản? Đăng nhập ngay' : 'Chưa có tài khoản? Đăng ký tại đây',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF00E5FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, GameProvider provider) async {
    final navigator = Navigator.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Đăng xuất?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất tài khoản này không?',
          style: GoogleFonts.outfit(color: const Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('HỦY', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('ĐĂNG XUẤT', style: GoogleFonts.outfit(color: Colors.red.shade300, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await provider.logout();
    if (!mounted) return;
    navigator.pop();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
      filled: true,
      fillColor: const Color(0xFF0F172A).withOpacity(0.4),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
