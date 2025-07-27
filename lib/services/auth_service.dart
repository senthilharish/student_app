import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';
import '../data/firebase_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  StudentModel? _currentStudent;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  StudentModel? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    if (user != null) {
      _currentStudent = await FirebaseService.getStudent(user.uid);
    } else {
      _currentStudent = null;
    }
    _isLoading = false;
    notifyListeners();
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