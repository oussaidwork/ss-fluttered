import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../../data/firestore/firestore_provider.dart';

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _UserSeed {
  final String displayName;
  final String email;
  final String password;
  final String role;
  String status = 'pending';
  String? uid;
  String? error;

  _UserSeed({
    required this.displayName,
    required this.email,
    required this.password,
    required this.role,
  });
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  bool _isRunning = false;
  bool _done = false;

  final _users = [
    _UserSeed(displayName: 'ssragraga', email: 'ssragraga@gmail.com', password: '123654789d', role: 'Admin'),
    _UserSeed(displayName: 'Mohamed', email: 'ssragraga.user1@gmail.com', password: '123654user1', role: 'Worker'),
    _UserSeed(displayName: 'Abdessadek', email: 'ssragraga.user2@gmail.com', password: '123654user2', role: 'Worker'),
    _UserSeed(displayName: 'ABDilah', email: 'ssragraga.user3@gmail.com', password: '123654user3', role: 'Worker'),
    _UserSeed(displayName: 'SSRAG-audit', email: 'ssragragaadmin@gmail.com', password: '123654789a', role: 'Audit'),
  ];

  int _created = 0;
  int _failed = 0;

  // Firebase Auth REST API endpoint
  static const _authApiKey = 'AIzaSyAMPx-kaKzBr2hhDbFUXeNlsDpnGiRaMeE';
  static const _signUpUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_authApiKey';

  Future<void> _createAllUsers() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _done = false;
      _created = 0;
      _failed = 0;
      for (final u in _users) {
        u.status = 'pending';
        u.uid = null;
        u.error = null;
      }
    });

    for (final user in _users) {
      await _createSingleUser(user);
      setState(() {});
    }

    setState(() {
      _isRunning = false;
      _done = true;
    });
  }

  Future<void> _createSingleUser(_UserSeed user) async {
    try {
      // Step 1: Create Firebase Auth account via REST API
      setState(() => user.status = 'creating_auth');

      final response = await _post(_signUpUrl, {
        'email': user.email,
        'password': user.password,
        'returnSecureToken': true,
      });

      if (response['error'] != null) {
        final msg = response['error']['message'] ?? 'Unknown auth error';
        // Handle email-already-exists: try to extract uid from error
        if (msg == 'EMAIL_EXISTS') {
          // Already exists — skip auth creation, try to get UID via signIn
          setState(() {
            user.status = 'creating_profile';
            user.error = 'Auth account already exists';
          });
          // We can't get UID from signIn without creating a session
          // Just create Firestore profile with a placeholder UID
          // Actually, let's skip and mark as skipped
          setState(() {
            user.status = 'error';
            user.error = 'Account already exists — skip or delete manually';
          });
          _failed++;
          return;
        }
        setState(() {
          user.status = 'error';
          user.error = msg;
        });
        _failed++;
        return;
      }

      final uid = response['localId'] as String;
      user.uid = uid;

      // Step 2: Create Firestore user profile
      setState(() => user.status = 'creating_profile');

      await firestore.collection('users').doc(uid).set({
        'fullName': user.displayName,
        'email': user.email,
        'role': user.role,
        'isActive': true,
        'monthlySalary': null,
        'isDeleted': false,
      });

      setState(() {
        user.status = 'done';
        user.error = null;
      });
      _created++;
    } catch (e) {
      setState(() {
        user.status = 'error';
        user.error = e.toString();
      });
      _failed++;
    }
  }

  Future<Map<String, dynamic>> _post(String url, Map<String, dynamic> body) async {
    final completer = Completer<Map<String, dynamic>>();
    final xhr = html.HttpRequest();

    xhr.open('POST', url, async: true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.timeout = 30000;

    xhr.onLoad.listen((_) {
      try {
        completer.complete(jsonDecode(xhr.responseText!) as Map<String, dynamic>);
      } catch (e) {
        completer.complete({'error': {'message': 'Invalid response: ${xhr.responseText}'}});
      }
    });
    xhr.onError.listen((_) {
      completer.complete({'error': {'message': 'Network error'}});
    });
    xhr.onTimeout.listen((_) {
      completer.complete({'error': {'message': 'Request timed out'}});
    });

    xhr.send(jsonEncode(body));
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Initial User Setup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              if (!_done && !_isRunning)
                ElevatedButton.icon(
                  onPressed: _createAllUsers,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Create All Users'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    foregroundColor: const Color(0xFF0B1220),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              if (_done)
                Chip(
                  avatar: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  label: Text(
                    'Done — $_created created, $_failed failed',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF84CC16).withAlpha(50),
                  side: const BorderSide(color: Color(0xFF84CC16)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Creates Firebase Auth accounts + Firestore user profiles in one go.\n'
            'This is a one-time operation — only run when setting up the station for the first time.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Users table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF111A2E),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('NAME', style: _headerStyle)),
                        Expanded(flex: 4, child: Text('EMAIL', style: _headerStyle)),
                        Expanded(flex: 2, child: Text('ROLE', style: _headerStyle)),
                        Expanded(flex: 3, child: Text('STATUS', style: _headerStyle)),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),

                  // Table rows
                  ...List.generate(_users.length, (i) {
                    final u = _users[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: i.isEven ? Colors.transparent : Colors.white.withAlpha(5),
                        border: const Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _roleColor(u.role).withAlpha(40),
                                  child: Text(
                                    u.displayName[0].toUpperCase(),
                                    style: TextStyle(color: _roleColor(u.role), fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(u.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(u.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _roleColor(u.role).withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                u.role,
                                style: TextStyle(color: _roleColor(u.role), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          Expanded(flex: 3, child: _buildStatusWidget(u)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(_UserSeed user) {
    switch (user.status) {
      case 'pending':
        return const Text('Waiting...', style: TextStyle(color: Colors.white38, fontSize: 13));
      case 'creating_auth':
        return Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0066CC)),
            ),
            const SizedBox(width: 8),
            const Text('Creating auth...', style: TextStyle(color: Color(0xFF0066CC), fontSize: 13)),
          ],
        );
      case 'creating_profile':
        return Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF84CC16)),
            ),
            const SizedBox(width: 8),
            const Text('Creating profile...', style: TextStyle(color: Color(0xFF84CC16), fontSize: 13)),
          ],
        );
      case 'done':
        return Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF84CC16), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Created${user.uid != null ? ' (${user.uid!.substring(0, 8)}...)' : ''}',
                style: const TextStyle(color: Color(0xFF84CC16), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'error':
        return Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                user.error ?? 'Unknown error',
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return const Color(0xFF0066CC);
      case 'Worker':
        return const Color(0xFF84CC16);
      case 'Audit':
        return const Color(0xFFEAB308);
      default:
        return Colors.white54;
    }
  }
}

const _headerStyle = TextStyle(
  color: Colors.white38,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.2,
);
