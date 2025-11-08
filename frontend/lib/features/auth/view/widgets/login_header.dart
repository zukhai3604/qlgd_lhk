import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class LoginHeader extends StatelessWidget {
  final ImageProvider? logo;

  const LoginHeader({super.key, this.logo});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tiêu đề "TRƯỜNG ĐẠI HỌC THUỶ LỢI"
        Text(
          'TRƯỜNG ĐẠI HỌC THUỶ LỢI',
          style: textTheme.titleMedium?.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Dòng phụ "THUYLOI UNIVERSITY - WWW.TLU.EDU.VN"
        Text(
          'THUYLOI UNIVERSITY - WWW.TLU.EDU.VN',
          style: textTheme.bodySmall?.copyWith(
            color: primaryColor,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Logo hình thoi (giữ nguyên hình dạng)
        logo != null
            ? Image(
                image: logo!,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Logo load error: $error');
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              )
            : Image.asset(
                'assets/images/tlu_logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Logo asset load error: $error');
                  debugPrint('Trying to load: assets/images/tlu_logo.png');
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 24),
        // Tiêu đề "Đăng nhập"
        Text(
          'Đăng nhập',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
