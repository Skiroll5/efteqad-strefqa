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
  /// **'Wadeea'**
  String get appTitle;

  /// No description provided for @churchName.
  ///
  /// In en, this message translates to:
  /// **'Church of Martyr Rafqa and Her Children in Al-Qanater Al-Khayriya'**
  String get churchName;

  /// No description provided for @loginVerse.
  ///
  /// In en, this message translates to:
  /// **'اِحْفَظِ الْوَدِيعَةَ الصَّالِحَةَ بِالرُّوحِ الْقُدُسِ السَّاكِنِ فِينَا. (2 تي 1: 14).'**
  String get loginVerse;

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
  /// **'Flag student after {threshold} consecutive absences'**
  String thresholdCaption(Object threshold);

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

  /// No description provided for @waitingForClassAssignment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for class assignment'**
  String get waitingForClassAssignment;

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

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

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

  /// No description provided for @phoneNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get phoneNumberCopied;

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

  /// No description provided for @whatsappDefaultTemplate.
  ///
  /// In en, this message translates to:
  /// **'Hi %firstname%,'**
  String get whatsappDefaultTemplate;

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
  /// **'Grade (Optional)'**
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

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

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

  /// No description provided for @lastSession.
  ///
  /// In en, this message translates to:
  /// **'Last Session'**
  String get lastSession;

  /// No description provided for @attendanceSessions.
  ///
  /// In en, this message translates to:
  /// **'Attendance Sessions'**
  String get attendanceSessions;

  /// No description provided for @noAttendanceSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No attendance sessions yet'**
  String get noAttendanceSessionsYet;

  /// No description provided for @tapBelowToTakeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Tap below to take attendance'**
  String get tapBelowToTakeAttendance;

  /// No description provided for @addStudentsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add students first'**
  String get addStudentsFirst;

  /// No description provided for @addStudentsFirstToTakeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Add students first to take attendance'**
  String get addStudentsFirstToTakeAttendance;

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
  /// **'All'**
  String get markAll;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAll;

  /// No description provided for @sessionNote.
  ///
  /// In en, this message translates to:
  /// **'Session Note'**
  String get sessionNote;

  /// No description provided for @sessionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add session note...'**
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

  /// No description provided for @unknownClass.
  ///
  /// In en, this message translates to:
  /// **'Unknown class'**
  String get unknownClass;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChanges;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discard;

  /// No description provided for @consecutiveAbsences.
  ///
  /// In en, this message translates to:
  /// **'Consecutive'**
  String get consecutiveAbsences;

  /// No description provided for @successAddStudent.
  ///
  /// In en, this message translates to:
  /// **'Student added successfully'**
  String get successAddStudent;

  /// No description provided for @errorAddStudent.
  ///
  /// In en, this message translates to:
  /// **'Error adding student: {error}'**
  String errorAddStudent(Object error);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(Object error);

  /// No description provided for @errorWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not launch WhatsApp'**
  String get errorWhatsApp;

  /// No description provided for @errorSave.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSave(Object error);

  /// No description provided for @successSaveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template saved successfully'**
  String get successSaveTemplate;

  /// No description provided for @errorSaveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Failed to save template'**
  String get errorSaveTemplate;

  /// No description provided for @successResetData.
  ///
  /// In en, this message translates to:
  /// **'Success: Local data reset and re-synced.'**
  String get successResetData;

  /// No description provided for @errorResetData.
  ///
  /// In en, this message translates to:
  /// **'Error resetting data: {error}'**
  String errorResetData(Object error);

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @inactiveAfterDays.
  ///
  /// In en, this message translates to:
  /// **'Inactive after (days)'**
  String get inactiveAfterDays;

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysUnit(Object count);

  /// No description provided for @birthdayAlertTime.
  ///
  /// In en, this message translates to:
  /// **'Birthday alert time'**
  String get birthdayAlertTime;

  /// No description provided for @addNewClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Class'**
  String get addNewClassTitle;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @manageClasses.
  ///
  /// In en, this message translates to:
  /// **'Manage Classes'**
  String get manageClasses;

  /// No description provided for @noClassesFoundAdd.
  ///
  /// In en, this message translates to:
  /// **'No classes found. Add one!'**
  String get noClassesFoundAdd;

  /// No description provided for @noClassSelected.
  ///
  /// In en, this message translates to:
  /// **'No class selected'**
  String get noClassSelected;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @noPendingUsers.
  ///
  /// In en, this message translates to:
  /// **'No pending users'**
  String get noPendingUsers;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @errorUpdateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to update user'**
  String get errorUpdateUser;

  /// No description provided for @classManagement.
  ///
  /// In en, this message translates to:
  /// **'Class Management'**
  String get classManagement;

  /// No description provided for @noClassesFound.
  ///
  /// In en, this message translates to:
  /// **'No classes found'**
  String get noClassesFound;

  /// No description provided for @managersForClass.
  ///
  /// In en, this message translates to:
  /// **'Managers: {className}'**
  String managersForClass(Object className);

  /// No description provided for @removeManager.
  ///
  /// In en, this message translates to:
  /// **'Remove Manager'**
  String get removeManager;

  /// No description provided for @removeManagerConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} as a manager from this class?'**
  String removeManagerConfirmation(Object name);

  /// No description provided for @addManagerConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to add {name} as a manager for this class?'**
  String addManagerConfirmation(Object name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @noEligibleUsers.
  ///
  /// In en, this message translates to:
  /// **'No eligible users'**
  String get noEligibleUsers;

  /// No description provided for @allUsersAreManagers.
  ///
  /// In en, this message translates to:
  /// **'All eligible users are already managers'**
  String get allUsersAreManagers;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get notEnoughData;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get genericError;

  /// No description provided for @availablePlaceholders.
  ///
  /// In en, this message translates to:
  /// **'Available placeholders:'**
  String get availablePlaceholders;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @emptyMessage.
  ///
  /// In en, this message translates to:
  /// **'(Empty message)'**
  String get emptyMessage;

  /// No description provided for @whatsappMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Hello {firstname}, how are you?'**
  String whatsappMessageHint(Object firstname);

  /// No description provided for @notificationSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage push notifications'**
  String get notificationSettingsDesc;

  /// No description provided for @notesNotification.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesNotification;

  /// No description provided for @notesNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a note is added'**
  String get notesNotificationDesc;

  /// No description provided for @attendanceNotification.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceNotification;

  /// No description provided for @attendanceNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when attendance is recorded'**
  String get attendanceNotificationDesc;

  /// No description provided for @birthdayNotification.
  ///
  /// In en, this message translates to:
  /// **'Birthday Reminders'**
  String get birthdayNotification;

  /// No description provided for @birthdayNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Get reminders for student birthdays'**
  String get birthdayNotificationDesc;

  /// No description provided for @inactiveNotification.
  ///
  /// In en, this message translates to:
  /// **'Inactive Students'**
  String get inactiveNotification;

  /// No description provided for @inactiveNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Alert when a student becomes inactive'**
  String get inactiveNotificationDesc;

  /// No description provided for @newUserNotification.
  ///
  /// In en, this message translates to:
  /// **'New Registrations'**
  String get newUserNotification;

  /// No description provided for @newUserNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Notify when a new user registers'**
  String get newUserNotificationDesc;

  /// No description provided for @inactiveThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Threshold to consider a student inactive'**
  String get inactiveThresholdDesc;

  /// No description provided for @birthdayReminderDays.
  ///
  /// In en, this message translates to:
  /// **'Days before birthday'**
  String get birthdayReminderDays;

  /// No description provided for @birthdayReminderDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'How many days before to send reminder'**
  String get birthdayReminderDaysDesc;

  /// No description provided for @sameDay.
  ///
  /// In en, this message translates to:
  /// **'Same day'**
  String get sameDay;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} days before'**
  String daysBefore(Object count);

  /// No description provided for @tapToChangeTime.
  ///
  /// In en, this message translates to:
  /// **'Tap to change time'**
  String get tapToChangeTime;

  /// No description provided for @morningTime.
  ///
  /// In en, this message translates to:
  /// **'Morning (8:00 AM)'**
  String get morningTime;

  /// No description provided for @eveningTime.
  ///
  /// In en, this message translates to:
  /// **'Evening before (8:00 PM)'**
  String get eveningTime;

  /// No description provided for @pendingActivation.
  ///
  /// In en, this message translates to:
  /// **'Pending Activation'**
  String get pendingActivation;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @userActivated.
  ///
  /// In en, this message translates to:
  /// **'User activated!'**
  String get userActivated;

  /// No description provided for @userActivationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to activate'**
  String get userActivationFailed;

  /// No description provided for @currentManagers.
  ///
  /// In en, this message translates to:
  /// **'Current Managers'**
  String get currentManagers;

  /// No description provided for @noManagersAssigned.
  ///
  /// In en, this message translates to:
  /// **'No managers assigned'**
  String get noManagersAssigned;

  /// No description provided for @removeManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Manager'**
  String get removeManagerTitle;

  /// No description provided for @removeManagerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} as manager?'**
  String removeManagerConfirm(Object name);

  /// No description provided for @addManager.
  ///
  /// In en, this message translates to:
  /// **'Add Manager'**
  String get addManager;

  /// No description provided for @managerAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added as manager'**
  String managerAdded(Object name);

  /// No description provided for @managerAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add manager'**
  String get managerAddFailed;

  /// No description provided for @noAdminPrivileges.
  ///
  /// In en, this message translates to:
  /// **'You do not have admin privileges.'**
  String get noAdminPrivileges;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @adminPanelDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage users, classes & data'**
  String get adminPanelDesc;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @userManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Activate, enable/disable users'**
  String get userManagementDesc;

  /// No description provided for @classManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage classes and managers'**
  String get classManagementDesc;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @resetAllData.
  ///
  /// In en, this message translates to:
  /// **'Synchronize with the server'**
  String get resetAllData;

  /// No description provided for @resetAllDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync all sessions and records'**
  String get resetAllDataDesc;

  /// No description provided for @resetDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Data?'**
  String get resetDataTitle;

  /// No description provided for @resetDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to synchronize all data?'**
  String get resetDataConfirm;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @classCreated.
  ///
  /// In en, this message translates to:
  /// **'Class created successfully'**
  String get classCreated;

  /// No description provided for @classCreationError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create class'**
  String get classCreationError;

  /// No description provided for @enterClassName.
  ///
  /// In en, this message translates to:
  /// **'Enter class name'**
  String get enterClassName;

  /// No description provided for @enterGrade.
  ///
  /// In en, this message translates to:
  /// **'Enter grade'**
  String get enterGrade;

  /// No description provided for @accountPendingActivation.
  ///
  /// In en, this message translates to:
  /// **'Your account is awaiting admin activation'**
  String get accountPendingActivation;

  /// No description provided for @accountDenied.
  ///
  /// In en, this message translates to:
  /// **'Your activation request was denied by the administrator'**
  String get accountDenied;

  /// No description provided for @accountDeniedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your activation request was denied. If you believe this was a mistake, please contact the administrator for assistance.'**
  String get accountDeniedDesc;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Your account has been disabled by the administrator'**
  String get accountDisabled;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful!'**
  String get registrationSuccessful;

  /// No description provided for @registrationSuccessfulDesc.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the administrator to activate your account'**
  String get registrationSuccessfulDesc;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists'**
  String get emailAlreadyExists;

  /// No description provided for @createAccountToStart.
  ///
  /// In en, this message translates to:
  /// **'Create your account to get started'**
  String get createAccountToStart;

  /// No description provided for @contactAdminForActivation.
  ///
  /// In en, this message translates to:
  /// **'Please contact the administrator to activate your account'**
  String get contactAdminForActivation;

  /// No description provided for @abortActivation.
  ///
  /// In en, this message translates to:
  /// **'Deny Activation'**
  String get abortActivation;

  /// No description provided for @abortActivationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deny this user\'s activation request?'**
  String get abortActivationConfirm;

  /// No description provided for @userActivationAborted.
  ///
  /// In en, this message translates to:
  /// **'User activation denied'**
  String get userActivationAborted;

  /// No description provided for @enableUser.
  ///
  /// In en, this message translates to:
  /// **'Enable User'**
  String get enableUser;

  /// No description provided for @disableUser.
  ///
  /// In en, this message translates to:
  /// **'Disable User'**
  String get disableUser;

  /// No description provided for @enableUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enable this user\'s access to the app?'**
  String get enableUserConfirm;

  /// No description provided for @disableUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disable this user\'s access? They will be logged out immediately.'**
  String get disableUserConfirm;

  /// No description provided for @userEnabled.
  ///
  /// In en, this message translates to:
  /// **'User enabled!'**
  String get userEnabled;

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'User disabled.'**
  String get userDisabled;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @deleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user? This action cannot be undone.'**
  String get deleteUserConfirm;

  /// No description provided for @userDeleted.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get userDeleted;

  /// No description provided for @abortedActivations.
  ///
  /// In en, this message translates to:
  /// **'Denied Activations'**
  String get abortedActivations;

  /// No description provided for @noAbortedUsers.
  ///
  /// In en, this message translates to:
  /// **'No denied activation requests'**
  String get noAbortedUsers;

  /// No description provided for @viewDeniedUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'View and manage users whose activation was denied'**
  String get viewDeniedUsersDesc;

  /// No description provided for @reactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivate;

  /// No description provided for @reactivateConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reactivate {name}? They will be able to log in again.'**
  String reactivateConfirmation(Object name);

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @classManagers.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get classManagers;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @systemThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get systemThemeDesc;

  /// No description provided for @lightThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Bright appearance'**
  String get lightThemeDesc;

  /// No description provided for @darkThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Dark appearance'**
  String get darkThemeDesc;

  /// No description provided for @englishLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'English language'**
  String get englishLanguageDesc;

  /// No description provided for @arabicLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Arabic language'**
  String get arabicLanguageDesc;

  /// No description provided for @activityNotifications.
  ///
  /// In en, this message translates to:
  /// **'Activity notifications'**
  String get activityNotifications;

  /// No description provided for @importantWarnings.
  ///
  /// In en, this message translates to:
  /// **'Important warnings'**
  String get importantWarnings;

  /// No description provided for @customizeBehavior.
  ///
  /// In en, this message translates to:
  /// **'Customize behavior'**
  String get customizeBehavior;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @manageClassManagers.
  ///
  /// In en, this message translates to:
  /// **'Manage Managers'**
  String get manageClassManagers;

  /// No description provided for @classManagersDescription.
  ///
  /// In en, this message translates to:
  /// **'Managers for {className}'**
  String classManagersDescription(Object className);

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @accountPendingActivationDesc.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully but is waiting for administrator approval. You will be notified once your account is active.'**
  String get accountPendingActivationDesc;

  /// No description provided for @removingManager.
  ///
  /// In en, this message translates to:
  /// **'Removing {name}...'**
  String removingManager(Object name);

  /// No description provided for @addingManager.
  ///
  /// In en, this message translates to:
  /// **'Adding {name}...'**
  String addingManager(Object name);

  /// No description provided for @availableUsers.
  ///
  /// In en, this message translates to:
  /// **'Available Users'**
  String get availableUsers;

  /// No description provided for @serverConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Please check your internet connection.'**
  String get serverConnectionError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @cannotConnect.
  ///
  /// In en, this message translates to:
  /// **'Cannot Connect'**
  String get cannotConnect;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get somethingWentWrong;

  /// No description provided for @autoRetrying.
  ///
  /// In en, this message translates to:
  /// **'Auto-retrying...'**
  String get autoRetrying;

  /// No description provided for @willAutoRetry.
  ///
  /// In en, this message translates to:
  /// **'Will auto-retry when connected'**
  String get willAutoRetry;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please log in again.'**
  String get unauthorized;

  /// No description provided for @actionFailedCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Check your internet connection.'**
  String get actionFailedCheckConnection;

  /// No description provided for @managerAssigned.
  ///
  /// In en, this message translates to:
  /// **'Manager assigned!'**
  String get managerAssigned;

  /// No description provided for @managerRemoved.
  ///
  /// In en, this message translates to:
  /// **'Manager removed.'**
  String get managerRemoved;

  /// No description provided for @loadingAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Loading Admin Panel...'**
  String get loadingAdminPanel;

  /// No description provided for @loadingClassManagers.
  ///
  /// In en, this message translates to:
  /// **'Loading class managers...'**
  String get loadingClassManagers;

  /// No description provided for @enableUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to enable \"{name}\"?'**
  String enableUserConfirmation(Object name);

  /// No description provided for @disableUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disable \"{name}\"?'**
  String disableUserConfirmation(Object name);

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @noStudentsYet.
  ///
  /// In en, this message translates to:
  /// **'No students yet'**
  String get noStudentsYet;

  /// No description provided for @tapAddStudentsAbove.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button above to add students'**
  String get tapAddStudentsAbove;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneHint;

  /// No description provided for @phoneAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this phone number already exists'**
  String get phoneAlreadyExists;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before logging in'**
  String get emailNotConfirmed;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmail;

  /// No description provided for @confirmEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a confirmation link to your email. Please click it to activate your account.'**
  String get confirmEmailDescription;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @emailResent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation email resent'**
  String get emailResent;

  /// No description provided for @goBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go back to Login'**
  String get goBackToLogin;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to recover your password'**
  String get forgotPasswordSubtitle;

  /// No description provided for @recoverViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Recover via Email'**
  String get recoverViaEmail;

  /// No description provided for @recoverViaPhone.
  ///
  /// In en, this message translates to:
  /// **'Recover via Phone'**
  String get recoverViaPhone;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @sendOTP.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent successfully'**
  String get resetLinkSent;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter New Password'**
  String get enterNewPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 6 characters'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @resetPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordAction;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccess;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP code'**
  String get pleaseEnterOtp;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @emailConfirmedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email confirmed successfully!'**
  String get emailConfirmedSuccess;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterOtpAndNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP code sent to you and your new password.'**
  String get enterOtpAndNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @atLeast8Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Chars;

  /// No description provided for @atLeast1Upper.
  ///
  /// In en, this message translates to:
  /// **'At least 1 uppercase letter'**
  String get atLeast1Upper;

  /// No description provided for @atLeast1Lower.
  ///
  /// In en, this message translates to:
  /// **'At least 1 lowercase letter'**
  String get atLeast1Lower;

  /// No description provided for @atLeast1Digit.
  ///
  /// In en, this message translates to:
  /// **'At least 1 number'**
  String get atLeast1Digit;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get enterCode;

  /// No description provided for @enterCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your email'**
  String get enterCodeDesc;

  /// No description provided for @resendConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Resend Confirmation'**
  String get resendConfirmation;

  /// No description provided for @invalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidToken;

  /// No description provided for @expiredToken.
  ///
  /// In en, this message translates to:
  /// **'Expired code'**
  String get expiredToken;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get googleSignIn;
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
