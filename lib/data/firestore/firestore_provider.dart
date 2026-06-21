import 'package:cloud_firestore/cloud_firestore.dart';

/// Backward-compatibility wrapper.
///
/// Pages and services that haven't been fully migrated to the repository
/// pattern can still use this. New code should use repository providers
/// from `repository_providers.dart` instead.
///
/// This exposes the same `FirebaseFirestore` instance used by
/// [FirestoreDataSourceImpl], keeping the single source of truth.
final FirebaseFirestore firestore = FirebaseFirestore.instance;

DocumentReference docRef(String collection, String id) =>
    firestore.collection(collection).doc(id);
