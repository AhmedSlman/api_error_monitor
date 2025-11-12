# Product Store - MVVM Demo

مشروع Flutter مثال يوضح استخدام حزمة `api_error_monitor` مع MVVM Architecture.

## المميزات

- ✅ **MVVM Architecture**: Model-View-ViewModel pattern
- ✅ **Repository Pattern**: فصل منطق API عن UI
- ✅ **API Integration**: استخدام FakeStore API للمنتجات
- ✅ **Error Monitoring**: مراقبة أخطاء API تلقائياً
- ✅ **Discord Integration**: إرسال التقارير إلى Discord (اختياري)

## البنية

```
lib/
├── main.dart                    # Entry point
├── models/
│   └── product_model.dart      # Product Model
├── repositories/
│   └── product_repository.dart # API Repository
├── viewmodels/
│   └── product_viewmodel.dart  # ViewModel (Business Logic)
└── views/
    └── product_detail_view.dart # Product Detail Screen
```

## التثبيت

```bash
flutter pub get
```

## إعداد Discord Webhook (اختياري)

### الخطوة 1: إنشاء Webhook في Discord

1. افتح Discord → السيرفر الخاص بك
2. Server Settings → Integrations → Webhooks
3. اضغط "New Webhook"
4. اختر القناة
5. انسخ Webhook URL

### الخطوة 2: إضافة Webhook URL في المشروع

**الطريقة 1: Environment Variable (الأفضل)**
```bash
export DISCORD_WEBHOOK="https://discord.com/api/webhooks/xxxx/yyyy"
flutter run
```

**الطريقة 2: تعديل الكود مباشرة**

افتح `lib/main.dart` وعدّل السطر 13:
```dart
defaultValue: 'https://discord.com/api/webhooks/xxxx/yyyy', // ضع رابطك هنا
```

## التشغيل

```bash
flutter run
```

## الاستخدام

- **قائمة المنتجات**: تعرض تلقائياً عند فتح التطبيق
- **تفاصيل المنتج**: اضغط على أي منتج لرؤية التفاصيل
- **مراقبة الأخطاء**: تحدث تلقائياً عند حدوث type mismatch أو missing key errors

## ملاحظات

- الـ Discord webhook URL **متغير** - كل مشروع يدخل رابط الـ webhook الخاص به
- الحزمة `api_error_monitor` من pub.dev - مش hardcoded في المشروع
- الأخطاء تُسجل محلياً حتى لو لم يتم إعداد Discord webhook
