import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';
import '../data/firebase_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  StudentModel? _currentStudent;
  bool _isLoading = true;
  String? _loadError;

  User? get currentUser => _currentUser;
  StudentModel? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    _loadError = null;
    if (user != null) {
      try {
        _currentStudent = await FirebaseService.getStudent(user.uid);
      } catch (e) {
        _currentStudent = null;
        _loadError = 'Unable to load your profile. Check your connection and try again.';
      }
    } else {
      _currentStudent = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> retryLoadStudent() async {
    final user = _currentUser;
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    await _onAuthStateChanged(user);
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print('Sign up error: $e');
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateStudentProfile(StudentModel student) async {
    await FirebaseService.saveStudent(student);
    _currentStudent = student;
    notifyListeners();
  }
}