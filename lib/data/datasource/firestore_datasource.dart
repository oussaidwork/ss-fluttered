import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_datasource.dart';

/// Firestore implementation of [DatabaseDataSource].
///
/// This is the single place where all Firestore SDK calls live.
/// Repository implementations depend only on the abstract interface.
class FirestoreDataSourceImpl implements DatabaseDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  String generateId(String collection) =>
      _firestore.collection(collection).doc().id;

  @override
  Future<DatabaseDocSnapshot?> getDoc(String collection, String id) async {
    final snap = await _firestore.collection(collection).doc(id).get();
    return snap.exists ? FirestoreDocSnapshot(snap) : null;
  }

  @override
  Future<void> setDoc(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) =>
      _firestore.collection(collection).doc(id).set(data);

  @override
  Future<void> updateDoc(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) =>
      _firestore.collection(collection).doc(id).update(data);

  @override
  Future<void> deleteDoc(String collection, String id) =>
      _firestore.collection(collection).doc(id).delete();

  @override
  Future<DatabaseQuerySnapshot> query(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  }) async {
    final q = _buildQuery(
      collection,
      filters: filters,
      orderByField: orderByField,
      orderByDescending: orderByDescending,
      limit: limit,
    );
    final snap = await q.get();
    return FirestoreQuerySnapshot(snap);
  }

  @override
  Stream<DatabaseQuerySnapshot> streamQuery(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  }) {
    final q = _buildQuery(
      collection,
      filters: filters,
      orderByField: orderByField,
      orderByDescending: orderByDescending,
      limit: limit,
    );
    return q.snapshots().map((snap) => FirestoreQuerySnapshot(snap));
  }

  Query _buildQuery(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  }) {
    Query q = _firestore.collection(collection);

    if (filters != null) {
      for (final f in filters) {
        switch (f.operator) {
          case FilterOperator.isEqualTo:
            q = q.where(f.field, isEqualTo: f.value);
            break;
          case FilterOperator.isNotEqualTo:
            q = q.where(f.field, isNotEqualTo: f.value);
            break;
          case FilterOperator.isGreaterThan:
            q = q.where(f.field, isGreaterThan: f.value);
            break;
          case FilterOperator.isGreaterThanOrEqualTo:
            q = q.where(f.field, isGreaterThanOrEqualTo: f.value);
            break;
          case FilterOperator.isLessThan:
            q = q.where(f.field, isLessThan: f.value);
            break;
          case FilterOperator.isLessThanOrEqualTo:
            q = q.where(f.field, isLessThanOrEqualTo: f.value);
            break;
        }
      }
    }

    if (orderByField != null) {
      q = q.orderBy(orderByField, descending: orderByDescending);
    }

    if (limit != null) {
      q = q.limit(limit);
    }

    return q;
  }

  @override
  DatabaseBatch batch() => FirestoreBatch(_firestore.batch(), _firestore);

  @override
  Future<T> runTransaction<T>(
      Future<T> Function(DatabaseTransaction txn) handler) {
    return _firestore.runTransaction((txn) {
      return handler(FirestoreTransaction(txn, _firestore));
    });
  }
}

/// Firestore wrapper for [DatabaseDocSnapshot].
class FirestoreDocSnapshot extends DatabaseDocSnapshot {
  final DocumentSnapshot _snap;

  FirestoreDocSnapshot(this._snap);

  @override
  String get id => _snap.id;

  @override
  bool get exists => _snap.exists;

  @override
  Map<String, dynamic>? data() => _snap.data() as Map<String, dynamic>?;
}

/// Firestore wrapper for [DatabaseQuerySnapshot].
class FirestoreQuerySnapshot extends DatabaseQuerySnapshot {
  final QuerySnapshot _snap;

  FirestoreQuerySnapshot(this._snap);

  @override
  List<DatabaseDocSnapshot> get docs =>
      _snap.docs.map((d) => FirestoreDocSnapshot(d)).toList();
}

/// Firestore wrapper for [DatabaseBatch].
class FirestoreBatch extends DatabaseBatch {
  final WriteBatch _batch;
  final FirebaseFirestore _firestore;

  FirestoreBatch(this._batch, this._firestore);

  DocumentReference _ref(String collection, String id) =>
      _firestore.collection(collection).doc(id);

  @override
  void set(String collection, String id, Map<String, dynamic> data) =>
      _batch.set(_ref(collection, id), data);

  @override
  void update(String collection, String id, Map<String, dynamic> data) =>
      _batch.update(_ref(collection, id), data);

  @override
  void delete(String collection, String id) =>
      _batch.delete(_ref(collection, id));

  @override
  Future<void> commit() => _batch.commit();
}

/// Firestore wrapper for [DatabaseTransaction].
class FirestoreTransaction extends DatabaseTransaction {
  final Transaction _txn;
  final FirebaseFirestore _firestore;

  FirestoreTransaction(this._txn, this._firestore);

  DocumentReference _ref(String collection, String id) =>
      _firestore.collection(collection).doc(id);

  @override
  Future<DatabaseDocSnapshot?> get(String collection, String id) async {
    final snap = await _txn.get(_ref(collection, id));
    return FirestoreDocSnapshot(snap);
  }

  @override
  void set(String collection, String id, Map<String, dynamic> data) =>
      _txn.set(_ref(collection, id), data);

  @override
  void update(String collection, String id, Map<String, dynamic> data) =>
      _txn.update(_ref(collection, id), data);

  @override
  void delete(String collection, String id) =>
      _txn.delete(_ref(collection, id));
}
