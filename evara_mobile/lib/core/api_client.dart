import 'package:http/http.dart' as http;
import '../services/token_storage.dart';


class ApiClient {


  static Future<Map<String,String>> authHeaders() async {

    final token =
    await TokenStorage.getAccessToken();


    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

  }



  static Future<http.Response> get(
      String url
      ) async {


    final headers =
    await authHeaders();


    return await http.get(
      Uri.parse(url),
      headers: headers,
    );

  }

}