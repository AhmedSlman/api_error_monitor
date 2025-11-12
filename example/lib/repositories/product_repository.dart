import 'package:dio/dio.dart';
import '../models/product_model.dart';

/// Repository for fetching products from API
class ProductRepository {
  final Dio dio;
  final String baseUrl = 'https://fakestoreapi.com';

  ProductRepository({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://fakestoreapi.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  /// Fetch a single product by ID
  Future<ProductModel> getProduct(int id) async {
    try {
      final response = await dio.get('/products/$id');
      if (response.statusCode == 200 && response.data is Map) {
        return ProductModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid response: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await dio.get('/products');
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data as List;
        return data
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Invalid response: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }
}
