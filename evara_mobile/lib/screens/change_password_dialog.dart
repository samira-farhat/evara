import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/api_config.dart';
import '../../core/app_colors.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  bool _validatePasswordRequirements(String password) {
    // Requirements: min 6 chars, at least one capital letter, and one number
    if (password.length < 6) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  Future<void> _submit() async {
    setState(() {
      _oldPasswordError = _oldPasswordController.text.isEmpty ? 'Field cannot be empty' : null;

      if (_newPasswordController.text.isEmpty) {
        _newPasswordError = 'Field cannot be empty';
      } else if (!_validatePasswordRequirements(_newPasswordController.text)) {
        _newPasswordError = 'Must be 6+ chars, include a capital letter & a number';
      } else {
        _newPasswordError = null;
      }

      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = 'Field cannot be empty';
      } else if (_confirmPasswordController.text != _newPasswordController.text) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
      }
    });

    if (_oldPasswordError != null || _newPasswordError != null || _confirmPasswordError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.post(
        ApiConfig.changePassword,
        {
          'old_password': _oldPasswordController.text,
          'new_password': _newPasswordController.text,
        },
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close edit profile sheet

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password changed successfully!',
              style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.white,
          ),
        );
      } else {
        setState(() {
          _oldPasswordError = 'Incorrect current password';
        });
      }
    } catch (e) {
      setState(() {
        _oldPasswordError = 'Failed to update. Try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Change Password',
        style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: _obscureOld,
              style: const TextStyle(color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                errorText: _oldPasswordError,
                suffixIcon: IconButton(
                  icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              style: const TextStyle(color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                errorText: _newPasswordError,
                errorMaxLines: 2,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                errorText: _confirmPasswordError,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lavender))
              : const Text('Save', style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}