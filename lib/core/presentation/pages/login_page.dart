import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/auth/firebase_auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../router/app_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      _emailController.text = prefs.getString('remembered_email') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0xFF1A2332), Color(0xFF0B1220)],
          ),
        ),
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(64),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_gas_station, size: 64, color: Color(0xFF84CC16)),
                SizedBox(height: 24),
                Text(
                  'SS-RAGRAGA',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Station OS',
                  style: TextStyle(fontSize: 24, color: Colors.white54),
                ),
                SizedBox(height: 32),
                Text(
                  'Industrial-grade POS and operations management\nfor fuel/gas stations',
                  style: TextStyle(fontSize: 16, color: Colors.white38, height: 1.5),
                ),
                SizedBox(height: 48),
                _FeatureRow(icon: Icons.local_gas_station, text: 'Fuel dispensing & inventory'),
                SizedBox(height: 12),
                _FeatureRow(icon: Icons.schedule, text: 'Shift management'),
                SizedBox(height: 12),
                _FeatureRow(icon: Icons.assessment, text: 'Reports & analytics'),
                SizedBox(height: 12),
                _FeatureRow(icon: Icons.people, text: 'Client & debt ledger'),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildLoginForm(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_gas_station, size: 48, color: Color(0xFF84CC16)),
            const SizedBox(height: 16),
            const Text(
              'SS-RAGRAGA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            _buildLoginForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Enter your credentials', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.email, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF0B1220),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF84CC16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.lock, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF0B1220),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF84CC16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() => _rememberMe = value ?? false);
                  },
                  activeColor: const Color(0xFF84CC16),
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Remember me',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      try {
                        await firebaseAuthProvider.signIn(
                          _emailController.text.trim(),
                          _passwordController.text,
                        );

                        final prefs = await SharedPreferences.getInstance();
                        if (_rememberMe) {
                          await prefs.setBool('remember_me', true);
                          await prefs.setString('remembered_email', _emailController.text.trim());
                        } else {
                          await prefs.remove('remember_me');
                          await prefs.remove('remembered_email');
                        }
                        // Successful sign‑in will trigger authStateProvider and router redirect.
                      } on FirebaseAuthException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.code == 'invalid-api-key'
                                    ? 'Invalid API key – check the Firebase console for restrictions and ensure localhost is an authorized domain.'
                                    : '${e.code}: ${e.message ?? 'Sign‑in failed'}',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: const Color(0xFF0B1220),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0B1220),
                      ),
                    )
                  : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go(AppRoutes.signup),
            child: const Text(
              "Don't have an account? Create one",
              style: TextStyle(color: Color(0xFF84CC16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF84CC16)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }
}
