# 📦 API Error Monitor - حزمة Flutter/Dart لمراقبة أخطاء API تلقائياً

## 🎯 المشكلة التي نحلها

هل واجهت مشكلة عندما يتغير نوع البيانات من الـ Backend فجأة؟ مثلاً:

- الـ API كان يرسل `price` كـ `double` فجأة أصبح `String`
- أو `title` كان `String` فجأة أصبح `int`
- أو مفاتيح مهمة اختفت من الـ Response

هذه المشاكل تسبب **Type Errors** في التطبيق وتجعل المستخدمين يواجهون أخطاء غير متوقعة! 😱

## ✨ الحل: API Error Monitor

حزمة Flutter/Dart تلقائية تراقب وتكتشف أخطاء تحليل الـ API وتقاريرها تلقائياً على Discord مع تفاصيل كاملة!

---

## 🚀 المميزات الرئيسية

### 1. 🔍 اكتشاف تلقائي للأخطاء

- يراقب جميع طلبات الـ API تلقائياً
- يكتشف أخطاء Type Mismatch (مثل: `String` بدلاً من `int`)
- يكتشف المفاتيح المفقودة من الـ JSON Response
- يحدد المفتاح المسبب للمشكلة بدقة

### 2. 📱 تكامل مع Discord

- يرسل تقارير الأخطاء تلقائياً على Discord Webhook
- تقارير منظمة وواضحة مع تفاصيل كاملة:
  - اسم التطبيق
  - الـ Endpoint المسبب للخطأ
  - المفتاح (Key) المسبب للمشكلة
  - النوع المتوقع (Expected Type)
  - النوع المستلم (Received Type)
  - Timestamp
  - تفاصيل الخطأ

### 3. 💾 تسجيل محلي

- يحفظ جميع التقارير محلياً على الجهاز
- يعمل حتى بدون اتصال بالإنترنت
- يمكن استرجاع التقارير لاحقاً

### 4. 🔄 آلية إعادة المحاولة

- إذا فشل إرسال التقرير للـ Discord، يحفظه في Queue
- يعيد المحاولة تلقائياً عند توفر الاتصال
- يمكن التحكم بعدد المحاولات والوقت بينها

### 5. 🛠️ دعم متعدد

- **Dio**: دعم كامل مع Interceptor مدمج
- **HTTP Package**: دعم مع Wrapper Class
- **Manual Capture**: يمكن التقاط الأخطاء يدوياً

### 6. 🎛️ إعدادات متقدمة

- التحكم في Debug Mode
- تخصيص مجلد التسجيل
- تفعيل/تعطيل الميزات حسب الحاجة

---

## 📦 التثبيت

### 1. إضافة الحزمة

```yaml
# pubspec.yaml
dependencies:
  api_error_monitor: ^0.0.2
```

### 2. تثبيت الحزمة

```bash
flutter pub get
```

---

## 🎓 طريقة الاستخدام

### الطريقة 1: استخدام مع Dio (الأسهل والأكثر شيوعاً)

#### الخطوة 1: إنشاء ApiErrorMonitor

```dart
import 'package:api_error_monitor/api_error_monitor.dart';
import 'package:dio/dio.dart';

// إنشاء ApiErrorMonitor مع Discord Webhook
final errorMonitor = ApiErrorMonitor(
  appName: "MyApp",
  discordWebhookUrl: "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN",
  enableInDebugMode: false, // تعطيل في Debug Mode (افتراضي)
  enableLocalLogging: true,  // تفعيل التسجيل المحلي
);
```

#### الخطوة 2: إضافة Interceptor للـ Dio

```dart
final dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),
);

// إضافة Error Monitoring Interceptor
dio.addApiErrorMonitoring(errorMonitor: errorMonitor);
```

#### الخطوة 3: استخدام Dio بشكل عادي

```dart
// عمل Request عادي - الأخطاء ستُلتقط تلقائياً!
try {
  final response = await dio.get('/products');
  final products = (response.data as List)
      .map((json) => ProductModel.fromJson(json))
      .toList();

  // إذا حدث خطأ في fromJson، سيُلتقط تلقائياً!
} catch (e) {
  // يمكنك التعامل مع الخطأ هنا أيضاً
}
```

**مثال كامل:**

```dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:api_error_monitor/api_error_monitor.dart';

class ProductService {
  late final Dio dio;
  late final ApiErrorMonitor errorMonitor;

  ProductService() {
    // تهيئة Error Monitor
    errorMonitor = ApiErrorMonitor(
      appName: "E-Commerce App",
      discordWebhookUrl: "YOUR_DISCORD_WEBHOOK_URL",
      enableLocalLogging: true,
    );

    // تهيئة Dio
    dio = Dio(BaseOptions(
      baseUrl: 'https://fakestoreapi.com',
    ));

    // إضافة Error Monitoring
    dio.addApiErrorMonitoring(errorMonitor: errorMonitor);
  }

  Future<List<Product>> getProducts() async {
    final response = await dio.get('/products');
    return (response.data as List)
        .map((json) => Product.fromJson(json))
        .toList();
    // أي خطأ في fromJson سيُلتقط تلقائياً!
  }
}
```

---

### الطريقة 2: استخدام مع HTTP Package

```dart
import 'package:api_error_monitor/api_error_monitor.dart';
import 'package:http/http.dart' as http;

// إنشاء Error Monitor
final errorMonitor = ApiErrorMonitor(
  appName: "MyApp",
  discordWebhookUrl: "YOUR_DISCORD_WEBHOOK_URL",
);

// إنشاء ApiErrorHttpClient
final httpClient = ApiErrorHttpClient(
  errorMonitor: errorMonitor,
);

// استخدامه مع fromJsonCallback
final response = await httpClient.get(
  Uri.parse('https://api.example.com/products'),
  fromJsonCallback: (data) {
    // إذا حدث خطأ هنا، سيُلتقط تلقائياً!
    return ProductModel.fromJson(data);
  },
);
```

---

### الطريقة 3: التقاط الأخطاء يدوياً

```dart
try {
  final model = MyModel.fromJson(response.data);
} catch (e, stackTrace) {
  // التقاط الخطأ يدوياً مع تفاصيل كاملة
  errorMonitor.capture(
    e,
    stackTrace: stackTrace,
    endpoint: "/api/products",
    key: "price",              // اختياري: تحديد المفتاح المسبب
    expectedType: "double",    // اختياري: تحديد النوع المتوقع
    receivedType: "String",    // اختياري: تحديد النوع المستلم
    requestData: {"id": 123},  // اختياري: بيانات الطلب
    responseData: response.data, // اختياري: بيانات الاستجابة
  );
}
```

---

## ⚙️ الإعدادات المتقدمة

### إعدادات ApiErrorMonitor

```dart
final errorMonitor = ApiErrorMonitor(
  appName: "MyApp",                    // مطلوب: اسم التطبيق
  discordWebhookUrl: "https://...",     // اختياري: Discord Webhook URL
  enableInDebugMode: false,             // افتراضي: false (معطل في Debug)
  enableLocalLogging: true,             // افتراضي: true
  customLogDirectory: "/path/to/logs",  // اختياري: مجلد مخصص
  maxRetries: 3,                        // افتراضي: 3 محاولات
  retryDelay: Duration(seconds: 5),      // افتراضي: 5 ثواني
  enabled: true,                        // افتراضي: true
);
```

### استخدام Configuration Object

```dart
final config = ApiErrorMonitorConfig(
  appName: "MyApp",
  discordWebhookUrl: "https://discord.com/api/webhooks/xxxx",
  enableInDebugMode: false,
  enableLocalLogging: true,
  maxRetries: 3,
  retryDelay: Duration(seconds: 5),
  enabled: true,
);

final errorMonitor = ApiErrorMonitor.fromConfig(config);
```

---

## 📊 مثال على تقرير Discord

عند حدوث خطأ، سيتم إرسال تقرير منظم على Discord مثل:

```
🔴 Type Mismatch Error

App Name: E-Commerce App
Endpoint: https://fakestoreapi.com/products

🔑 Field Name: price
❌ Current Type: String
✅ Expected Type: double

Error Details:
type 'String' is not a subtype of type 'double' in type cast

Timestamp: 2025-11-12T14:34:02.367671
```

---

## 🔧 استخدامات متقدمة

### 1. استرجاع التقارير المحلية

```dart
// الحصول على جميع التقارير المحفوظة محلياً
final reports = await errorMonitor.getLocalReports();

for (final report in reports) {
  print('Error: ${report.errorMessage}');
  print('Endpoint: ${report.endpoint}');
  print('Key: ${report.key}');
  print('Expected: ${report.expectedType}');
  print('Received: ${report.receivedType}');
}
```

### 2. مسح التقارير المحلية

```dart
// مسح جميع التقارير المحفوظة
await errorMonitor.clearLocalReports();
```

### 3. الحصول على مسار مجلد التسجيل

```dart
final logPath = errorMonitor.getLocalLogDirectoryPath();
print('Logs stored at: $logPath');
```

### 4. إدارة Queue (قائمة الانتظار)

```dart
// معالجة التقارير المعلقة (عند توفر الاتصال)
await errorMonitor.processQueue();

// التحقق من حجم Queue
final queueSize = errorMonitor.queueSize;

// مسح Queue
errorMonitor.clearQueue();
```

---

## 🎯 مثال عملي كامل (MVVM Architecture)

```dart
// 1. Repository Layer
class ProductRepository {
  final Dio dio;
  final String baseUrl = 'https://fakestoreapi.com';

  ProductRepository({required this.dio});

  Future<List<ProductModel>> getAllProducts() async {
    final response = await dio.get('/products');
    final List<dynamic> data = response.data as List;
    return data
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

// 2. ViewModel Layer
class ProductViewModel extends ChangeNotifier {
  final ProductRepository repository;
  final ApiErrorMonitor errorMonitor;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  ProductViewModel({
    required this.repository,
    required this.errorMonitor,
  });

  Future<void> fetchAllProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await repository.getAllProducts();
      _error = null;
    } catch (e, stackTrace) {
      _error = 'Failed to load products';

      // التقاط الخطأ تلقائياً
      errorMonitor.capture(
        e,
        stackTrace: stackTrace,
        endpoint: 'https://fakestoreapi.com/products',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// 3. Main App Setup
void main() {
  // تهيئة Error Monitor
  final errorMonitor = ApiErrorMonitor(
    appName: 'Product Store App',
    discordWebhookUrl: 'YOUR_DISCORD_WEBHOOK_URL',
    enableLocalLogging: true,
  );

  // تهيئة Dio
  final dio = Dio(BaseOptions(
    baseUrl: 'https://fakestoreapi.com',
  ));
  dio.addApiErrorMonitoring(errorMonitor: errorMonitor);

  // تهيئة Repository و ViewModel
  final repository = ProductRepository(dio: dio);
  final viewModel = ProductViewModel(
    repository: repository,
    errorMonitor: errorMonitor,
  );

  runApp(MyApp(viewModel: viewModel));
}
```

---

## 🔗 إعداد Discord Webhook

### الخطوات:

1. افتح Discord Server الخاص بك
2. اذهب إلى **Server Settings** → **Integrations** → **Webhooks**
3. اضغط على **New Webhook**
4. اختر القناة التي تريد إرسال التقارير عليها
5. انسخ الـ Webhook URL
6. استخدمه في `ApiErrorMonitor`

**مثال على Webhook URL:**

```
https://discord.com/api/webhooks/1234567890/abcdefghijklmnopqrstuvwxyz
```

⚠️ **ملاحظة مهمة**: الـ Channel URL (`https://discord.com/channels/...`) **ليس** Webhook URL!

---

## 📱 دعم المنصات

✅ **Android** - يعمل بشكل كامل في Debug و Release Mode
✅ **iOS** - يعمل بشكل كامل في Debug و Release Mode
✅ **Web** - يعمل بشكل كامل
✅ **Desktop** - يعمل بشكل كامل

---

## 🎨 أنواع الأخطاء المكتشفة

الباكدج يكتشف تلقائياً:

1. **Type Mismatch**: `type 'String' is not a subtype of type 'int'`
2. **Missing Key**: `key not found: "keyName"`
3. **Null Value**: `type 'null' is not a subtype of type 'String'`
4. **Cast Error**: `type 'X' is not a subtype of type 'Y' in type cast`
5. **JSON Path Errors**: أخطاء في مسار JSON

---

## 💡 أفضل الممارسات

1. ✅ **استخدم في Production**: عطّل Error Reporting في Debug Mode لتجنب الـ Spam
2. ✅ **راقب Queue Size**: تحقق بانتظام من حجم Queue وقم بمعالجتها
3. ✅ **امسح الـ Logs القديمة**: احذف الـ Logs القديمة بانتظام لتوفير المساحة
4. ✅ **أمان Webhook**: احتفظ بـ Discord Webhook URL آمناً
5. ✅ **معالجة الأخطاء**: تعامل مع الأخطاء في الكود حتى مع وجود Monitoring

---

## 📚 المزيد من الأمثلة

راجع مجلد `/example` في الـ Repository للحصول على مثال كامل مع:

- MVVM Architecture
- Repository Pattern
- State Management
- UI Components

---

## 🔗 الروابط

- 📦 **Pub.dev**: https://pub.dev/packages/api_error_monitor
- 💻 **GitHub**: https://github.com/AhmedSlman/api_error_monitor
- 📝 **Documentation**: متوفر في README.md

---

## 🎉 الخلاصة

**API Error Monitor** هي الحل الأمثل لمراقبة أخطاء API تلقائياً في تطبيقات Flutter/Dart. مع دعم كامل لـ Dio و HTTP Package، وتكامل سلس مع Discord، وآلية إعادة محاولة ذكية - أصبح من السهل جداً تتبع وحل مشاكل Type Mismatch في تطبيقاتك!

جربها الآن وشاركنا تجربتك! 🚀

---

#Flutter #Dart #API #ErrorMonitoring #Discord #MobileDevelopment #Programming #SoftwareDevelopment
