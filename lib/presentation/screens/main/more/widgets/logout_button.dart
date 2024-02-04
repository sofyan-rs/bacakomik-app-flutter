import 'package:bacakomik_app/core/auth/auth_methods.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:flutter/material.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    void logout() {
      showModalBottomSheet(
        useSafeArea: true,
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return SizedBox(
            height: 185,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Text(
                    AppText.logout,
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Text(
                        AppText.logoutConfirmation,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              AppText.cancel,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              AuthMethod().signOut(context);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              AppText.logout,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(15),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        onPressed: logout,
        child: const SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppText.logout,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
