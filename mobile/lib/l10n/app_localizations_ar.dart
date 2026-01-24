// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'وديعة';

  @override
  String get churchName => 'كنيسة الشهيدة رفقة وأولادها بالقناطر الخيرية';

  @override
  String get loginVerse =>
      'اِحْفَظِ الْوَدِيعَةَ الصَّالِحَةَ بِالرُّوحِ الْقُدُسِ السَّاكِنِ فِينَا. (2 تي 1: 14).';

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
  String thresholdCaption(Object threshold) {
    return 'تنبيه بعد $threshold غيابات متتالية';
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
  String get waitingForClassAssignment => 'بانتظار تعيين الفصل';

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
  String get user => 'مستخدم';

  @override
  String get search => 'بحث';

  @override
  String get call => 'اتصال';

  @override
  String get phone => 'الهاتف';

  @override
  String get noPhone => 'لا يوجد هاتف';

  @override
  String get phoneNumberCopied => 'تم نسخ رقم الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get birthdate => 'تاريخ الميلاد';

  @override
  String get visitationNotes => 'الملاحظات';

  @override
  String get whatsappDefaultTemplate => 'أهلاً %firstname%،';

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
  String get gradeOptional => 'السنة الدراسية (اختياري)';

  @override
  String get gradeHint => 'مثال: الصف الثالث';

  @override
  String get create => 'إنشاء';

  @override
  String get upcomingBirthdays => 'أعياد الميلاد القادمة';

  @override
  String get today => 'النهاردة!';

  @override
  String get tomorrow => 'بكره';

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
      'استخدم هذا الخيار فقط إذا تم إعادة تعيين قاعدة البيانات. سيتم مسح البيانات المحلية.';

  @override
  String get resetSyncData => 'إعادة تعيين المزامنة والبيانات';

  @override
  String get confirmReset => 'تأكيد إعادة التعيين';

  @override
  String get resetWarning =>
      'سيؤدي هذا لعملية مسح كاملة للبيانات المحلية وإعادة المزامنة.';

  @override
  String get lastSession => 'آخر حصة';

  @override
  String get attendanceSessions => 'جلسات الحضور';

  @override
  String get noAttendanceSessionsYet => 'لا توجد جلسات حضور بعد';

  @override
  String get tapBelowToTakeAttendance => 'اضغط بالأسفل لتسجيل الحضور';

  @override
  String get addStudentsFirst => 'أضف الطلاب أولاً';

  @override
  String get addStudentsFirstToTakeAttendance =>
      'أضف الطلاب أولاً لتسجيل الحضور';

  @override
  String get noUpcomingBirthdays => 'لا توجد أعياد ميلاد قادمة';

  @override
  String get attendanceDetails => 'تفاصيل الغياب';

  @override
  String get attendanceRate => 'نسبة الحضور';

  @override
  String get showMore => 'قراءة المزيد';

  @override
  String get showLess => 'إخفاء';

  @override
  String get deleteWarning => 'هل أنت متأكد من الحذف؟';

  @override
  String get noAttendanceRecords => 'لا توجد سجلات غياب';

  @override
  String get sortBy => 'رتب حسب';

  @override
  String get attendancePercentage => 'نسبة الحضور';

  @override
  String get sortAscending => 'تصاعدي';

  @override
  String get sortDescending => 'تنازلي';

  @override
  String get sortByName => 'الاسم';

  @override
  String get sortByStatus => 'الحالة';

  @override
  String absencesTotal(Object count) {
    return '$count غياب (كلي)';
  }

  @override
  String consecutive(Object count) {
    return '$count متتالية';
  }

  @override
  String get whatsappTemplate => 'قالب واتساب';

  @override
  String get whatsappTemplateDesc => 'تخصيص الرسالة الافتراضية المرسلة للطلاب';

  @override
  String get newArrivals => 'طلاب جدد';

  @override
  String get tapToAddToSession => 'اضغط لإضافتهم لهذه الجلسة';

  @override
  String get notInSession => 'غير مسجل في هذه الجلسة';

  @override
  String get whatsappCustomize => 'تخصيص الرسالة';

  @override
  String get whatsappButton => 'واتساب';

  @override
  String get deleteSessionConfirmTitle => 'حذف الحصة؟';

  @override
  String get deleteSessionConfirmMessage =>
      'هل أنت متأكد أنك تريد حذف هذه الحصة؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get typeMessageHint => 'اكتب رسالتك...';

  @override
  String get messageSaved => 'تم حفظ الرسالة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get takeAttendance => 'تسجيل الغياب';

  @override
  String get newAttendance => 'تسجيل حضور جديد';

  @override
  String get changeDateTime => 'تغيير التاريخ والوقت';

  @override
  String get noStudentsInClass => 'لا يوجد طلاب في هذا الفصل';

  @override
  String attendancePresentCount(Object present, Object total) {
    return '$present من $total حاضر';
  }

  @override
  String get tapToMark => 'اضغط على الطالب لتسجيل حضوره';

  @override
  String get markAll => 'الكل';

  @override
  String get clearAll => 'مسح';

  @override
  String get sessionNote => 'ملاحظة الحصة';

  @override
  String get sessionNoteHint => 'إضافة ملاحظة للحصة...';

  @override
  String get saving => 'جار الحفظ...';

  @override
  String get saveAttendance => 'حفظ الحضور';

  @override
  String get attendanceSaved => 'تم حفظ الحضور!';

  @override
  String get defaultAttendanceNote => 'ملاحظة الحصة الافتراضية';

  @override
  String get defaultAttendanceNoteDesc =>
      'تعيين الملاحظة الافتراضية للحصص الجديدة';

  @override
  String get editSessionNote => 'تعديل ملاحظة الحصة';

  @override
  String get defaultNoteHint => 'أدخل الملاحظة الافتراضية...';

  @override
  String get status => 'الحالة';

  @override
  String get unknown => 'مجهول';

  @override
  String get unknownClass => 'فصل غير معروف';

  @override
  String get discardChanges => 'تجاهل التغييرات؟';

  @override
  String get discardChangesMessage =>
      'لديك تغييرات غير محفوظة. هل أنت متأكد أنك تريد تجاهل هذه التغييرات؟';

  @override
  String get discard => 'تجاهل التغييرات';

  @override
  String get consecutiveAbsences => 'متتالي';

  @override
  String get successAddStudent => 'تم إضافة الطالب بنجاح';

  @override
  String errorAddStudent(Object error) {
    return 'خطأ في إضافة الطالب: $error';
  }

  @override
  String errorGeneric(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get errorWhatsApp => 'تعذر تشغيل واتساب';

  @override
  String errorSave(Object error) {
    return 'خطأ في الحفظ: $error';
  }

  @override
  String get successSaveTemplate => 'تم حفظ القالب بنجاح';

  @override
  String get errorSaveTemplate => 'فشل حفظ القالب';

  @override
  String get successResetData =>
      'تم إعادة تعيين البيانات المحلية والمزامنة بنجاح.';

  @override
  String errorResetData(Object error) {
    return 'خطأ في إعادة تعيين البيانات: $error';
  }

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get inactiveAfterDays => 'غير نشط بعد (أيام)';

  @override
  String daysUnit(Object count) {
    return '$count يوم';
  }

  @override
  String get birthdayAlertTime => 'وقت تنبيه عيد الميلاد';

  @override
  String get addNewClassTitle => 'إضافة فصل جديد';

  @override
  String get add => 'إضافة';

  @override
  String get manageClasses => 'إدارة الفصول';

  @override
  String get noClassesFoundAdd => 'لا توجد فصول. أضف واحدًا!';

  @override
  String get noClassSelected => 'لم يتم اختيار فصل';

  @override
  String get userManagement => 'إدارة المستخدمين';

  @override
  String get noPendingUsers => 'لا يوجد مستخدمين قيد الانتظار';

  @override
  String get activate => 'تفعيل';

  @override
  String get noUsersFound => 'لا يوجد مستخدمين';

  @override
  String get errorUpdateUser => 'فشل تحديث بيانات المستخدم';

  @override
  String get classManagement => 'إدارة الفصول';

  @override
  String get noClassesFound => 'لا توجد فصول';

  @override
  String managersForClass(Object className) {
    return 'مديرين $className';
  }

  @override
  String get removeManager => 'إزالة المدير';

  @override
  String removeManagerConfirmation(Object name) {
    return 'هل أنت متأكد من إزالة $name كمدير من هذا الصف؟';
  }

  @override
  String addManagerConfirmation(Object name) {
    return 'هل أنت متأكد من إضافة $name كمدير لهذا الصف؟';
  }

  @override
  String get remove => 'إزالة';

  @override
  String get noEligibleUsers => 'لا يوجد مستخدمين مؤهلين';

  @override
  String get allUsersAreManagers => 'جميع المستخدمين المؤهلين هم مديرون بالفعل';

  @override
  String get accessDenied => 'تم رفض الوصول';

  @override
  String get notEnoughData => 'لا توجد بيانات كافية';

  @override
  String get genericError => 'خطأ';

  @override
  String get availablePlaceholders => 'المتغيرات المتاحة:';

  @override
  String get preview => 'معاينة';

  @override
  String get emptyMessage => '(رسالة فارغة)';

  @override
  String whatsappMessageHint(Object firstname) {
    return 'أهلاً $firstname، كيف حالك؟';
  }

  @override
  String get notificationSettingsDesc => 'إدارة الإشعارات';

  @override
  String get notesNotification => 'الملاحظات';

  @override
  String get notesNotificationDesc => 'تلقي إشعار عند إضافة ملاحظة';

  @override
  String get attendanceNotification => 'الغياب';

  @override
  String get attendanceNotificationDesc => 'تلقي إشعار عند تسجيل الحضور';

  @override
  String get birthdayNotification => 'أعياد الميلاد';

  @override
  String get birthdayNotificationDesc => 'تلقي تذكيرات بأعياد ميلاد الطلاب';

  @override
  String get inactiveNotification => 'الطلاب غير النشطين';

  @override
  String get inactiveNotificationDesc => 'تنبيه عند عدم نشاط طالب';

  @override
  String get newUserNotification => 'تسجيلات جديدة';

  @override
  String get newUserNotificationDesc => 'تلقي إشعار عند تسجيل مستخدم جديد';

  @override
  String get inactiveThresholdDesc => 'الحد الأدنى لاعتبار الطالب غير نشط';

  @override
  String get birthdayReminderDays => 'أيام قبل عيد الميلاد';

  @override
  String get birthdayReminderDaysDesc =>
      'كم يوم قبل عيد الميلاد لإرسال التذكير';

  @override
  String get sameDay => 'نفس اليوم';

  @override
  String daysBefore(Object count) {
    return 'قبل $count يوم';
  }

  @override
  String get tapToChangeTime => 'اضغط لتغيير الوقت';

  @override
  String get morningTime => 'صباحاً (8:00 ص)';

  @override
  String get eveningTime => 'مساءً (8:00 م)';

  @override
  String get pendingActivation => 'بانتظار التفعيل';

  @override
  String get allUsers => 'كل المستخدمين';

  @override
  String get userActivated => 'تم تفعيل المستخدم!';

  @override
  String get userActivationFailed => 'فشل التفعيل';

  @override
  String get currentManagers => 'المديرون الحاليون';

  @override
  String get noManagersAssigned => 'لا يوجد مديرين معينين';

  @override
  String get removeManagerTitle => 'إزالة المدير';

  @override
  String removeManagerConfirm(Object name) {
    return 'هل تريد إزالة $name من الإدارة؟';
  }

  @override
  String get addManager => 'إضافة مدير';

  @override
  String managerAdded(Object name) {
    return 'تم إضافة $name كمدير';
  }

  @override
  String get managerAddFailed => 'فشل إضافة المدير';

  @override
  String get noAdminPrivileges => 'ليس لديك صلاحيات المسؤول.';

  @override
  String get adminPanel => 'لوحة التحكم';

  @override
  String get adminPanelDesc => 'إدارة المستخدمين والفصول والبيانات';

  @override
  String get management => 'الإدارة';

  @override
  String get userManagementDesc => 'تفعيل، تمكين/تعطيل المستخدمين';

  @override
  String get classManagementDesc => 'إدارة الفصول والمديرين';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get appearance => 'المظهر';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get about => 'حول';

  @override
  String get dangerZone => 'مزامنة مع السيرفر';

  @override
  String get resetAllData => 'إعادة تعيين جميع البيانات';

  @override
  String get resetAllDataDesc => 'مزامنة جميع الجلسات والسجلات';

  @override
  String get resetDataTitle => 'مزامنة البيانات؟';

  @override
  String get resetDataConfirm =>
      'هل أنت متأكد من أنك تريد مزامنة جميع البيانات؟';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get classCreated => 'تم إنشاء الفصل بنجاح';

  @override
  String get classCreationError => 'فشل إنشاء الفصل';

  @override
  String get enterClassName => 'أدخل اسم الفصل';

  @override
  String get enterGrade => 'أدخل الصف';

  @override
  String get accountPendingActivation => 'حسابك في انتظار تفعيل المسؤول';

  @override
  String get accountDenied => 'تم رفض طلب التفعيل من قبل المسؤول';

  @override
  String get accountDeniedDesc =>
      'تم رفض طلب التفعيل الخاص بك. إذا كنت تعتقد أن هذا خطأ، يرجى التواصل مع المسؤول للمساعدة.';

  @override
  String get accountDisabled => 'تم تعطيل حسابك من قبل المسؤول';

  @override
  String get invalidCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get registrationSuccessful => 'تم التسجيل بنجاح!';

  @override
  String get registrationSuccessfulDesc => 'يرجى انتظار المسؤول لتفعيل حسابك';

  @override
  String get emailAlreadyExists => 'يوجد حساب مرتبط بهذا البريد الإلكتروني';

  @override
  String get createAccountToStart => 'أنشئ حسابك للبدء';

  @override
  String get contactAdminForActivation =>
      'يرجى التواصل مع المسؤول لتفعيل حسابك';

  @override
  String get abortActivation => 'رفض التفعيل';

  @override
  String get abortActivationConfirm =>
      'هل أنت متأكد أنك تريد رفض طلب تفعيل هذا المستخدم؟';

  @override
  String get userActivationAborted => 'تم رفض تفعيل المستخدم';

  @override
  String get enableUser => 'تفعيل المستخدم';

  @override
  String get disableUser => 'تعطيل المستخدم';

  @override
  String get enableUserConfirm => 'هل تريد تمكين وصول هذا المستخدم للتطبيق؟';

  @override
  String get disableUserConfirm =>
      'هل تريد تعطيل وصول هذا المستخدم؟ سيتم تسجيل خروجه فوراً.';

  @override
  String get userEnabled => 'تم تفعيل المستخدم!';

  @override
  String get userDisabled => 'تم تعطيل المستخدم.';

  @override
  String get deleteUser => 'حذف المستخدم';

  @override
  String get deleteUserConfirm =>
      'هل أنت متأكد أنك تريد حذف هذا المستخدم؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get userDeleted => 'تم حذف المستخدم بنجاح';

  @override
  String get abortedActivations => 'طلبات التفعيل المرفوضة';

  @override
  String get noAbortedUsers => 'لا توجد طلبات تفعيل مرفوضة';

  @override
  String get viewDeniedUsersDesc =>
      'عرض وإدارة المستخدمين الذين تم رفض تفعيلهم';

  @override
  String get reactivate => 'إعادة التفعيل';

  @override
  String reactivateConfirmation(Object name) {
    return 'هل أنت متأكد من إعادة تفعيل $name؟ سيتمكن من تسجيل الدخول مرة أخرى.';
  }

  @override
  String get deny => 'رفض';

  @override
  String get classManagers => 'المديرون';

  @override
  String get disabled => 'معطّل';

  @override
  String get active => 'نشط';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get events => 'الأحداث';

  @override
  String get alerts => 'التنبيهات';

  @override
  String get configuration => 'الإعدادات';

  @override
  String get systemThemeDesc => 'اتباع إعدادات الجهاز';

  @override
  String get lightThemeDesc => 'المظهر الفاتح';

  @override
  String get darkThemeDesc => 'المظهر الداكن';

  @override
  String get englishLanguageDesc => 'اللغة الإنجليزية';

  @override
  String get arabicLanguageDesc => 'اللغة العربية';

  @override
  String get activityNotifications => 'إشعارات النشاط';

  @override
  String get importantWarnings => 'تحذيرات مهمة';

  @override
  String get customizeBehavior => 'تخصيص السلوك';

  @override
  String get manage => 'إدارة';

  @override
  String get good => 'جيد';

  @override
  String get average => 'متوسط';

  @override
  String get poor => 'ضعيف';

  @override
  String get manageClassManagers => 'إدارة المديرين';

  @override
  String classManagersDescription(Object className) {
    return 'مديرو $className';
  }

  @override
  String get enabled => 'مُفعّل';

  @override
  String get accountPendingActivationDesc =>
      'تم إنشاء حسابك بنجاح ولكنه في انتظار موافقة المسؤول. سيتم إشعارك عند تفعيل حسابك.';

  @override
  String removingManager(Object name) {
    return 'جاري إزالة $name...';
  }

  @override
  String addingManager(Object name) {
    return 'جاري إضافة $name...';
  }

  @override
  String get availableUsers => 'المستخدمون المتاحون';

  @override
  String get serverConnectionError =>
      'لا يمكن الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.';

  @override
  String get tryAgain => 'حاول مجدداً';

  @override
  String get loadingData => 'جارٍ تحميل البيانات...';

  @override
  String get cannotConnect => 'لا يمكن الاتصال';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get autoRetrying => 'جارٍ إعادة المحاولة تلقائياً...';

  @override
  String get willAutoRetry => 'ستتم إعادة المحاولة عند الاتصال';

  @override
  String get serverError => 'خطأ في الخادم. يرجى المحاولة لاحقاً.';

  @override
  String get unauthorized => 'غير مصرح. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get actionFailedCheckConnection =>
      'فشل الإجراء. تحقق من اتصالك بالإنترنت.';

  @override
  String get managerAssigned => 'تم تعيين المدير!';

  @override
  String get managerRemoved => 'تمت إزالة المدير.';

  @override
  String get loadingAdminPanel => 'جارٍ تحميل لوحة الإدارة...';

  @override
  String get loadingClassManagers => 'جارٍ تحميل مديري الفصول...';

  @override
  String enableUserConfirmation(Object name) {
    return 'هل أنت متأكد من تفعيل \"$name\"؟';
  }

  @override
  String disableUserConfirmation(Object name) {
    return 'هل أنت متأكد من تعطيل \"$name\"؟';
  }

  @override
  String get enable => 'تفعيل';

  @override
  String get disable => 'تعطيل';

  @override
  String get noStudentsYet => 'لا يوجد طلاب بعد';

  @override
  String get tapAddStudentsAbove => 'اضغط على زر + أعلاه لإضافة طلاب';

  @override
  String get forgotPassword => 'هل نسيت كلمة السر؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get emailOrPhone => 'البريد الإلكتروني أو الهاتف';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneHint => 'أدخل رقم هاتفك';

  @override
  String get phoneAlreadyExists => 'يوجد حساب مرتبط برقم الهاتف هذا بالفعل';

  @override
  String get emailNotConfirmed =>
      'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول';

  @override
  String get checkYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String get confirmEmailDescription =>
      'لقد أرسلنا رابط تأكيد إلى بريدك الإلكتروني. يرجى الضغط عليه لتنشيط حسابك.';

  @override
  String get resendEmail => 'إعادة إرسال البريد';

  @override
  String get emailResent => 'تم إعادة إرسال بريد التأكيد';

  @override
  String get goBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get forgotPasswordTitle => 'استعادة كلمة المرور';

  @override
  String get forgotPasswordSubtitle =>
      'اختر الطريقة التي تفضلها لاستعادة كلمة المرور';

  @override
  String get recoverViaEmail => 'استعادة عبر البريد الإلكتروني';

  @override
  String get recoverViaPhone => 'استعادة عبر الهاتف';

  @override
  String get sendResetLink => 'إرسال رابط الاستعادة';

  @override
  String get sendOTP => 'إرسال كود التحقق';

  @override
  String get resetLinkSent => 'تم إرسال رابط إعادة التعيين بنجاح';

  @override
  String get enterNewPassword => 'أدخل كلمة المرور الجديدة';

  @override
  String get newPasswordHint => 'أدخل 6 أحرف على الأقل';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get resetPasswordAction => 'إعادة تعيين كلمة المرور';

  @override
  String get passwordResetSuccess => 'تم إعادة تعيين كلمة المرور بنجاح';

  @override
  String get pleaseEnterEmail => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get pleaseEnterValidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get pleaseEnterOtp => 'يرجى إدخال كود التحقق';

  @override
  String get otpCode => 'كود التحقق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get emailConfirmedSuccess => 'تم تأكيد البريد الإلكتروني بنجاح!';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get enterOtpAndNewPassword =>
      'أدخل كود التحقق المرسل إليك وكلمة المرور الجديدة.';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get atLeast8Chars => '8 أحرف على الأقل';

  @override
  String get atLeast1Upper => 'حرف كبير واحد على الأقل';

  @override
  String get atLeast1Lower => 'حرف صغير واحد على الأقل';

  @override
  String get atLeast1Digit => 'رقم واحد على الأقل';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get verify => 'تحقق';

  @override
  String get enterCode => 'أدخل الكود';

  @override
  String get enterCodeDesc => 'أدخل كود التحقق المرسل لبريدك الإلكتروني';

  @override
  String get resendConfirmation => 'إعادة إرسال التأكيد';

  @override
  String get invalidToken => 'كود غير صحيح';

  @override
  String get expiredToken => 'كود منتهي الصلاحية';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get verifyCode => 'تحقق من الكود';

  @override
  String get continueAction => 'متابعة';

  @override
  String get changeEmail => 'Change Email';
}
