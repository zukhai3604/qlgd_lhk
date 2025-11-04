import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  final ImageProvider? logo;

  const LoginHeader({super.key, this.logo});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image(
          image: logo ?? const AssetImage('assets/images/tlu_logo.png'),
          height: 80,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.school, size: 80), // Fallback icon
        ),
        const SizedBox(height: 16),
        Text(
          'THUYLOI UNIVERSITY - WWW.TLU.EDU.VN',
          style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Text(
          "Đăng nhập",
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
