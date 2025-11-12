# خطوات رفع المشروع - Quick Steps

## ✅ تم إنجازه:
- ✅ تم إنشاء Git repository
- ✅ تم إضافة جميع الملفات
- ✅ تم إنشاء commit أولي
- ✅ تم التحقق من الحزمة (`flutter pub publish --dry-run`)
- ✅ الحزمة جاهزة للنشر (0 warnings)

## 📋 الخطوات التالية:

### 1. تحديث pubspec.yaml

افتح `pubspec.yaml` وغير:
```yaml
homepage: https://github.com/YOUR_USERNAME/api_logger
repository: https://github.com/YOUR_USERNAME/api_logger
issue_tracker: https://github.com/YOUR_USERNAME/api_logger/issues
```

استبدل `YOUR_USERNAME` باسم GitHub الخاص بك.

### 2. إنشاء Repository على GitHub

1. اذهب إلى https://github.com/new
2. اختر اسم: `api_logger`
3. اختر Public
4. **لا** تختار "Initialize with README"
5. اضغط "Create repository"

### 3. رفع الكود إلى GitHub

```bash
cd /Users/macbookaairm2/Documents/api_logger

# إضافة remote (استبدل YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/api_logger.git

# رفع الكود
git branch -M main
git push -u origin main
```

### 4. تحديث pubspec.yaml مرة أخرى

بعد إنشاء repository على GitHub، تأكد من تحديث `pubspec.yaml` بـ:
- `homepage`: رابط GitHub repository
- `repository`: رابط GitHub repository
- `issue_tracker`: رابط GitHub issues

ثم:
```bash
git add pubspec.yaml
git commit -m "Update repository URLs"
git push
```

### 5. النشر على pub.dev

#### أ. التحقق من الحساب على pub.dev

1. اذهب إلى https://pub.dev
2. سجل دخول بحساب Google
3. اربط حساب GitHub

#### ب. النشر

```bash
# التحقق مرة أخرى
flutter pub publish --dry-run

# النشر (إذا كل شيء تمام)
flutter pub publish
```

### 6. بعد النشر

1. اذهب إلى صفحة الحزمة على pub.dev
2. تأكد من أن كل شيء يعمل
3. شارك الرابط مع الآخرين! 🎉

## 🚀 أمر سريع للرفع:

```bash
# 1. تحديث pubspec.yaml (غير YOUR_USERNAME)
# 2. إنشاء repository على GitHub
# 3. ثم:

cd /Users/macbookaairm2/Documents/api_logger
git remote add origin https://github.com/YOUR_USERNAME/api_logger.git
git branch -M main
git push -u origin main

# 4. بعد رفع الكود، حدث pubspec.yaml ثم:
git add pubspec.yaml
git commit -m "Update repository URLs"
git push

# 5. نشر على pub.dev
flutter pub publish
```

## ⚠️ ملاحظات مهمة:

1. **لا يمكن حذف الحزمة** بعد النشر على pub.dev
2. **لا يمكن إعادة نشر نفس النسخة**
3. تأكد من أن repository موجود على GitHub قبل النشر
4. تأكد من أن LICENSE و README.md موجودين

## 📞 للمساعدة:

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [GitHub Guide](https://docs.github.com/en/get-started/quickstart/create-a-repo)

