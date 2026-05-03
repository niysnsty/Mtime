import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      return getCurrentUser();
    }
    return null;
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      final newUser = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
      );
      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
      return newUser;
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

class MockAuthRepositoryImpl implements AuthRepository {
  UserModel? _mockUser;

  @override
  Stream<UserModel?> get user => Stream.value(_mockUser);

  @override
  Future<UserModel?> getCurrentUser() async => _mockUser;

  @override
  Future<UserModel?> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockUser = UserModel(id: '1', name: 'User Demo', email: email);
    return _mockUser;
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockUser = UserModel(id: '1', name: name, email: email);
    return _mockUser;
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
  }
}
