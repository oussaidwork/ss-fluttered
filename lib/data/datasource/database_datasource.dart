/// Abstract interface for all database operations.
///
/// This abstraction isolates the repository layer from the concrete
/// database implementation (Firestore). To switch databases, only
/// [FirestoreDataSourceImpl] needs to be replaced.
abstract class DatabaseDataSource {
  /// Generates a unique document ID for [collection].
  String generateId(String collection);

  /// Gets a single document by [collection] and [id].
  Future<DatabaseDocSnapshot?> getDoc(String collection, String id);

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

  /// Queries a collection with optional filters.
  Future<DatabaseQuerySnapshot> query(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  });

  /// Streams a collection with optional filters (real-time).
  Stream<DatabaseQuerySnapshot> streamQuery(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  });

  /// Returns a batch for atomic multi-document operations.
  DatabaseBatch batch();

  /// Executes a transaction.
  Future<T> runTransaction<T>(Future<T> Function(DatabaseTransaction txn) handler);
}

/// Abstract database document snapshot.
abstract class DatabaseDocSnapshot {
  String get id;
  bool get exists;
  Map<String, dynamic>? data();
}

/// Abstract database query result.
abstract class DatabaseQuerySnapshot {
  List<DatabaseDocSnapshot> get docs;
}

/// Abstract batch writer for atomic multi-document operations.
abstract class DatabaseBatch {
  void set(String collection, String id, Map<String, dynamic> data);
  void update(String collection, String id, Map<String, dynamic> data);
  void delete(String collection, String id);
  Future<void> commit();
}

/// Abstract transaction for atomic read-write operations.
abstract class DatabaseTransaction {
  Future<DatabaseDocSnapshot?> get(String collection, String id);
  void set(String collection, String id, Map<String, dynamic> data);
  void update(String collection, String id, Map<String, dynamic> data);
  void delete(String collection, String id);
}

/// A reusable filter for database queries.
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
