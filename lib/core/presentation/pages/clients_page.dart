import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/client.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Client Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 260,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF1A2332),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showClientDialog(),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Add Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('clients')
                  .where('isDeleted', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0066CC)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }
                final clients = snapshot.data!.docs
                    .map((doc) => Client.fromMap(doc.data() as Map<String, dynamic>))
                    .where((c) => _searchQuery.isEmpty || c.name.toLowerCase().contains(_searchQuery))
                    .toList();
                if (clients.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildClientTable(clients);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No clients match "$_searchQuery"' : 'No clients yet',
            style: const TextStyle(fontSize: 18, color: Colors.white54),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showClientDialog(),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add First Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientTable(List<Client> clients) {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
            columns: const [
              DataColumn(label: Text('Name', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Phone', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Plate', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Credit Limit', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Balance', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            ],
            rows: clients.map((client) {
              final overCredit = client.creditLimit != null &&
                  client.currentBalance > 0 &&
                  client.currentBalance >= client.creditLimit!;
              final balanceColor = client.currentBalance > 0
                  ? const Color(0xFFEF4444)
                  : client.currentBalance < 0
                      ? const Color(0xFF84CC16)
                      : Colors.white54;
              return DataRow(
                cells: [
                  DataCell(
                    Text(client.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                  DataCell(Text(client.phone ?? '--', style: const TextStyle(color: Colors.white70))),
                  DataCell(Text(client.plateNumber ?? '--', style: const TextStyle(color: Colors.white70))),
                  DataCell(Text(
                    client.creditLimit != null ? '${client.creditLimit!.toStringAsFixed(0)} DA' : '--',
                    style: const TextStyle(color: Colors.white70),
                  )),
                  DataCell(Text(
                    '${client.currentBalance.toStringAsFixed(2)} DA',
                    style: TextStyle(color: balanceColor, fontWeight: FontWeight.w600),
                  )),
                  DataCell(_buildClientStatus(overCredit, client.currentBalance)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Color(0xFF0066CC)),
                          onPressed: () => _showClientDialog(client: client),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () => _deleteClient(client),
                          tooltip: 'Delete',
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

  Widget _buildClientStatus(bool overCredit, double balance) {
    if (overCredit) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'OVER LIMIT',
          style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    }
    if (balance > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'OWES',
          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF84CC16).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'OK',
        style: TextStyle(color: Color(0xFF84CC16), fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _showClientDialog({Client? client}) async {
    final isEdit = client != null;
    final nameCtrl = TextEditingController(text: client?.name ?? '');
    final phoneCtrl = TextEditingController(text: client?.phone ?? '');
    final plateCtrl = TextEditingController(text: client?.plateNumber ?? '');
    final creditCtrl = TextEditingController(
      text: client?.creditLimit != null ? client!.creditLimit!.toStringAsFixed(0) : '',
    );
    final addressCtrl = TextEditingController(text: client?.address ?? '');
    final emailCtrl = TextEditingController(text: client?.email ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit : Icons.person_add, color: const Color(0xFF0066CC), size: 22),
            const SizedBox(width: 8),
            Text(
              isEdit ? 'Edit Client' : 'Add Client',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameCtrl, 'Full Name *', Icons.person),
                  const SizedBox(height: 12),
                  _buildTextField(phoneCtrl, 'Phone', Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildTextField(plateCtrl, 'Plate Number', Icons.directions_car),
                  const SizedBox(height: 12),
                  _buildTextField(creditCtrl, 'Credit Limit (DA)', Icons.credit_card,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildTextField(addressCtrl, 'Address', Icons.home),
                  const SizedBox(height: 12),
                  _buildTextField(emailCtrl, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await _saveClient(
                id: client?.id,
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                plateNumber: plateCtrl.text.trim(),
                creditLimit: double.tryParse(creditCtrl.text),
                address: addressCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                currentBalance: client?.currentBalance ?? 0.0,
                isEdit: isEdit,
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0066CC)),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _saveClient({
    String? id,
    required String name,
    required String phone,
    required String plateNumber,
    double? creditLimit,
    required String address,
    required String email,
    required double currentBalance,
    required bool isEdit,
  }) async {
    final data = {
      'name': name,
      'phone': phone.isNotEmpty ? phone : null,
      'plateNumber': plateNumber.isNotEmpty ? plateNumber : null,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'address': address.isNotEmpty ? address : null,
      'email': email.isNotEmpty ? email : null,
      'isDeleted': false,
    };
    if (isEdit && id != null) {
      await firestore.collection('clients').doc(id).update(data);
    } else {
      final docRef = firestore.collection('clients').doc();
      data['id'] = docRef.id;
      await docRef.set(data);
    }
  }

  Future<void> _deleteClient(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Client', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${client.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await firestore.collection('clients').doc(client.id).update({'isDeleted': true});
    }
  }
}
