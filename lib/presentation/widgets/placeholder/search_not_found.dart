import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class SearchNotFound extends StatelessWidget {
  const SearchNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            SolarIconsOutline.magnifier,
            color: AppColors.primary.withOpacity(0.5),
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            AppText.comicNotFound,
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
