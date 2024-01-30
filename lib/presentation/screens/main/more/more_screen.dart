import 'package:bacakomik_app/core/auth/auth_methods.dart';
import 'package:flutter/material.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            AuthMethod().signOut(context);
          },
          child: const Text('Log Out'),
        ),
      ),
    );
  }
}
