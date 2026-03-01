import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'app_state.dart';
import 'widgets.dart';

class AuthScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onAuthSuccess;

  const AuthScreen({
    super.key,
    required this.state,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  String _error = '';

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  bool _obscurePass = true;

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  // Removed static _apiBase - using widget.state.apiUrl

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final endpoint = _isLogin ? '/auth/login' : '/auth/register';
      final body = _isLogin
          ? {'email': _emailCtrl.text.trim(), 'password': _passCtrl.text}
          : {
              'email': _emailCtrl.text.trim(),
              'password': _passCtrl.text,
              'username': _userCtrl.text.trim(),
            };

      final res = await http.post(
        Uri.parse('${widget.state.apiUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        widget.state.setToken(
          data['access_token'],
          Map<String, dynamic>.from(data['user']),
        );
        widget.onAuthSuccess();
      } else {
        final err = json.decode(res.body);
        setState(() => _error = err['detail'] ?? 'Authentication failed');
      }
    } catch (e) {
      setState(
        () => _error = 'Cannot connect to server. Is the backend running?',
      );
    }
    setState(() => _loading = false);
  }

  void _toggle() {
    _animCtrl.reset();
    _animCtrl.forward();
    setState(() {
      _isLogin = !_isLogin;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: GradientBackground(
        state: s,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.accent.withOpacity(0.12),
                      border: Border.all(
                        color: s.accent.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: s.accent.withOpacity(0.3),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    child: Icon(Icons.blur_on, color: s.accent, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'VOID_OS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 28 * s.uiFontScale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI BURNOUT MONITOR',
                    style: GoogleFonts.inter(
                      fontSize: 11 * s.uiFontScale,
                      color: s.accent.withOpacity(0.7),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Card ──
                  GlassCard(
                    state: s,
                    width: 420,
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tab bar
                        Row(
                          children: [
                            _tabBtn('SIGN IN', _isLogin, () => _toggle()),
                            const SizedBox(width: 8),
                            _tabBtn('REGISTER', !_isLogin, () => _toggle()),
                          ],
                        ),
                        const SizedBox(height: 32),

                        if (!_isLogin) ...[
                          _field(_userCtrl, 'USERNAME', Icons.person_outline),
                          const SizedBox(height: 16),
                        ],
                        _field(_emailCtrl, 'EMAIL', Icons.alternate_email),
                        const SizedBox(height: 16),
                        _passField(),
                        const SizedBox(height: 8),

                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _error,
                              style: GoogleFonts.inter(
                                color: Colors.red.shade300,
                                fontSize: 12 * s.uiFontScale,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        GlowButton(
                          label: _isLogin
                              ? 'INITIALIZE SESSION'
                              : 'CREATE ACCOUNT',
                          state: s,
                          onPressed: _submit,
                          isLoading: _loading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    final s = widget.state;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active ? s.accent.withOpacity(0.15) : Colors.transparent,
            border: Border.all(
              color: active ? s.accent.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11 * s.uiFontScale,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: active ? s.accent : Colors.white30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    final s = widget.state;
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14 * s.uiFontScale,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: Colors.white24,
          letterSpacing: 2,
          fontSize: 12 * s.uiFontScale,
        ),
        prefixIcon: Icon(icon, color: s.accent.withOpacity(0.6), size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s.cardBorderRadius.toDouble()),
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s.cardBorderRadius.toDouble()),
          borderSide: BorderSide(color: s.accent.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s.cardBorderRadius.toDouble()),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }

  Widget _passField() {
    final s = widget.state;
    return TextField(
      controller: _passCtrl,
      obscureText: _obscurePass,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14 * s.uiFontScale,
      ),
      decoration: InputDecoration(
        hintText: 'PASSWORD',
        hintStyle: GoogleFonts.inter(
          color: Colors.white24,
          letterSpacing: 2,
          fontSize: 12 * s.uiFontScale,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: s.accent.withOpacity(0.6),
          size: 18,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePass ? Icons.visibility_off : Icons.visibility,
            color: Colors.white24,
            size: 18,
          ),
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s.cardBorderRadius.toDouble()),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s.cardBorderRadius.toDouble()),
          borderSide: BorderSide(color: s.accent.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s.cardBorderRadius.toDouble()),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }
}
