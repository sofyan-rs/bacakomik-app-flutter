import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ErrNoInternet extends StatelessWidget {
  const ErrNoInternet({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            SolarIconsOutline.translation,
            color: AppColors.primary.withOpacity(0.5),
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            AppText.noInternet,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
