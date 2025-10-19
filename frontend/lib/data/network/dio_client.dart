// core/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// ...

ApiClient._internal() {
_installAuth();

// THÊM LOG INTERCEPTOR
dio.interceptors.add(LogInterceptor(
request: true,
requestHeader: true,
requestBody: true,
responseHeader: false,
responseBody: true,
error: true,
logPrint: (obj) {
if (kDebugMode) print('🛰️ $obj');
},
));
}
