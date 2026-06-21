import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/salary_advance.dart';
import '../../../domain/enums/user_role.dart';

class WorkersPage extends StatefulWidget {
  const WorkersPage({super.key});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Worker Profiles',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showWorkerDialog(),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add Worker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                final cs = Theme.of(context).colorScheme;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: cs.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }
                final workers = snapshot.data!.docs
                    .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
                    .where((w) => w.role != UserRole.audit)
                    .toList();
                if (workers.isEmpty) return _buildEmptyState();
                return Column(
                  children: [
                    Expanded(child: _buildWorkerTable(workers)),
                    const SizedBox(height: 20),
                    _buildAdvancesSection(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_add, size: 64, color: cs.onSurface.withValues(alpha: 0.24)),
          const SizedBox(height: 16),
          Text('No workers yet', style: TextStyle(fontSize: 18, color: cs.onSurface.withValues(alpha: 0.54))),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showWorkerDialog(),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add First Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerTable(List<UserProfile> workers) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(cs.onSurface.withValues(alpha: 0.05)),
            columns: [
              DataColumn(label: Text('Name', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Role', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Status', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Monthly Salary', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Actions', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
            ],
            rows: workers.map((worker) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    worker.fullName ?? worker.email,
                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
                  )),
                  DataCell(_buildRoleBadge(worker.role)),
                  DataCell(_buildActiveBadge(worker.isActive)),
                  DataCell(Text(
                    worker.monthlySalary != null ? '${worker.monthlySalary!.toStringAsFixed(0)} DA' : '--',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                  )),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 18, color: cs.primary),
                          onPressed: () => _showWorkerDialog(worker: worker),
                          tooltip: 'Edit',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    final cs = Theme.of(context).colorScheme;
    Color color;
    switch (role) {
      case UserRole.superUser:
        color = cs.tertiary;
        break;
      case UserRole.admin:
        color = cs.primary;
        break;
      case UserRole.worker:
        color = cs.secondary;
        break;
      case UserRole.audit:
        color = cs.onSurface.withValues(alpha: 0.54);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.value,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildActiveBadge(bool isActive) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? cs.secondary : cs.error).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? cs.secondary : cs.error,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAdvancesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('salary_advances')
          .where('status', isEqualTo: 'PENDING')
          .snapshots(),
      builder: (context, snapshot) {
        final cs = Theme.of(context).colorScheme;
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final advances = snapshot.data!.docs
            .map((doc) => SalaryAdvance.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        return Card(
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: cs.tertiary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pending Salary Advances (${advances.length})',
                      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...advances.map((a) => _advanceRow(a)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _advanceRow(SalaryAdvance advance) {
    return FutureBuilder<DocumentSnapshot>(
      future: firestore.collection('users').doc(advance.workerId).get(),
      builder: (ctx, snap) {
        final cs = Theme.of(ctx).colorScheme;
        final workerName = snap.data?.exists == true
            ? ((snap.data!.data() as Map<String, dynamic>?)?['fullName'] ?? advance.workerId)
            : advance.workerId;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workerName, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      '${advance.amount.toStringAsFixed(0)} DA — ${_formatDate(advance.requestDate)}',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.check_circle, color: cs.secondary, size: 20),
                    onPressed: () => _resolveAdvance(advance, 'APPROVED'),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: cs.error, size: 20),
                    onPressed: () => _resolveAdvance(advance, 'REJECTED'),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _resolveAdvance(SalaryAdvance advance, String status) async {
    await firestore.collection('salary_advances').doc(advance.id).update({
      'status': status,
      'resolutionDate': Timestamp.now(),
    });
  }

  Future<void> _showWorkerDialog({UserProfile? worker}) async {
    final isEdit = worker != null;
    final nameCtrl = TextEditingController(text: worker?.fullName ?? '');
    final emailCtrl = TextEditingController(text: worker?.email ?? '');
    final salaryCtrl = TextEditingController(
      text: worker?.monthlySalary != null ? worker!.monthlySalary!.toStringAsFixed(0) : '',
    );
    UserRole selectedRole = worker?.role ?? UserRole.worker;
    bool isActive = worker?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            backgroundColor: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.person_add, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text(isEdit ? 'Edit Worker' : 'Add Worker', style: TextStyle(color: cs.onSurface)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(cs, nameCtrl, 'Full Name', Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(cs, emailCtrl, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildTextField(cs, salaryCtrl, 'Monthly Salary (DA)', Icons.attach_money, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      dropdownColor: cs.surfaceContainerHighest,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Role',
                        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: cs.primary),
                        ),
                      ),
                      items: [UserRole.worker, UserRole.admin, UserRole.superUser]
                          .map((r) => DropdownMenuItem(value: r, child: Text(r.value)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text('Active', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
                      value: isActive,
                      activeThumbColor: cs.secondary,
                      onChanged: (val) => setDialogState(() => isActive = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                  await _saveWorker(
                    id: worker?.id,
                    fullName: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    role: selectedRole,
                    isActive: isActive,
                    monthlySalary: double.tryParse(salaryCtrl.text),
                    isEdit: isEdit,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(ColorScheme cs, TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
        prefixIcon: Icon(icon, color: cs.onSurface.withValues(alpha: 0.38), size: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.primary),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _saveWorker({
    String? id,
    required String fullName,
    required String email,
    required UserRole role,
    required bool isActive,
    double? monthlySalary,
    required bool isEdit,
  }) async {
    final data = {
      'fullName': fullName,
      'email': email,
      'role': role.value,
      'isActive': isActive,
      'monthlySalary': monthlySalary,
    };
    if (isEdit && id != null) {
      await firestore.collection('users').doc(id).update(data);
    } else {
      final docRef = firestore.collection('users').doc();
      data['id'] = docRef.id;
      await docRef.set(data);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
