import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sale.dart';

/// Active (non-deleted) clients stream.
final clientsProvider = StreamProvider<List<Client>>((ref) {
  return firestore.collection('clients').where('isDeleted', isEqualTo: false).orderBy('name').snapshots().map(
    (snap) => snap.docs.map((d) => Client.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

/// Archived (deleted) clients stream.
final archivedClientsProvider = StreamProvider<List<Client>>((ref) {
  return firestore.collection('clients').where('isDeleted', isEqualTo: true).orderBy('name').snapshots().map(
    (snap) => snap.docs.map((d) => Client.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

/// Stream of sales for a specific client.
final clientSalesProvider = StreamProvider.family<List<Sale>, String>((ref, clientId) {
  return firestore
      .collection(FirestorePaths.sales)
      .where('clientId', isEqualTo: clientId)
      .where('isDeleted', isEqualTo: false)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Sale.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList());
});

/// Stream of payments for a specific client.
final clientPaymentsProvider = StreamProvider.family<List<Payment>, String>((ref, clientId) {
  return firestore
      .collection(FirestorePaths.payments)
      .where('clientId', isEqualTo: clientId)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Payment.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList());
});

/// Stream of debts for a specific client.
final clientDebtsProvider = StreamProvider.family<List<Debt>, String>((ref, clientId) {
  return firestore
      .collection(FirestorePaths.debts)
      .where('clientId', isEqualTo: clientId)
      .where('isDeleted', isEqualTo: false)
      .orderBy('created', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Debt.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList());
});
