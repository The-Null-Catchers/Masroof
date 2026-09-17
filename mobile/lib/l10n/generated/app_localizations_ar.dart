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
  String get searchTransactions => 'ابحث بالجهة أو الملاحظة أو الفئة أو الوسم';

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
  String get merchant => 'الجهة';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get paymentCash => 'نقدًا';

  @override
  String get paymentCard => 'بطاقة';

  @override
  String get paymentBankTransfer => 'تحويل بنكي';

  @override
  String get paymentWallet => 'محفظة رقمية';

  @override
  String get paymentCheque => 'شيك';

  @override
  String get paymentOther => 'أخرى';

  @override
  String get tags => 'الوسوم';

  @override
  String get addTag => 'إضافة وسم';

  @override
  String get duplicate => 'تكرار';

  @override
  String get duplicated => 'تم تكرار المعاملة';

  @override
  String get undo => 'تراجع';

  @override
  String get transactionDeleted => 'تم حذف المعاملة';

  @override
  String get notes => 'ملاحظات';

  @override
  String get verifyEmailBanner => 'يرجى تأكيد بريدك الإلكتروني.';

  @override
  String get resendLink => 'إعادة إرسال الرابط';

  @override
  String get verificationSent => 'تم إرسال رابط التحقق. تفقد بريدك.';

  @override
  String get onboardingTitle => 'لنخصص مصروف لك';

  @override
  String get skip => 'تخطي';

  @override
  String get back => 'رجوع';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get finishOnboarding => 'ابدأ استخدام مصروف';

  @override
  String get onboardingNameTitle => 'بماذا نناديك؟';

  @override
  String get onboardingLanguageTitle => 'اختر لغتك';

  @override
  String get onboardingCurrencyTitle => 'عملتك الرئيسية';

  @override
  String get onboardingCurrencyBody => 'تُحسب الإجماليات والتقارير بهذه العملة، ويمكن للحسابات استخدام عملات أخرى.';

  @override
  String get onboardingIncomeTitle => 'كم دخلك الشهري تقريبًا؟';

  @override
  String get onboardingIncomeBody => 'اختياري — يساعدنا على اقتراح ميزانيات واقعية.';

  @override
  String get onboardingGoalTitle => 'ما هدفك المالي الرئيسي؟';

  @override
  String get onboardingAlertsTitle => 'ابقَ على المسار';

  @override
  String get goalTrackSpending => 'فهم مصروفاتي';

  @override
  String get goalSaveMoney => 'ادخار المزيد';

  @override
  String get goalEmergencyFund => 'بناء صندوق طوارئ';

  @override
  String get goalPayDebt => 'سداد الديون';

  @override
  String get goalBudgetBetter => 'الالتزام بميزانية';

  @override
  String get goalInvest => 'تنمية استثماراتي';

  @override
  String get goalOther => 'هدف آخر';

  @override
  String get budgetAlerts => 'تنبيهات الميزانية';

  @override
  String get budgetAlertsHint => 'نبّهني عند اقتراب الميزانيات من حدها';

  @override
  String get recurringReminders => 'تذكير الدفعات المتكررة';

  @override
  String get recurringRemindersHint => 'ذكّرني بالدفعات المتكررة القادمة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get defaultAccount => 'الحساب الافتراضي';

  @override
  String get none => 'بدون';

  @override
  String get monthStartDay => 'يبدأ الشهر المالي في اليوم';

  @override
  String get categoryFood => 'الطعام';

  @override
  String get categoryRestaurants => 'المطاعم';

  @override
  String get categoryGroceries => 'البقالة';

  @override
  String get categoryTransportation => 'المواصلات';

  @override
  String get categoryFuel => 'الوقود';

  @override
  String get categoryShopping => 'التسوق';

  @override
  String get categoryEntertainment => 'الترفيه';

  @override
  String get categoryBills => 'الفواتير';

  @override
  String get categoryInternet => 'الإنترنت';

  @override
  String get categoryMobile => 'الجوال';

  @override
  String get categoryRent => 'الإيجار';

  @override
  String get categoryHealthcare => 'الرعاية الصحية';

  @override
  String get categoryEducation => 'التعليم';

  @override
  String get categoryTravel => 'السفر';

  @override
  String get categoryGifts => 'الهدايا';

  @override
  String get categorySubscriptions => 'الاشتراكات';

  @override
  String get categoryFamily => 'العائلة';

  @override
  String get categoryOtherExpense => 'أخرى';

  @override
  String get categorySalary => 'الراتب';

  @override
  String get categoryFreelancing => 'العمل الحر';

  @override
  String get categoryBusiness => 'الأعمال';

  @override
  String get categoryInvestments => 'الاستثمارات';

  @override
  String get categoryGiftsIncome => 'الهدايا';

  @override
  String get categoryRefunds => 'المبالغ المستردة';

  @override
  String get categoryOtherIncome => 'أخرى';

  @override
  String get navPlan => 'التخطيط';

  @override
  String get navAnalytics => 'التحليلات';

  @override
  String get navMore => 'المزيد';

  @override
  String get offlineData => 'تُعرض بيانات محفوظة — اتصل بالإنترنت للتحديث';

  @override
  String get requiresConnection => 'يتطلب هذا الإجراء اتصالًا بالإنترنت.';

  @override
  String get budgets => 'الميزانيات';

  @override
  String get addBudget => 'إنشاء ميزانية';

  @override
  String get editBudget => 'تعديل الميزانية';

  @override
  String get budgetName => 'اسم الميزانية';

  @override
  String get period => 'الفترة';

  @override
  String get periodMonthly => 'شهرية';

  @override
  String get periodWeekly => 'أسبوعية';

  @override
  String get periodCustom => 'فترة مخصصة';

  @override
  String get budgetAmount => 'مبلغ الميزانية';

  @override
  String get startsOn => 'تبدأ في';

  @override
  String get endsOn => 'تنتهي في';

  @override
  String get allCategories => 'جميع فئات المصروفات';

  @override
  String get alertThresholds => 'نبّهني عند (%)';

  @override
  String get alertThresholdsHint => 'نسب مئوية مفصولة بفواصل، مثل 50، 75، 90، 100';

  @override
  String get spent => 'المُنفق';

  @override
  String get remaining => 'المتبقي';

  @override
  String get periodEnded => 'انتهت الفترة';

  @override
  String get statusOnTrack => 'ضمن الخطة';

  @override
  String get statusWarning => 'انتبه';

  @override
  String get statusExceeded => 'تجاوزت الميزانية';

  @override
  String get safeToSpend => 'آمن للإنفاق';

  @override
  String get emptyBudgetsTitle => 'لا توجد ميزانيات بعد';

  @override
  String get emptyBudgetsBody => 'حدّد سقفًا للإنفاق لهذا الشهر أو الأسبوع أو لفترة مخصصة.';

  @override
  String get goals => 'أهداف الادخار';

  @override
  String get addGoal => 'هدف جديد';

  @override
  String get editGoal => 'تعديل الهدف';

  @override
  String get goalName => 'اسم الهدف';

  @override
  String get goalKind => 'النوع';

  @override
  String get goalKindEmergencyFund => 'صندوق طوارئ';

  @override
  String get goalKindLaptop => 'حاسوب محمول';

  @override
  String get goalKindCar => 'سيارة';

  @override
  String get goalKindTravel => 'سفر';

  @override
  String get goalKindWedding => 'زفاف';

  @override
  String get goalKindHome => 'منزل';

  @override
  String get goalKindCustom => 'مخصص';

  @override
  String get targetAmount => 'المبلغ المستهدف';

  @override
  String get targetDate => 'التاريخ المستهدف';

  @override
  String get linkedAccount => 'الحساب المرتبط';

  @override
  String get noPace => 'أضف مساهمات لرؤية التوقع';

  @override
  String get achieved => 'تحقق';

  @override
  String get addMoney => 'إضافة مبلغ';

  @override
  String get withdraw => 'سحب';

  @override
  String get contribution => 'مساهمة';

  @override
  String get withdrawal => 'سحب';

  @override
  String get history => 'السجل';

  @override
  String get noEntries => 'لا توجد مساهمات بعد.';

  @override
  String get emptyGoalsTitle => 'لا توجد أهداف بعد';

  @override
  String get emptyGoalsBody => 'ادّخر لصندوق طوارئ أو حاسوب أو رحلة.';

  @override
  String get analytics => 'التحليلات';

  @override
  String get thisMonth2 => 'هذا الشهر';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get savings => 'الادخار';

  @override
  String get savingsRate => 'نسبة الادخار';

  @override
  String get avgDailySpending => 'متوسط الإنفاق اليومي';

  @override
  String get incomeVsExpenses => 'الدخل مقابل المصروفات';

  @override
  String get spendingTrend => 'اتجاه الإنفاق';

  @override
  String get balanceTrend => 'اتجاه الرصيد';

  @override
  String get categoryComparison => 'مقارنة الفئات';

  @override
  String get fixedVsVariable => 'الثابتة مقابل المتغيرة';

  @override
  String get fixed => 'ثابتة';

  @override
  String get variable => 'متغيرة';

  @override
  String get largestExpenses => 'أكبر المصروفات';

  @override
  String get topMerchants => 'الجهات الأكثر تكرارًا';

  @override
  String get insights => 'رؤى';

  @override
  String get noInsights => 'لا توجد رؤى بعد — استمر في التسجيل وستظهر هنا.';

  @override
  String get noData => 'لا توجد بيانات لهذه الفترة.';

  @override
  String get remainingBudget => 'الميزانية المتبقية';

  @override
  String get seeAnalytics => 'عرض التحليلات';

  @override
  String overBy(String amount) {
    return 'تجاوز بمقدار $amount';
  }

  @override
  String perDay(String amount) {
    return '$amount / يوم';
  }

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يومًا متبقيًا',
      few: '$days أيام متبقية',
      two: 'يومان متبقيان',
      one: 'يوم واحد متبقٍ',
      zero: 'لا أيام متبقية',
    );
    return '$_temp0';
  }

  @override
  String projectedAtPace(String amount) {
    return 'المتوقع $amount بهذا المعدل';
  }

  @override
  String goalOf(String amount) {
    return 'من $amount';
  }

  @override
  String monthlyNeeded(String amount) {
    return 'تحتاج $amount شهريًا';
  }

  @override
  String expectedBy(String date) {
    return 'متوقع بحلول $date';
  }

  @override
  String monthsAgo(int count) {
    return 'قبل $count أشهر';
  }

  @override
  String timesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرة',
      few: '$count مرات',
      two: 'مرتان',
      one: 'مرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get navActivity => 'المعاملات';

  @override
  String get recurring => 'الدفعات المتكررة';

  @override
  String get addRecurring => 'دفعة متكررة جديدة';

  @override
  String get editRecurring => 'تعديل الدفعة المتكررة';

  @override
  String get recurringName => 'الاسم';

  @override
  String get frequency => 'التكرار';

  @override
  String get freqDaily => 'يومي';

  @override
  String get freqWeekly => 'أسبوعي';

  @override
  String get freqMonthly => 'شهري';

  @override
  String get freqYearly => 'سنوي';

  @override
  String get everyInterval => 'كل (الفاصل)';

  @override
  String get whenDue => 'عند الاستحقاق';

  @override
  String get modeAuto => 'إضافة تلقائية';

  @override
  String get modeRemind => 'ذكّرني فقط';

  @override
  String get remindDaysBefore => 'أيام التذكير المسبق';

  @override
  String get paused => 'متوقفة';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get resume => 'استئناف';

  @override
  String get ended => 'انتهت';

  @override
  String get emptyRecurringTitle => 'لا توجد دفعات متكررة بعد';

  @override
  String get emptyRecurringBody => 'أتمت الرواتب والإيجار والاشتراكات والفواتير.';

  @override
  String get upcomingPayments => 'الدفعات القادمة';

  @override
  String get noNotifications => 'لا جديد لديك.';

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String get notificationPreferences => 'تفضيلات الإشعارات';

  @override
  String get inApp => 'داخل التطبيق';

  @override
  String get emailChannel => 'البريد الإلكتروني';

  @override
  String get notifBudgetThreshold => 'تنبيهات الميزانية';

  @override
  String get notifBillReminder => 'تذكير الفواتير';

  @override
  String get notifRecurringReminder => 'تذكير الدفعات المتكررة';

  @override
  String get notifGoalReminder => 'تذكير أهداف الادخار';

  @override
  String get notifWeeklySummary => 'ملخص الإنفاق الأسبوعي';

  @override
  String get notifMonthlySummary => 'الملخص المالي الشهري';

  @override
  String get reports => 'التقارير والتصدير';

  @override
  String get reportType => 'التقرير';

  @override
  String get reportFormat => 'الصيغة';

  @override
  String get generateReport => 'إنشاء ومشاركة';

  @override
  String get reportMonthly => 'التقرير المالي الشهري';

  @override
  String get reportTransactions => 'المعاملات';

  @override
  String get reportBudgets => 'تقرير الميزانيات';

  @override
  String get reportIncomeExpense => 'ملخص الدخل والمصروفات';

  @override
  String get reportCategories => 'الإنفاق حسب الفئة';

  @override
  String get preparingReport => 'جارٍ تحضير التقرير…';

  @override
  String get reportFailed => 'تعذر إنشاء التقرير.';

  @override
  String nextOn(String date) {
    return 'القادمة: $date';
  }

  @override
  String get scanReceipt => 'مسح إيصال';

  @override
  String get receiptScanIntro =>
      'التقط صورة للإيصال أو اختر صورة من المعرض. نقرأ اسم المتجر والمجموع والتاريخ، وتؤكدها أنت قبل الحفظ.';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get readingReceipt => 'جارٍ قراءة الإيصال…';

  @override
  String get receiptFailed => 'تعذرت قراءة هذا الإيصال.';

  @override
  String get receiptPartial => 'لم نعثر على بعض التفاصيل. يمكنك إكمالها في الخطوة التالية.';

  @override
  String get receiptNeedsInternet => 'يتطلب مسح الإيصال اتصالًا بالإنترنت. ما زال بإمكانك إضافة المعاملة يدويًا.';

  @override
  String get receiptPickFailed => 'تعذر فتح الكاميرا أو المعرض.';

  @override
  String get notFound => 'غير موجود';

  @override
  String get reviewAndSave => 'مراجعة وحفظ';

  @override
  String get enterManually => 'إدخال يدوي';

  @override
  String get reviewReceipt => 'مراجعة الإيصال';

  @override
  String get receiptVerifyHint => 'راجع التفاصيل المقروءة من الإيصال قبل الحفظ.';
}
