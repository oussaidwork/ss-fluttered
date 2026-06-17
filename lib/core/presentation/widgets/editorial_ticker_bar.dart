import 'package:flutter/material.dart';

class EditorialTickerBar extends StatelessWidget implements PreferredSizeWidget {
  const EditorialTickerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0B1220),
      elevation: 0,
      title: const Text(
        'SS-RAGRAGA Station OS',
        style: TextStyle(fontSize: 14, color: Colors.white70),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Chip(
            label: Text(
              'Fuel: 10.72 MAD/L',
              style: TextStyle(fontSize: 11),
            ),
            backgroundColor: Color(0xFF1A2332),
            labelStyle: TextStyle(color: Color(0xFF84CC16)),
            side: BorderSide(color: Color(0xFF84CC16), width: 0.5),
            padding: EdgeInsets.symmetric(horizontal: 8),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.language, size: 20, color: Colors.white54),
          onPressed: () {},
          tooltip: 'Language',
        ),
        IconButton(
          icon: const Icon(Icons.brightness_6, size: 20, color: Colors.white54),
          onPressed: () {},
          tooltip: 'Theme',
        ),
        IconButton(
          icon: const Icon(Icons.person, size: 20, color: Colors.white54),
          onPressed: () {},
          tooltip: 'Profile',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}
