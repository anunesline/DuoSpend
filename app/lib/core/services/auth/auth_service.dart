import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../features/home/data/models/user_model.dart';
import '../../../features/home/data/repositories/user_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepository = UserRepository();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      print("1️⃣ Iniciando login Google...");

      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        print("❌ Usuário cancelou o login.");
        return null;
      }

      print("2️⃣ Conta Google selecionada.");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print("3️⃣ Token recebido.");

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      print("4️⃣ Login Firebase realizado.");

      final User? user = userCredential.user;

      if (user != null) {
        print("5️⃣ Criando usuário no Firestore...");

        await _userRepository.createUser(
          UserModel(
            uid: user.uid,
            name: user.displayName ?? "",
            email: user.email ?? "",
            photoUrl: user.photoURL ?? "",
            createdAt: DateTime.now(),
          ),
        );

        print("6️⃣ Usuário salvo no Firestore.");
      }

      return user;
    } catch (e, s) {
      print("🚨 ERRO AUTH SERVICE");
      print(e);
      print(s);

      throw Exception("Erro login Google: $e");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}