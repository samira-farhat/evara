import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/token_storage.dart';
import 'api_config.dart';


class ApiClient {


  static Future<Map<String, String>> authHeaders() async {

    final token = await TokenStorage.getAccessToken();

    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty)
        "Authorization": "Bearer $token",
    };
  }



  static Future<http.Response> get(
      String url,
      ) async {

    final headers = await authHeaders();

    var response = await http.get(
      Uri.parse(url),
      headers: headers,
    );


    if(response.statusCode == 401){

      final refreshed =
      await refreshAccessToken();


      if(refreshed){

        final newHeaders =
        await authHeaders();


        response = await http.get(
          Uri.parse(url),
          headers: newHeaders,
        );

      }

    }


    return response;
  }



  static Future<http.Response> post(
      String url,
      Map<String, dynamic> body,
      ) async {

    var headers = await authHeaders();

    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );


    if (response.statusCode == 401) {

      final refreshed =
      await refreshAccessToken();


      if (refreshed) {

        final newHeaders =
        await authHeaders();


        response = await http.post(
          Uri.parse(url),
          headers: newHeaders,
          body: jsonEncode(body),
        );

      }

    }


    return response;
  }



  static Future<http.Response> put(
      String url,
      Map<String, dynamic> body,
      ) async {

    var headers = await authHeaders();

    var response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );


    if (response.statusCode == 401) {

      final refreshed =
      await refreshAccessToken();


      if (refreshed) {

        final newHeaders =
        await authHeaders();


        response = await http.put(
          Uri.parse(url),
          headers: newHeaders,
          body: jsonEncode(body),
        );

      }

    }


    return response;
  }



  static Future<http.Response> delete(
      String url,
      ) async {

    var headers = await authHeaders();

    var response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );


    if (response.statusCode == 401) {

      final refreshed =
      await refreshAccessToken();


      if (refreshed) {

        final newHeaders =
        await authHeaders();


        response = await http.delete(
          Uri.parse(url),
          headers: newHeaders,
        );

      }

    }


    return response;
  }



  static Future<bool> refreshAccessToken() async {

    final refreshToken =
    await TokenStorage.getRefreshToken();

    if (refreshToken == null) {
      return false;
    }


    final response = await http.post(
      Uri.parse(ApiConfig.refreshToken),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "refresh": refreshToken,
      }),
    );


    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      await TokenStorage.saveTokens(
        access: data["access"],
        refresh: refreshToken,
      );

      return true;
    }


    return false;
  }

}