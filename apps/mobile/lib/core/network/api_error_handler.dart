import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api_exception.dart';

class ApiErrorHandler {
  static ApiException? parse(Object error) {
    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }
    return null;
  }

  static void show(BuildContext context, Object error, {VoidCallback? onRetry}) {
    final api = parse(error);
    final message = api?.message ?? '일시적인 오류가 발생했어요.';

    if (api?.code == 'UNAUTHORIZED') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        context.go('/login');
      }
      return;
    }

    if (api?.code == 'VERSION_MISMATCH') {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('내용이 변경되었어요'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                onRetry?.call();
              },
              child: const Text('새로고침'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: onRetry != null ? SnackBarAction(label: '재시도', onPressed: onRetry) : null,
      ),
    );
  }
}
