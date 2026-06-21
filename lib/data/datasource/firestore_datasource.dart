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
  DocumentReference docRef(String collection, String id) =>
      _firestore.collection(collection).doc(id);

  @override
  Future<DocumentSnapshot> getDoc(String collection, String id) =>
      _firestore.collection(collection).doc(id).get();

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

  Query _buildSingleQuery(
    String collection, {
    String? filterField,
    dynamic filterValue,
    bool filterIsEqualTo = true,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  }) {
    Query q = _firestore.collection(collection);

    if (filterField != null && filterValue != null) {
      q = q.where(filterField, isEqualTo: filterValue);
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
  Future<QuerySnapshot> query(
    String collection, {
    String? filterField,
    dynamic filterValue,
    bool filterIsEqualTo = true,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  }) =>
      _buildSingleQuery(
        collection,
        filterField: filterField,
        filterValue: filterValue,
        filterIsEqualTo: filterIsEqualTo,
        orderByField: orderByField,
        orderByDescending: orderByDescending,
        limit: limit,
      ).get();

  @override
  Stream<QuerySnapshot> streamQuery(
    String collection, {
    String? filterField,
    dynamic filterValue,
    bool filterIsEqualTo = true,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  }) =>
      _buildSingleQuery(
        collection,
        filterField: filterField,
        filterValue: filterValue,
        filterIsEqualTo: filterIsEqualTo,
        orderByField: orderByField,
        orderByDescending: orderByDescending,
        limit: limit,
      ).snapshots();

  Query _buildMultiQuery(
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
  Future<QuerySnapshot> queryMulti(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  }) =>
      _buildMultiQuery(
        collection,
        filters: filters,
        orderByField: orderByField,
        orderByDescending: orderByDescending,
        limit: limit,
      ).get();

  @override
  Stream<QuerySnapshot> streamQueryMulti(
    String collection, {
    List<QueryFilter>? filters,
    String? orderByField,
    bool orderByDescending = false,
    int? limit,
  }) =>
      _buildMultiQuery(
        collection,
        filters: filters,
        orderByField: orderByField,
        orderByDescending: orderByDescending,
        limit: limit,
      ).snapshots();

  @override
  WriteBatch batch() => _firestore.batch();

  @override
  Future<T> runTransaction<T>(Future<T> Function(Transaction txn) handler) =>
      _firestore.runTransaction(handler);
}
