import 'dart:convert';

void main() {
  String jsonStr = '{"id":7,"user_id":1,"address":"gang haji daus","total_price":"220000.00","status":"pending","created_at":"2026-06-10T17:56:10.000000Z","updated_at":"2026-06-10T17:56:10.000000Z","items":[{"id":10,"order_id":7,"product_id":2,"quantity":1,"price":"220000.00","created_at":"2026-06-10T17:56:10.000000Z","updated_at":"2026-06-10T17:56:10.000000Z","product":{"id":2,"name":"Rose Petal Serum","category":"Skincare","price":"220000.00","buyers":892,"rating":4.9,"description":"Serum wajah mewah yang mengandung ekstrak kelopak bunga mawar asli dan Niacinamide. Diformulasikan khusus untuk meratakan warna kulit, menyamarkan noda hitam, dan memberikan efek calming pada kulit yang kemerahan. Teksturnya yang ringan dan mudah meresap menutrisi kulit hingga ke lapisan terdalam, menghasilkan kulit yang lebih kenyal, halus, dan bercahaya sehat alami.","image_url":"https:\/\/images.unsplash.com\/photo-1620916566398-39f1143ab7be?w=400&q=80","created_at":"2026-06-08T03:55:53.000000Z","updated_at":"2026-06-08T03:55:53.000000Z"}}]}';
  
  var data = json.decode(jsonStr);
  
  var itemsList = data['items'] as List? ?? [];
  for (var i in itemsList) {
    final product = i['product'];
    String imgUrl = '';
    String pName = 'Unknown Product';
    
    if (product is Map) {
      imgUrl = product['image_url']?.toString() ?? '';
      pName = product['name']?.toString() ?? 'Unknown Product';
    } else {
      imgUrl = i['product_image_url']?.toString() ?? '';
      pName = i['product_name']?.toString() ?? 'Unknown Product';
    }
    
    print('Product: $pName');
    print('URL: $imgUrl');
  }
}
