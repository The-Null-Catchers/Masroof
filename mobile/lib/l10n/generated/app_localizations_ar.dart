// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'مصروف';

  @override
  String get appTagline => 'أموالك بوضوح.';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get done => 'تم';

  @override
  String get optional => 'اختياري';

  @override
  String get search => 'بحث';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get invalidAmount => 'أدخل مبلغًا صحيحًا';

  @override
  String get amountMustBePositive => 'يجب أن يكون المبلغ أكبر من صفر';

  @override
  String get genericError => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get networkError => 'أنت غير متصل. تحقق من الاتصال وحاول مجددًا.';

  @override
  String get confirmDeleteTitle => 'حذف نهائي؟';

  @override
  String get confirmDeleteBody => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get loginTitle => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لمتابعة أموالك.';

  @override
  String get registerTitle => 'أنشئ حسابك';

  @override
  String get registerSubtitle => 'ابدأ بإدارة ميزانيتك خلال دقيقة.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get noAccount => 'جديد في مصروف؟';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordBody => 'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.';

  @override
  String get sendResetLink => 'إرسال الرابط';

  @override
  String get resetLinkSent => 'إذا كان البريد مسجلًا، فسيصلك رابط إعادة التعيين قريبًا.';

  @override
  String get backToSignIn => 'العودة لتسجيل الدخول';

  @override
  String get invalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get passwordRules => '٨ أحرف على الأقل تتضمن حروفًا وأرقامًا';

  @override
  String get sessionExpired => 'انتهت الجلسة. يرجى تسجيل الدخول مجددًا.';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get defaultCurrency => 'العملة الرئيسية';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navTransactions => 'المعاملات';

  @override
  String get navAccounts => 'الحسابات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String greeting(String name) {
    return 'أهلًا، $name';
  }

  @override
  String get netWorth => 'إجمالي الرصيد';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get income => 'الدخل';

  @override
  String get expenses => 'المصروفات';

  @override
  String get net => 'الصافي';

  @override
  String get recentTransactions => 'أحدث المعاملات';

  @override
  String get topSpending => 'أعلى المصروفات';

  @override
  String get uncategorized => 'بدون فئة';

  @override
  String get addTransaction => 'إضافة معاملة';

  @override
  String get emptyDashboardTitle => 'لنبدأ بتنظيم أموالك';

  @override
  String get emptyDashboardBody => 'أضف حسابك الأول — نقدي أو بنكي أو بطاقة — لتبدأ التتبع.';

  @override
  String get emptyTransactionsTitle => 'لا توجد معاملات بعد';

  @override
  String get emptyTransactionsBody => 'ستظهر المعاملات التي تضيفها هنا.';

  @override
  String get noResults => 'لا توجد معاملات مطابقة';

  @override
  String get syncOffline => 'غير متصل — ستتم مزامنة التغييرات عند عودة الاتصال';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغييرًا بانتظار المزامنة',
      few: '$count تغييرات بانتظار المزامنة',
      two: 'تغييران بانتظار المزامنة',
      one: 'تغيير واحد بانتظار المزامنة',
      zero: 'لا توجد تغييرات',
    );
    return '$_temp0';
  }

  @override
  String get syncRejected => 'رفض الخادم بعض التغييرات وتمت استعادتها.';

  @override
  String get accounts => 'الحسابات';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get editAccount => 'تعديل الحساب';

  @override
  String get accountName => 'اسم الحساب';

  @override
  String get accountType => 'النوع';

  @override
  String get currency => 'العملة';

  @override
  String get openingBalance => 'الرصيد الافتتاحي';

  @override
  String get color => 'اللون';

  @override
  String get includeInTotal => 'احتسابه ضمن إجمالي الرصيد';

  @override
  String get archive => 'أرشفة';

  @override
  String get unarchive => 'إلغاء الأرشفة';

  @override
  String get archived => 'مؤرشف';

  @override
  String get showArchived => 'عرض المؤرشفة';

  @override
  String get currencyLocked => 'لا يمكن تغيير العملة بعد تسجيل معاملات';

  @override
  String get deleteAccountWarning => 'حذف الحساب سيحذف معاملاته ويعكس التحويلات المرتبطة به.';

  @override
  String get emptyAccountsTitle => 'لا توجد حسابات بعد';

  @override
  String get emptyAccountsBody => 'الحسابات تحفظ أرصدتك: محفظة، حساب بنكي، بطاقة.';

  @override
  String get accountTypeCash => 'نقدي';

  @override
  String get accountTypeBank => 'حساب بنكي';

  @override
  String get accountTypeCreditCard => 'بطاقة ائتمان';

  @override
  String get accountTypeSavings => 'ادخار';

  @override
  String get accountTypeEWallet => 'محفظة إلكترونية';

  @override
  String get accountTypeOther => 'أخرى';

  @override
  String get categories => 'الفئات';

  @override
  String get addCategory => 'إضافة فئة';

  @override
  String get editCategory => 'تعديل الفئة';

  @override
  String get categoryName => 'اسم الفئة';

  @override
  String get parentCategory => 'الفئة الرئيسية';

  @override
  String get noParent => 'بدون (فئة رئيسية)';

  @override
  String get category => 'الفئة';

  @override
  String get icon => 'الأيقونة';

  @override
  String get moveTransactionsTo => 'نقل معاملاتها إلى';

  @override
  String get leaveUncategorized => 'تركها بدون فئة';

  @override
  String get transactions => 'المعاملات';

  @override
  String get newTransaction => 'معاملة جديدة';

  @override
  String get editTransaction => 'تعديل المعاملة';

  @override
  String get typeExpense => 'مصروف';

  @override
  String get typeIncome => 'دخل';

  @override
  String get typeTransfer => 'تحويل';

  @override
  String get amount => 'المبلغ';

  @override
  String get account => 'الحساب';

  @override
  String get fromAccount => 'من حساب';

  @override
  String get toAccount => 'إلى حساب';

  @override
  String amountReceived(String currency) {
    return 'المبلغ المستلم ($currency)';
  }

  @override
  String get date => 'التاريخ';

  @override
  String get payee => 'الجهة';

  @override
  String get note => 'ملاحظة';

  @override
  String get selectAccount => 'اختر حسابًا';

  @override
  String get selectCategory => 'اختر فئة';

  @override
  String get sameAccountError => 'اختر حسابًا مختلفًا';

  @override
  String get needAccountFirst => 'أضف حسابًا قبل تسجيل المعاملات.';

  @override
  String transferTo(String account) {
    return 'تحويل إلى $account';
  }

  @override
  String transferFrom(String account) {
    return 'تحويل من $account';
  }

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get all => 'الكل';

  @override
  String get searchTransactions => 'ابحث بالجهة أو الملاحظة أو الفئة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get security => 'الأمان';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور وتسجيل الخروج من الأجهزة الأخرى.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutPending => 'لديك تغييرات غير متزامنة. تسجيل الخروج الآن سيحذفها.';

  @override
  String get deleteMyAccount => 'حذف حسابي';

  @override
  String get deleteMyAccountBody => 'سيؤدي هذا إلى حذف ملفك وجميع بياناتك المالية نهائيًا. أدخل كلمة المرور للتأكيد.';

  @override
  String get about => 'عن مصروف';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get aboutBody => 'يساعدك مصروف على معرفة أين تذهب أموالك — بالعربية والإنجليزية، متصلًا أو دون اتصال.';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String lastSynced(String time) {
    return 'آخر مزامنة $time';
  }

  @override
  String get saved => 'تم الحفظ';

  @override
  String get categoryFood => 'الطعام والمطاعم';

  @override
  String get categoryGroceries => 'البقالة';

  @override
  String get categoryTransport => 'المواصلات';

  @override
  String get categoryHousing => 'السكن والإيجار';

  @override
  String get categoryBills => 'الفواتير والخدمات';

  @override
  String get categoryShopping => 'التسوق';

  @override
  String get categoryHealth => 'الصحة';

  @override
  String get categoryEducation => 'التعليم';

  @override
  String get categoryEntertainment => 'الترفيه';

  @override
  String get categoryTravel => 'السفر';

  @override
  String get categoryCharity => 'الصدقات والزكاة';

  @override
  String get categoryFamily => 'العائلة';

  @override
  String get categoryOtherExpense => 'أخرى';

  @override
  String get categorySalary => 'الراتب';

  @override
  String get categoryBusiness => 'الأعمال';

  @override
  String get categoryGifts => 'الهدايا';

  @override
  String get categoryInvestments => 'الاستثمارات';

  @override
  String get categoryOtherIncome => 'دخل آخر';
}
