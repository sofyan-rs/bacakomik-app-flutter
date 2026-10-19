import 'dart:async';

import 'package:bacakomik_app/app/root_screen.dart';
import 'package:bacakomik_app/core/assets/assets.gen.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_theme.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Always dark, so it continues the black native launch screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 3000);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.duration, _openRoot);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openRoot() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: DotMotion.slide,
        pageBuilder: (_, _, _) => const RootScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DotlineThemes.dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Builder(
          builder: (context) {
            final c = Dotline.of(context);
            return Scaffold(
              backgroundColor: c.bg,
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(DotRadius.l),
                              child: Image.asset(
                                Assets.images.splashArt.path,
                                width: 168,
                                height: 168,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: DotSpace.s6),
                            Text(
                              AppVariables.appName.toUpperCase(),
                              style: DotlineText.dotBrand.copyWith(
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: DotSpace.s3),
                            Text(
                              'MANGA · MANHWA · MANHUA',
                              style: DotlineText.label.copyWith(
                                color: c.inkFaint,
                              ),
                            ),
                            const SizedBox(height: DotSpace.s6),
                            const DotLoader(),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: DotSpace.s6),
                      child: Column(
                        children: [
                          Text(
                            'FROM',
                            style: DotlineText.label.copyWith(
                              color: c.inkFaint,
                            ),
                          ),
                          const SizedBox(height: DotSpace.s1),
                          Text(
                            'Kurodev',
                            style: DotlineText.headline.copyWith(color: c.ink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
