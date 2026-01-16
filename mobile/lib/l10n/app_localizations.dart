import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'St. Refqa Efteqad'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @waitActivation.
  ///
  /// In en, this message translates to:
  /// **'Wait for admin activation'**
  String get waitActivation;

  /// No description provided for @classes.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classes;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @statisticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsDashboard;

  /// No description provided for @atRiskStudents.
  ///
  /// In en, this message translates to:
  /// **'At Risk Students'**
  String get atRiskStudents;

  /// No description provided for @atRiskThreshold.
  ///
  /// In en, this message translates to:
  /// **'At Risk Threshold'**
  String get atRiskThreshold;

  /// No description provided for @thresholdCaption.
  ///
  /// In en, this message translates to:
  /// **'Flag student after {count} consecutive absences'**
  String thresholdCaption(Object count);

  /// No description provided for @attendanceTrends.
  ///
  /// In en, this message translates to:
  /// **'Attendance Trends (Last 12 Weeks)'**
  String get attendanceTrends;

  /// No description provided for @absentTimes.
  ///
  /// In en, this message translates to:
  /// **'Absent {count} times'**
  String absentTimes(Object count);

  /// No description provided for @noAtRiskStudents.
  ///
  /// In en, this message translates to:
  /// **'Great job! No students are currently at risk.'**
  String get noAtRiskStudents;

  /// No description provided for @yourClasses.
  ///
  /// In en, this message translates to:
  /// **'Your Classes'**
  String get yourClasses;

  /// No description provided for @yourClass.
  ///
  /// In en, this message translates to:
  /// **'Your Class'**
  String get yourClass;

  /// No description provided for @selectClassToManage.
  ///
  /// In en, this message translates to:
  /// **'Select a class to manage students and attendance'**
  String get selectClassToManage;

  /// No description provided for @noClassesYet.
  ///
  /// In en, this message translates to:
  /// **'No classes yet'**
  String get noClassesYet;

  /// No description provided for @noClassAssigned.
  ///
  /// In en, this message translates to:
  /// **'No class assigned'**
  String get noClassAssigned;

  /// No description provided for @createClass.
  ///
  /// In en, this message translates to:
  /// **'Create Class'**
  String get createClass;

  /// No description provided for @addClass.
  ///
  /// In en, this message translates to:
  /// **'Add Class'**
  String get addClass;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get hi;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No Phone'**
  String get noPhone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @birthdate.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get birthdate;

  /// No description provided for @visitationNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get visitationNotes;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotes;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{count} years old'**
  String yearsOld(Object count);

  /// No description provided for @nextBirthday.
  ///
  /// In en, this message translates to:
  /// **'Next Birthday'**
  String get nextBirthday;

  /// No description provided for @birthdayCountdown.
  ///
  /// In en, this message translates to:
  /// **'In {months} months, {days} days'**
  String birthdayCountdown(Object months, Object days);

  /// No description provided for @todayIsBirthday.
  ///
  /// In en, this message translates to:
  /// **'Today is their birthday! 🎉'**
  String get todayIsBirthday;

  /// No description provided for @addNoteCaption.
  ///
  /// In en, this message translates to:
  /// **'Add a note for this student'**
  String get addNoteCaption;

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'Write note content...'**
  String get whatHappened;

  /// No description provided for @studentDetails.
  ///
  /// In en, this message translates to:
  /// **'Student Details'**
  String get studentDetails;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @servant.
  ///
  /// In en, this message translates to:
  /// **'Servant'**
  String get servant;

  /// No description provided for @studentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Student not found'**
  String get studentNotFound;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @noAddress.
  ///
  /// In en, this message translates to:
  /// **'No address provided'**
  String get noAddress;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @editStudent.
  ///
  /// In en, this message translates to:
  /// **'Edit Student'**
  String get editStudent;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @deleteStudentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Student?'**
  String get deleteStudentQuestion;

  /// No description provided for @deleteStudentWarning.
  ///
  /// In en, this message translates to:
  /// **'This student and all their records will be permanently removed. This action cannot be undone.'**
  String get deleteStudentWarning;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @addNewStudent.
  ///
  /// In en, this message translates to:
  /// **'Add New Student'**
  String get addNewStudent;

  /// No description provided for @addStudentCaption.
  ///
  /// In en, this message translates to:
  /// **'Add a student to this class'**
  String get addStudentCaption;

  /// No description provided for @studentName.
  ///
  /// In en, this message translates to:
  /// **'Student Name'**
  String get studentName;

  /// No description provided for @phoneNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (optional)'**
  String get phoneNumberOptional;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @addStudentAction.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudentAction;

  /// No description provided for @createNewClass.
  ///
  /// In en, this message translates to:
  /// **'Create New Class'**
  String get createNewClass;

  /// No description provided for @addClassCaption.
  ///
  /// In en, this message translates to:
  /// **'Add a new class to manage students'**
  String get addClassCaption;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'Class Name'**
  String get className;

  /// No description provided for @classNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunday School - Grade 3'**
  String get classNameHint;

  /// No description provided for @gradeOptional.
  ///
  /// In en, this message translates to:
  /// **'Grade (optional)'**
  String get gradeOptional;

  /// No description provided for @gradeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grade 3'**
  String get gradeHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
