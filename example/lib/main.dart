import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:api_error_monitor/api_error_monitor.dart';
import 'models/product_model.dart';
import 'repositories/product_repository.dart';
import 'viewmodels/product_viewmodel.dart';
import 'views/product_detail_view.dart';

// Discord Webhook URL Configuration
// This is a user-provided variable - each project should set its own webhook URL
// Option 1: Set via environment variable before running:
//   export DISCORD_WEBHOOK="https://discord.com/api/webhooks/xxxx/yyyy"
//   flutter run
//
// Option 2: Replace the webhook URL below with your own:
//   Get webhook URL from: Discord Server → Settings → Integrations → Webhooks → New Webhook
//   Note: The channel URL (https://discord.com/channels/...) is NOT a webhook URL
const _discordWebhookUrl = String.fromEnvironment(
  'DISCORD_WEBHOOK',
  defaultValue:
      'https://discord.com/api/webhooks/1438089449929052261/L8-7QNcsB7gCTdSJAjyJ4hAQ4lQwVdyb5s3nFodePQj64gIK6EqJ2MI05HrM9UcerEIO',
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Store - MVVM Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiErrorMonitor errorMonitor;
  late final ProductRepository repository;
  late final ProductViewModel productViewModel;
  late final Dio dio;

  @override
  void initState() {
    super.initState();

    // Initialize ApiErrorMonitor with Discord webhook (if provided)
    // The webhook URL is a user-provided variable, not hardcoded in the package
    errorMonitor = ApiErrorMonitor(
      appName: 'Product Store MVVM Demo',
      discordWebhookUrl: _discordWebhookUrl.isEmpty ? null : _discordWebhookUrl,
      enableInDebugMode: true,
      enableLocalLogging: true,
    );

    // Log webhook status
    if (_discordWebhookUrl.isEmpty) {
      debugPrint(
        '⚠️  Discord webhook not configured - errors will only be logged locally',
      );
    } else {
      debugPrint(
        '✅ Discord webhook configured - errors will be sent to Discord',
      );
    }

    // Initialize Dio with error monitoring
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://fakestoreapi.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    dio.addApiErrorMonitoring(errorMonitor: errorMonitor);

    // Initialize Repository and ViewModel
    repository = ProductRepository(dio: dio);
    productViewModel = ProductViewModel(
      repository: repository,
      errorMonitor: errorMonitor,
    );

    // Load products on startup
    productViewModel.fetchAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Store')),
      body: ListenableBuilder(
        listenable: productViewModel,
        builder: (context, _) {
          if (productViewModel.isLoading && productViewModel.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productViewModel.hasError && productViewModel.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${productViewModel.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      productViewModel.clearError();
                      productViewModel.fetchAllProducts();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: productViewModel.products.length,
            itemBuilder: (context, index) {
              final product = productViewModel.products[index];
              return _ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(
                        productId: product.id,
                        viewModel: productViewModel,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final ProductViewModel viewModel;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.viewModel,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.fetchProduct(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return ProductDetailView(
          viewModel: widget.viewModel,
          productId: widget.productId,
        );
      },
    );
  }
}
