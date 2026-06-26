import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/home_models.dart';
import '../../models/user_model.dart';
import '../../models/cart_item.dart';
import '../../models/order_history_model.dart';

class ApiService {
  // IP khusus Emulator Android ke localhost laptop Anda
  static const String _baseUrl =
      'http://192.168.43.63/beautycare-api/public/api';

  Future<HomeResponse> fetchHomeData() async {
    final url = Uri.parse('$_baseUrl/home-data');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        return HomeResponse.fromJson(decodedData);
      } else {
        throw Exception(
          'Gagal memuat data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  // ── [API Login] ──
  Future<User?> loginUser(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Sesuaikan dengan struktur response Laravel Anda
        // Misalnya: { "success": true, "user": { "id": 1, "name": "...", "email": "..." }, "token": "..." }
        if (data['user'] != null) {
          return User(
            id: data['user']['id'],
            name: data['user']['name'],
            email: data['user']['email'],
            password: password, // Jangan simpan plain password di production
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── [API Register] ──
  Future<int> registerUser(User user) async {
    final url = Uri.parse('$_baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': user.name,
          'email': user.email,
          'password': user.password,
          'password_confirmation': user.password, // Umum digunakan di Laravel
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['user'] != null && data['user']['id'] != null) {
          return data['user']['id'];
        }
        return 1; // Sukses tapi API tidak mengembalikan ID
      }
      return -1; // Gagal register
    } catch (e) {
      return -1;
    }
  }

  // ── [API Checkout] ──
  Future<Map<String, dynamic>> checkoutOrder(
    int? userId,
    String address,
    double totalPrice,
    List<CartItem> items,
  ) async {
    final url = Uri.parse('$_baseUrl/checkout');

    try {
      final body = json.encode({
        'user_id': userId,
        'address': address,
        'total_price': totalPrice,
        'items': items
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                'price': double.tryParse(item.product.price) ?? 0.0,
              },
            )
            .toList(),
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'OK'};
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message':
              'Status ${response.statusCode}: ${data['message'] ?? data['error'] ?? response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }

  // ── [API History] ──
  Future<List<OrderHistory>> fetchOrderHistory(int userId) async {
    final url = Uri.parse('$_baseUrl/history/$userId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['data'] != null) {
          final List<dynamic> historyList = data['data'];
          return historyList.map((json) => OrderHistory.fromJson(json)).toList();
        } else if (data is List) {
          return data.map((json) => OrderHistory.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
