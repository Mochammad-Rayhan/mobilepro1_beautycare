import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('http://127.0.0.1/beautycare-api/public/api/history/1'); 
  try {
    final response = await http.get(url);
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
