import 'package:flutter/material.dart';

class FtErrorBanner extends StatelessWidget {
  const FtErrorBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      leading: const Icon(Icons.wifi_off_outlined),
      actions: [
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    );
  }
}
