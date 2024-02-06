import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/constants/colors.dart';

class CustomChoiceChip extends StatelessWidget {
  const CustomChoiceChip({
    Key? key,
    required this.isSelected,
    required this.label,
    required this.onSelected,
  }) : super(key: key);

  final bool isSelected;
  final String label;
  final void Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.onBackground,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
    );
  }
}
