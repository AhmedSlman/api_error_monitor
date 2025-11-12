# دليل نشر الحزمة (Publishing Guide)

## الخطوات المطلوبة للنشر

### 1. إنشاء Repository على GitHub

1. اذهب إلى [GitHub](https://github.com)
2. اضغط على "New repository"
3. اختر اسم للـ repository (مثلاً: `api_logger`)
4. اختر Public أو Private
5. لا تختار "Initialize with README" (لأنك بالفعل لديك README)
6. اضغط "Create repository"

### 2. تحديث pubspec.yaml

قبل النشر، يجب تحديث `pubspec.yaml` بتغيير:
- `homepage: https://github.com/yourusername/api_logger`
- `repository: https://github.com/yourusername/api_logger`
- `issue_tracker: https://github.com/yourusername/api_logger/issues`

استبدل `yourusername` باسم GitHub الخاص بك.

### 3. رفع الكود إلى GitHub

```bash
# إضافة remote repository
git remote add origin https://github.com/YOUR_USERNAME/api_logger.git

# رفع الكود
git branch -M main
git push -u origin main
```

### 4. النشر على pub.dev

#### أ. التحقق من الحساب

1. اذهب إلى [pub.dev](https://pub.dev)
2. سجل دخول بحساب Google
3. اربط حساب GitHub الخاص بك

#### ب. التحقق من الحزمة

```bash
# التحقق من الحزمة قبل النشر
flutter pub publish --dry-run
```

#### ج. نشر الحزمة

```bash
# نشر الحزمة
flutter pub publish
```

ستحتاج إلى:
- تأكيد النشر
- إدخال OAuth token (إذا طُلب)

### 5. بعد النشر

1. اذهب إلى صفحة الحزمة على pub.dev
2. تأكد من أن كل شيء يعمل بشكل صحيح
3. أضف badges إلى README.md

### 6. تحديثات مستقبلية

عند إصدار نسخة جديدة:

1. تحديث `version` في `pubspec.yaml`
2. تحديث `CHANGELOG.md`
3. Commit التغييرات
4. Push إلى GitHub
5. نشر على pub.dev

```bash
# مثال لتحديث النسخة
# 1. تحديث pubspec.yaml: version: 0.0.2
# 2. تحديث CHANGELOG.md
# 3. Commit
git add .
git commit -m "Release v0.0.2"
git push

# 4. نشر
flutter pub publish
```

## ملاحظات مهمة

1. **لا يمكن حذف الحزمة**: بمجرد النشر على pub.dev، لا يمكن حذفها
2. **النسخ المحجوزة**: لا يمكن إعادة نشر نفس النسخة
3. **GitHub Repository**: يجب أن يكون repository موجوداً على GitHub قبل النشر
4. **LICENSE**: يجب أن يكون LICENSE موجوداً
5. **README.md**: يجب أن يكون README.md موجوداً وواضحاً

## المشاكل الشائعة

### مشكلة: "Package has 0 warnings" لكن النشر فشل

**الحل**: تأكد من:
- أن repository موجود على GitHub
- أن pubspec.yaml يحتوي على repository URL صحيح
- أن LICENSE موجود

### مشكلة: "Authentication failed"

**الحل**: 
1. تأكد من تسجيل الدخول بحساب Google على pub.dev
2. تأكد من ربط حساب GitHub
3. جرب استخدام OAuth token

### مشكلة: "Version already exists"

**الحل**: 
- قم بتحديث version في pubspec.yaml
- لا يمكن إعادة نشر نفس النسخة

## روابط مفيدة

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Flutter Package Publishing](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#publish)
- [GitHub Guide](https://docs.github.com/en/get-started/quickstart/create-a-repo)

