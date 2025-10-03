enum BuildEnv { dev, stg, prod }

class Env {
  Env._(); // Private constructor

  static const String devUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://dev.api.example.com');
  static const String stgUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://stg.api.example.com');
  static const String prodUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://api.example.com');

  static late String baseUrl;
  static late BuildEnv buildEnv;

  static void init({required String baseUrl, required BuildEnv buildEnv}) {
    Env.baseUrl = baseUrl;
    Env.buildEnv = buildEnv;
  }
}
