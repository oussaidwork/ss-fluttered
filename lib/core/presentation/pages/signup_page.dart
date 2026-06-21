import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/auth/firebase_auth_provider.dart';
import '../../../data/firestore/firestore_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../router/app_router.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: cs.error),
    );
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
                  'Create your account to get started\nwith industrial-grade station management.',
                  style: TextStyle(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.6), height: 1.5),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildSignupForm(cs),
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
            _buildSignupForm(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm(ColorScheme cs) {
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
            'Create Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text('Fill in the details below', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            style: TextStyle(color: cs.onSurface),
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(label: 'Full Name', icon: Icons.person, cs: cs),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            style: TextStyle(color: cs.onSurface),
            keyboardType: TextInputType.emailAddress,
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
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: TextStyle(color: cs.onSurface),
            decoration: _inputDecoration(label: 'Confirm Password', icon: Icons.lock_outline, cs: cs),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignup,
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
                  : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: Text(
              'Already have an account? Sign In',
              style: TextStyle(color: cs.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError('All fields are required.');
      return;
    }

    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await firebaseAuthProvider.signUp(email, password);

      await firestore.collection('users').doc(credential.user!.uid).set({
        'fullName': name,
        'email': email,
        'role': 'Worker',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully! You can now sign in.'),
            backgroundColor: cs.secondary,
          ),
        );
        context.go(AppRoutes.login);
      }
    } on FirebaseAuthException catch (e) {
      _showError('${e.code}: ${e.message ?? 'Signup failed'}');
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
