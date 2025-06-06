import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('プロフィール'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'プロフィール情報',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
