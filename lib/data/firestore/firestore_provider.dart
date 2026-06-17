import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

DocumentReference docRef(String collection, String id) => firestore.collection(collection).doc(id);
