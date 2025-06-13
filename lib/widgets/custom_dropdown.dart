import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String hint;
  final List<String> items;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomDropdown({super.key, required this.hint, required this.items, this.backgroundColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint, style: TextStyle(color: textColor ?? Colors.black54)),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: textColor ?? Colors.black54),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.black)), // Set text color explicitly for items
            );
          }).toList(),
          onChanged: (_) {},
           dropdownColor: backgroundColor ?? Colors.white,
        ),
      ),
    );
  }
}