import 'package:flutter_dotenv/flutter_dotenv.dart';

String getBaseUrl() {
  // const defaultUrl = 'http://wk-230:27015';
  const defaultUrl = 'http://172.20.8.120:27015';
  return dotenv.env['API_BASE_URL'] ?? defaultUrl;
}
