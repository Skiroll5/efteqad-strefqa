// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'افتقاد القديسة رفقة';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get register => 'انشاء حساب';

  @override
  String get waitActivation => 'انتظر تفعيل الأدمن';

  @override
  String get classes => 'الفصول';

  @override
  String get students => 'الطلاب';

  @override
  String get attendance => 'الغياب';

  @override
  String get statisticsDashboard => 'الإحصائيات';

  @override
  String get atRiskStudents => 'الطلاب المعرضون للخطر';

  @override
  String get atRiskThreshold => 'حد الخطر';

  @override
  String thresholdCaption(Object count) {
    return 'تنبيه بعد $count غيابات متتالية';
  }

  @override
  String get attendanceTrends => 'مؤشر الحضور (آخر 12 أسبوع)';

  @override
  String absentTimes(Object count) {
    return 'غائب $count مرات';
  }

  @override
  String get noAtRiskStudents => 'عمل رائع! لا يوجد طلاب معرضون للخطر حالياً.';

  @override
  String get yourClasses => 'فصولك';

  @override
  String get yourClass => 'فصلك';

  @override
  String get selectClassToManage => 'اختر فصلاً لإدارة الطلاب والغياب';

  @override
  String get noClassesYet => 'لا توجد فصول بعد';

  @override
  String get noClassAssigned => 'لم يتم تعيين فصل';

  @override
  String get createClass => 'إنشاء فصل';

  @override
  String get addClass => 'إضافة فصل';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get hi => 'مرحباً';

  @override
  String get call => 'اتصال';

  @override
  String get phone => 'الهاتف';

  @override
  String get noPhone => 'لا يوجد هاتف';

  @override
  String get address => 'العنوان';

  @override
  String get birthdate => 'تاريخ الميلاد';

  @override
  String get visitationNotes => 'الملاحظات';

  @override
  String get noNotes => 'لا توجد ملاحظات بعد.';

  @override
  String get addNote => 'إضافة ملاحظة';

  @override
  String get age => 'العمر';

  @override
  String yearsOld(Object count) {
    return '$count سنة';
  }

  @override
  String get nextBirthday => 'عيد الميلاد القادم';

  @override
  String birthdayCountdown(Object months, Object days) {
    return 'خلال $months شهر و $days يوم';
  }

  @override
  String get todayIsBirthday => 'عيد ميلاده النهاردة! 🎉';

  @override
  String get addNoteCaption => 'أضف ملاحظة لهذا الطالب';

  @override
  String get whatHappened => 'اكتب محتوى الملاحظة...';

  @override
  String get studentDetails => 'بيانات الطالب';

  @override
  String get settings => 'الإعدادات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'النظام';

  @override
  String get version => 'الإصدار';

  @override
  String get admin => 'أدمن';

  @override
  String get servant => 'خادم';

  @override
  String get studentNotFound => 'الطالب غير موجود';

  @override
  String get details => 'التفاصيل';

  @override
  String get noAddress => 'لا يوجد عنوان';

  @override
  String get notSet => 'غير محدد';

  @override
  String get editStudent => 'تعديل الطالب';

  @override
  String get name => 'الاسم';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get deleteStudentQuestion => 'حذف الطالب؟';

  @override
  String get deleteStudentWarning =>
      'سيتم حذف هذا الطالب وجميع سجلاته بشكل دائم. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get selectTheme => 'اختر المظهر';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get addNewStudent => 'إضافة طالب جديد';

  @override
  String get addStudentCaption => 'أضف طالب لهذا الفصل';

  @override
  String get studentName => 'اسم الطالب';

  @override
  String get phoneNumberOptional => 'رقم الهاتف (اختياري)';

  @override
  String get addressOptional => 'العنوان (اختياري)';

  @override
  String get pleaseEnterName => 'يرجى إدخال الاسم';

  @override
  String get addStudentAction => 'إضافة الطالب';

  @override
  String get createNewClass => 'إنشاء فصل جديد';

  @override
  String get addClassCaption => 'أضف فصل جديد لإدارة الطلاب';

  @override
  String get className => 'اسم الفصل';

  @override
  String get classNameHint => 'مثال: مدرسة الأحد - الصف الثالث';

  @override
  String get gradeOptional => 'الصف (اختياري)';

  @override
  String get gradeHint => 'مثال: الصف الثالث';

  @override
  String get create => 'إنشاء';

  @override
  String get upcomingBirthdays => 'أعياد الميلاد القادمة';

  @override
  String get today => 'النهاردة!';

  @override
  String daysLeft(Object count) {
    return 'باقي $count يوم';
  }

  @override
  String get markAbsentPast => 'تسجيل غياب للحصص السابقة';

  @override
  String get markAbsentPastCaption =>
      'سيتم تسجيل الطالب \'غائب\' في جميع الحصص السابقة.';

  @override
  String get sessionTime => 'الوقت';

  @override
  String get attendanceHistory => 'سجل الحضور';

  @override
  String get present => 'حاضر';

  @override
  String get absent => 'غائب';

  @override
  String get excused => 'بعذر';

  @override
  String get late => 'متأخر';

  @override
  String get dataManagement => 'إدارة البيانات';

  @override
  String get resetDataCaption =>
      'إذا قمت بإعادة تعيين قاعدة البيانات على الخادم، استخدم هذا لمسح البيانات المحلية.';

  @override
  String get resetSyncData => 'إعادة تعيين البيانات والمزامنة';

  @override
  String get confirmReset => 'تأكيد إعادة التعيين';

  @override
  String get resetWarning =>
      'سيتم حذف جميع سجلات الغياب المحلية وفرض مزامنة كاملة من الخادم. استخدمه فقط إذا تم مسح البيانات على الخادم.';
}
