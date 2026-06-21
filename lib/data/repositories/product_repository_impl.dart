import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final DatabaseDataSource _ds;

  ProductRepositoryImpl(this._ds);

  @override
  Stream<List<Product>> watchProducts() {
    return _ds.streamQueryMulti(
      FirestorePaths.products,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    ).map((snap) => snap.docs.map((d) => Product.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Future<Product?> getProduct(String id) async {
    final doc = await _ds.getDoc(FirestorePaths.products, id);
    if (!doc.exists) return null;
    return Product.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> createProduct(Product product) async {
    await _ds.setDoc(FirestorePaths.products, product.id, product.toMap());
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _ds.updateDoc(FirestorePaths.products, product.id, product.toMap());
  }

  @override
  Future<void> archiveProduct(String id) async {
    await _ds.updateDoc(FirestorePaths.products, id, {'isDeleted': true});
  }

  @override
  Future<void> restoreProduct(String id) async {
    await _ds.updateDoc(FirestorePaths.products, id, {'isDeleted': false});
  }
}
