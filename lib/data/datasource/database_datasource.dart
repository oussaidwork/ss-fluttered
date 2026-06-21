import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract interface for all database operations.
///
/// This abstraction isolates the repository layer from the concrete
/// database implementation (Firestore). To switch databases, only
/// [FirestoreDataSourceImpl] needs to be replaced.
abstract class DatabaseDataSource {
  /// Returns a document reference for [collection]/[id].
  DocumentReference docRef(String collection, String id);

  /// Gets a single document by [collection] and [id].
  Future<DocumentSnapshot> getDoc(String collection, String id);

  /// Sets (creates or overwrites) a document.
  Future<void> setDoc(
    String collection,
    String id,
    Map<String, dynamic> data,
  );

  /// Updates fields on an existing document.
  Future<void> updateDoc(
    String collection,
    String id,
    Map<String, dynamic> data,
  );

  /// Deletes a document.
  Future<void> deleteDoc(String collection, String id);

  /// Queries a collection with a single filter.
  Future<QuerySnapshot> query(
    String collection, {
    String? filterField,
    dynamic filterValue,
    bool filterIsEqualTo = true,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  });

  /// Streams a collection with a single filter (real-time).
  Stream<QuerySnapshot> streamQuery(
    String collection, {
    String? filterField,
    dynamic filterValue,
    bool filterIsEqualTo = true,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  });

  /// Queries a collection with multiple filters.
  Future<QuerySnapshot> queryMulti(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  });

  /// Streams a collection with multiple filters (real-time).
  Stream<QuerySnapshot> streamQueryMulti(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  });

  /// Returns a write batch for atomic operations.
  WriteBatch batch();

  /// Executes a transaction.
  Future<T> runTransaction<T>(Future<T> Function(Transaction txn) handler);
}

/// A reusable filter for Firestore queries.
class QueryFilter {
  final String field;
  final dynamic value;
  final FilterOperator operator;

  const QueryFilter({
    required this.field,
    required this.value,
    this.operator = FilterOperator.isEqualTo,
  });
}

enum FilterOperator {
  isEqualTo,
  isNotEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
}
