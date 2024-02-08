import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/presentation/screens/root/root_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bacakomik_app/core/auth/auth_methods.dart';
import 'package:bacakomik_app/core/constants/colors.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final AuthMethod _authMethod = AuthMethod();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.5),
              Theme.of(context).colorScheme.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LOGIN',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.sairaStencilOne().fontFamily,
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton.icon(
                icon: Assets.icons.google.svg(
                  width: 24,
                  height: 24,
                ),
                onPressed: () async {
                  bool res = await _authMethod.signInWithGoogle(context);
                  if (res) {
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const RootScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0.3,
                ),
                label: const Text(
                  'Google Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
