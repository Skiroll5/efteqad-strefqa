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

  /// No description provided for @upcomingBirthdays.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Birthdays'**
  String get upcomingBirthdays;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today!'**
  String get today;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysLeft(Object count);

  /// No description provided for @markAbsentPast.
  ///
  /// In en, this message translates to:
  /// **'Mark absent for past sessions'**
  String get markAbsentPast;

  /// No description provided for @markAbsentPastCaption.
  ///
  /// In en, this message translates to:
  /// **'Student will be recorded as ABSENT for all previous sessions.'**
  String get markAbsentPastCaption;

  /// No description provided for @sessionTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get sessionTime;

  /// No description provided for @attendanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistory;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @excused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get excused;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @resetDataCaption.
  ///
  /// In en, this message translates to:
  /// **'If you manually reset the backend database, use this to clear local data.'**
  String get resetDataCaption;

  /// No description provided for @resetSyncData.
  ///
  /// In en, this message translates to:
  /// **'Reset Sync & Data'**
  String get resetSyncData;

  /// No description provided for @confirmReset.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset'**
  String get confirmReset;

  /// No description provided for @resetWarning.
  ///
  /// In en, this message translates to:
  /// **'This will delete all local attendance data and force a full re-sync from the server. Use only if backend was cleared.'**
  String get resetWarning;

  /// No description provided for @attendanceSessions.
  ///
  /// In en, this message translates to:
  /// **'Attendance Sessions'**
  String get attendanceSessions;

  /// No description provided for @noUpcomingBirthdays.
  ///
  /// In en, this message translates to:
  /// **'No upcoming birthdays'**
  String get noUpcomingBirthdays;

  /// No description provided for @attendanceDetails.
  ///
  /// In en, this message translates to:
  /// **'Attendance Details'**
  String get attendanceDetails;

  /// No description provided for @attendanceRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance Rate'**
  String get attendanceRate;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get deleteWarning;

  /// No description provided for @noAttendanceRecords.
  ///
  /// In en, this message translates to:
  /// **'No attendance records'**
  String get noAttendanceRecords;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @attendancePercentage.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendancePercentage;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sortByStatus;

  /// No description provided for @absencesTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} Absences (Total)'**
  String absencesTotal(Object count);

  /// No description provided for @consecutive.
  ///
  /// In en, this message translates to:
  /// **'{count} Consecutive'**
  String consecutive(Object count);

  /// No description provided for @whatsappTemplate.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Template'**
  String get whatsappTemplate;

  /// No description provided for @whatsappTemplateDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize the default message sent to students'**
  String get whatsappTemplateDesc;

  /// No description provided for @newArrivals.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get newArrivals;

  /// No description provided for @tapToAddToSession.
  ///
  /// In en, this message translates to:
  /// **'Tap to add to this session'**
  String get tapToAddToSession;

  /// No description provided for @notInSession.
  ///
  /// In en, this message translates to:
  /// **'Not in this session'**
  String get notInSession;

  /// No description provided for @whatsappCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize Message'**
  String get whatsappCustomize;

  /// No description provided for @whatsappButton.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappButton;

  /// No description provided for @deleteSessionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Session?'**
  String get deleteSessionConfirmTitle;

  /// No description provided for @deleteSessionConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this session? This action cannot be undone.'**
  String get deleteSessionConfirmMessage;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessageHint;

  /// No description provided for @messageSaved.
  ///
  /// In en, this message translates to:
  /// **'Message saved'**
  String get messageSaved;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @takeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Take Attendance'**
  String get takeAttendance;

  /// No description provided for @newAttendance.
  ///
  /// In en, this message translates to:
  /// **'New Attendance'**
  String get newAttendance;

  /// No description provided for @changeDateTime.
  ///
  /// In en, this message translates to:
  /// **'Change Date & Time'**
  String get changeDateTime;

  /// No description provided for @noStudentsInClass.
  ///
  /// In en, this message translates to:
  /// **'No students in this class'**
  String get noStudentsInClass;

  /// No description provided for @attendancePresentCount.
  ///
  /// In en, this message translates to:
  /// **'{present} of {total} present'**
  String attendancePresentCount(Object present, Object total);

  /// No description provided for @tapToMark.
  ///
  /// In en, this message translates to:
  /// **'Tap students to mark attendance'**
  String get tapToMark;

  /// No description provided for @markAll.
  ///
  /// In en, this message translates to:
  /// **'Mark All'**
  String get markAll;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @sessionNote.
  ///
  /// In en, this message translates to:
  /// **'Session Note'**
  String get sessionNote;

  /// No description provided for @sessionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add any note about this session...'**
  String get sessionNoteHint;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Save Attendance'**
  String get saveAttendance;

  /// No description provided for @attendanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved!'**
  String get attendanceSaved;

  /// No description provided for @defaultAttendanceNote.
  ///
  /// In en, this message translates to:
  /// **'Default Attendance Note'**
  String get defaultAttendanceNote;

  /// No description provided for @defaultAttendanceNoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Set the default note for new sessions'**
  String get defaultAttendanceNoteDesc;

  /// No description provided for @editSessionNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Session Note'**
  String get editSessionNote;

  /// No description provided for @defaultNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter default note...'**
  String get defaultNoteHint;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;
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
