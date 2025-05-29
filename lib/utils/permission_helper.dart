import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    try {
      final status = await Permission.microphone.status;
      print('Current microphone permission status: $status');

      if (status.isGranted) {
        print('Permission already granted');
        return true;
      }

      if (status.isPermanentlyDenied) {
        print('Permission permanently denied, showing settings dialog');
        // Show dialog to go to settings
        await _showSettingsDialog(context);
        // After showing settings dialog, check status again
        final newStatus = await Permission.microphone.status;
        print('Status after settings dialog: $newStatus');
        return newStatus.isGranted;
      }

      if (status.isDenied) {
        print('Permission denied, showing explanation dialog');
        // Show explanation dialog before requesting permission
        final shouldRequest = await _showPermissionExplanationDialog(context);
        if (!shouldRequest) {
          print('User declined to grant permission');
          return false;
        }

        print('Requesting microphone permission');
        final result = await Permission.microphone.request();
        print('Permission request result: $result');

        // If the result is permanently denied after request, show settings dialog
        if (result.isPermanentlyDenied) {
          print(
            'Permission became permanently denied, showing settings dialog',
          );
          await _showSettingsDialog(context);
          // Check again after settings
          final finalStatus = await Permission.microphone.status;
          print('Final status after settings: $finalStatus');
          return finalStatus.isGranted;
        }

        return result.isGranted;
      }

      // For restricted or limited status
      if (status.isRestricted || status.isLimited) {
        print('Permission restricted or limited');
        await _showSettingsDialog(context);
        final newStatus = await Permission.microphone.status;
        return newStatus.isGranted;
      }

      print('Unknown permission status: $status');
      return false;
    } catch (e) {
      print('Error requesting microphone permission: $e');
      return false;
    }
  }

  static Future<bool> _showPermissionExplanationDialog(
    BuildContext context,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A3E),
              title: const Text(
                'マイクロフォンの許可が必要です',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                '睡眠中の音声を録音して分析するために、マイクロフォンへのアクセス許可が必要です。この機能により、いびきや寝言などの睡眠の質に関する重要な情報を提供できます。',
                style: TextStyle(color: Colors.grey),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                  ),
                  child: const Text(
                    '許可する',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3E),
          title: const Text(
            'マイクロフォンの許可が必要です',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'マイクロフォンの許可が永続的に拒否されています。',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                '以下の手順で許可してください：',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. 「設定を開く」をタップ\n2. 「プライバシーとセキュリティ」を選択\n3. 「マイクロフォン」を選択\n4. このアプリをオンにする\n5. アプリに戻って再度お試しください',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('後で', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
              ),
              child: const Text('設定を開く', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
