import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ═══════════════════════════════════════════════════════════
//  AUTH SERVICE — Firebase Auth + Firestore RBAC
// ═══════════════════════════════════════════════════════════
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Current user shortcut ──
  static User? get currentUser => _auth.currentUser;

  // ─────────────────────────────────────────────────────
  //  REGISTER — create FirebaseAuth account + Firestore doc
  // ─────────────────────────────────────────────────────
  static Future<User?> register({
    required String email,
    required String password,
    required String namaLengkap,
    String nomorHp = '',
  }) async {
    try {
      developer.log('REGISTER MULAI', name: 'AuthService');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      developer.log('AUTH BERHASIL', name: 'AuthService');

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(namaLengkap.trim());

        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email.trim(),
          'namaLengkap': namaLengkap.trim(),
          'nomorHp': nomorHp.trim(),
          'role': 'user',
          'isSuspended': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      developer.log('REGISTER GAGAL: $e', name: 'AuthService');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────
  //  LOGIN — sign in + fetch role from Firestore
  // ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Login gagal, user tidak ditemukan.',
      );
    }

    // Fetch user profile from Firestore
    final doc = await _db.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      // Edge-case: auth exists but no Firestore doc — create one
      await _db.collection('users').doc(user.uid).set({
        'email': user.email ?? email.trim(),
        'namaLengkap': user.displayName ?? '',
        'nomorHp': '',
        'role': 'user',
        'isSuspended': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return {'role': 'user', 'isSuspended': false};
    }

    final data = doc.data()!;
    return {
      'role': data['role'] ?? 'user',
      'isSuspended': data['isSuspended'] ?? false,
      'namaLengkap': data['namaLengkap'] ?? '',
      'email': data['email'] ?? '',
    };
  }

  // ─────────────────────────────────────────────────────
  //  LOGOUT
  // ─────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────────────
  //  UPDATE ROLE (Super Admin only)
  // ─────────────────────────────────────────────────────
  static Future<void> updateUserRole({
    required String uid,
    required String newRole,
  }) async {
    await _db.collection('users').doc(uid).update({'role': newRole});
  }

  // ─────────────────────────────────────────────────────
  //  TOGGLE SUSPEND (Super Admin only)
  // ─────────────────────────────────────────────────────
  static Future<void> toggleSuspend({
    required String uid,
    required bool isSuspended,
  }) async {
    await _db.collection('users').doc(uid).update({'isSuspended': isSuspended});
  }

  // ─────────────────────────────────────────────────────
  //  UPDATE PROFILE (for edit_profile_page)
  // ─────────────────────────────────────────────────────
  static Future<void> updateProfile({
    required String uid,
    required String namaLengkap,
    required String nomorHp,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).update({
      'namaLengkap': namaLengkap.trim(),
      'nomorHp': nomorHp.trim(),
      'email': email.trim(),
    });

    // Also update FirebaseAuth displayName
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(namaLengkap.trim());
    }
  }

  // ─────────────────────────────────────────────────────
  //  FETCH CURRENT USER PROFILE
  // ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return {'uid': doc.id, ...doc.data()!};
  }

  // ─────────────────────────────────────────────────────
  //  FETCH ALL USERS (for manage_users_page)
  // ─────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final snapshot = await _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'uid': doc.id, ...data};
    }).toList();
  }

  // ─────────────────────────────────────────────────────
  //  STREAM ALL USERS (real-time for manage_users_page)
  // ─────────────────────────────────────────────────────
  static Stream<List<Map<String, dynamic>>> usersStream() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            return {'uid': doc.id, ...doc.data()};
          }).toList(),
        );
  }
}
