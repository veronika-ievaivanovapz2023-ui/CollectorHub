import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Імпорт моделей даних

class FirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Отримуємо шлях до колекцій поточного користувача
  CollectionReference _userCollections() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');
    return _db.collection('users').doc(uid).collection('my_collections');
  }

  // --- Методи репозиторію ---

  Stream<List<Collection>> getCollections() {
    return _userCollections().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Collection.fromFirestore(doc)).toList();
    });
  }

  Future<void> addCollection(String name) async {
    await _userCollections().add({
      'name': name,
      'iconCode': 58336,
    });
  }

  // Видалення колекції
  Future<void> deleteCollection(String id) async {
    await _userCollections().doc(id).delete();
  }

  Stream<List<CollectorItem>> getItems(String collectionId) {
    return _userCollections()
        .doc(collectionId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CollectorItem.fromFirestore(doc)).toList());
  }

  Future<void> addItem(String collectionId, CollectorItem item) async {
    await _userCollections()
        .doc(collectionId)
        .collection('items')
        .add(item.toMap());
  }

  // Видалення предмету
  Future<void> deleteItem(String collectionId, String itemId) async {
    await _userCollections()
        .doc(collectionId)
        .collection('items')
        .doc(itemId)
        .delete();
  }
}