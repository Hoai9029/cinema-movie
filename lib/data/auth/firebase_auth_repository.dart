import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../core/constants/app_avatars.dart';

class FirebaseAuthRepository {
  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> registerWithEmailAndPassword(
    String email,
    String password, {
    required String name,
    required String phone,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return;

    await user.updateDisplayName(name);

    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'avatarId': AppAvatars.defaultId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return snapshot.data();
  }

  Future<void> updateProfile(
    String uid, {
    required String name,
    required int avatarId,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'avatarId': avatarId,
    });
    await _firebaseAuth.currentUser?.updateDisplayName(name);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Stream<firebase_auth.User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }
}
