import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'main.dart';
import 'collections_repository.dart';

class CollectionsProvider extends ChangeNotifier {
  final FirestoreRepository _repository = FirestoreRepository();

  List<Collection> _collections = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _subscription;

  List<Collection> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Ініціалізація
  void init() {
    _isLoading = true;
    notifyListeners();

    try {
      _subscription = _repository.getCollections().listen((data) {
        _collections = data;
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCollection(String name) async {
    try {
      await _repository.addCollection(name);
    } catch (e) {
      _errorMessage = "Помилка додавання: $e";
      notifyListeners();
    }
  }

  // НОВЕ: Метод видалення колекції
  Future<void> deleteCollection(String id) async {
    try {
      await _repository.deleteCollection(id);
    } catch (e) {
      _errorMessage = "Помилка видалення колекції: $e";
      notifyListeners();
    }
  }

  // Метод видалення предмету
  Future<void> deleteItem(String collectionId, String itemId) async {
    try {
      await _repository.deleteItem(collectionId, itemId);
    } catch (e) {
      _errorMessage = "Помилка видалення предмету: $e";
      notifyListeners();
    }
  }

  Future<void> addItemWithPhoto(String collectionId, CollectorItem item, File? photoFile) async {
    try {
      String imageUrl = item.imageUrl;

      if (photoFile != null) {
        final storageRef = FirebaseStorage.instance.ref();
        final path = 'user_uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final fileRef = storageRef.child(path);

        await fileRef.putFile(photoFile);
        imageUrl = await fileRef.getDownloadURL();
      }

      final newItem = CollectorItem(
        id: '',
        name: item.name,
        description: item.description,
        imageUrl: imageUrl,
        price: item.price,
        purchaseDate: item.purchaseDate,
        condition: item.condition,
      );

      await _repository.addItem(collectionId, newItem);

    } catch (e) {
      _errorMessage = "Помилка збереження: $e";
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}