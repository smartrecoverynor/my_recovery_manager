import 'package:flutter/material.dart';

class InfoIcon extends StatelessWidget {
  final String title;
  final String message;

  const InfoIcon({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(
        Icons.info_outline,
        size: 20,
        color: colors.primary,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              title,
              style: TextStyle(
                color: colors.onSurface,
              ),
            ),
            content: Text(
              message,
              style: TextStyle(
                color: colors.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}