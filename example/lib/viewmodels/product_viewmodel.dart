import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';
import 'package:api_error_monitor/api_error_monitor.dart';

/// ViewModel for managing product state and business logic
class ProductViewModel extends ChangeNotifier {
  final ProductRepository repository;
  final ApiErrorMonitor errorMonitor;

  ProductViewModel({required this.repository, required this.errorMonitor});

  ProductModel? _product;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProductModel? get product => _product;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Fetch a single product by ID
  Future<void> fetchProduct(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _product = await repository.getProduct(id);
      _errorMessage = null;
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _product = null;

      // Report error to ApiErrorMonitor with full stack trace
      await errorMonitor.capture(
        e,
        stackTrace: stackTrace,
        endpoint: '${repository.baseUrl}/products/$id',
        responseData: null,
        key: _extractKeyFromError(e, stackTrace),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all products
  Future<void> fetchAllProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await repository.getAllProducts();
      _errorMessage = null;
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _products = [];

      // Report error to ApiErrorMonitor with full stack trace
      await errorMonitor.capture(
        e,
        stackTrace: stackTrace,
        endpoint: '${repository.baseUrl}/products',
        responseData: null,
        key: _extractKeyFromError(e, stackTrace),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Extract key from error for type mismatch errors
  String? _extractKeyFromError(dynamic error, StackTrace stackTrace) {
    try {
      final errorStr = error.toString();
      final stackStr = stackTrace.toString();
      final fullContext = '$errorStr\n$stackStr';

      // Look for patterns like: data['key'], json['key']
      final typeNames = [
        'int',
        'String',
        'double',
        'bool',
        'num',
        'List',
        'Map',
        'dynamic',
        'null',
        'Null',
      ];
      final keyPattern = RegExp(
        r"(?:data|json|map|response)\s*\[\s*[']([^']+)[']\s*\]",
        caseSensitive: false,
        multiLine: true,
      );

      final matches = keyPattern.allMatches(fullContext);
      for (final match in matches) {
        if (match.groupCount > 0) {
          final potentialKey = match.group(1)?.trim();
          if (potentialKey != null &&
              potentialKey.isNotEmpty &&
              potentialKey.length > 1 &&
              !typeNames.contains(potentialKey) &&
              !potentialKey.contains('type') &&
              !potentialKey.contains('subtype') &&
              !potentialKey.contains('cast')) {
            return potentialKey;
          }
        }
      }
    } catch (_) {
      // Ignore extraction errors
    }
    return null;
  }
}
