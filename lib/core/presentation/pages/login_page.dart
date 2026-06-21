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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required ColorScheme cs,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      prefixIcon: Icon(icon, color: cs.onSurfaceVariant),
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.secondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [cs.surface, cs.surfaceContainerHighest],
          ),
        ),
        child: isDesktop ? _buildDesktopLayout(cs) : _buildMobileLayout(cs),
      ),
    );
  }

  Widget _buildDesktopLayout(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_gas_station, size: 64, color: cs.secondary),
                const SizedBox(height: 24),
                Text(
                  'SS-RAGRAGA',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Station OS',
                  style: TextStyle(fontSize: 24, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                Text(
                  'Industrial-grade POS and operations management\nfor fuel/gas stations',
                  style: TextStyle(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.6), height: 1.5),
                ),
                const SizedBox(height: 48),
                _FeatureRow(icon: Icons.local_gas_station, text: 'Fuel dispensing & inventory', cs: cs),
                const SizedBox(height: 12),
                _FeatureRow(icon: Icons.schedule, text: 'Shift management', cs: cs),
                const SizedBox(height: 12),
                _FeatureRow(icon: Icons.assessment, text: 'Reports & analytics', cs: cs),
                const SizedBox(height: 12),
                _FeatureRow(icon: Icons.people, text: 'Client & debt ledger', cs: cs),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildLoginForm(cs),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ColorScheme cs) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station, size: 48, color: cs.secondary),
            const SizedBox(height: 16),
            Text(
              'SS-RAGRAGA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            _buildLoginForm(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sign In',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text('Enter your credentials', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            style: TextStyle(color: cs.onSurface),
            decoration: _inputDecoration(label: 'Email', icon: Icons.email, cs: cs),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: cs.onSurface),
            decoration: _inputDecoration(label: 'Password', icon: Icons.lock, cs: cs),
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
                  activeColor: cs.secondary,
                  side: BorderSide(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Remember me',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
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
                backgroundColor: cs.secondary,
                foregroundColor: cs.onSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSecondary,
                      ),
                    )
                  : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go(AppRoutes.signup),
            child: Text(
              "Don't have an account? Create one",
              style: TextStyle(color: cs.secondary),
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
  final ColorScheme cs;
  const _FeatureRow({required this.icon, required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.secondary),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
      ],
    );
  }
}
