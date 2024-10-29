// import 'package:app_clientes/home_page.dart';
import 'package:istp_app/login_page.dart';
import 'package:istp_app/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user is logged in
          if (snapshot.hasData) {
            // return const HomePage();
            return const HomePage();
          }

          // user is NOT logged in
          else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
