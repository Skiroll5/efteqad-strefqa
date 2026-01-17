// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'St. Refqa Efteqad';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get register => 'Register';

  @override
  String get waitActivation => 'Wait for admin activation';

  @override
  String get classes => 'Classes';

  @override
  String get students => 'Students';

  @override
  String get attendance => 'Attendance';

  @override
  String get statisticsDashboard => 'Statistics';

  @override
  String get atRiskStudents => 'At Risk Students';

  @override
  String get atRiskThreshold => 'At Risk Threshold';

  @override
  String thresholdCaption(Object count) {
    return 'Flag student after $count consecutive absences';
  }

  @override
  String get attendanceTrends => 'Attendance Trends (Last 12 Weeks)';

  @override
  String absentTimes(Object count) {
    return 'Absent $count times';
  }

  @override
  String get noAtRiskStudents =>
      'Great job! No students are currently at risk.';

  @override
  String get yourClasses => 'Your Classes';

  @override
  String get yourClass => 'Your Class';

  @override
  String get selectClassToManage =>
      'Select a class to manage students and attendance';

  @override
  String get noClassesYet => 'No classes yet';

  @override
  String get noClassAssigned => 'No class assigned';

  @override
  String get createClass => 'Create Class';

  @override
  String get addClass => 'Add Class';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get rename => 'Rename';

  @override
  String get hi => 'Hi';

  @override
  String get call => 'Call';

  @override
  String get phone => 'Phone';

  @override
  String get noPhone => 'No Phone';

  @override
  String get address => 'Address';

  @override
  String get birthdate => 'Birthdate';

  @override
  String get visitationNotes => 'Notes';

  @override
  String get noNotes => 'No notes yet.';

  @override
  String get addNote => 'Add Note';

  @override
  String get age => 'Age';

  @override
  String yearsOld(Object count) {
    return '$count years old';
  }

  @override
  String get nextBirthday => 'Next Birthday';

  @override
  String birthdayCountdown(Object months, Object days) {
    return 'In $months months, $days days';
  }

  @override
  String get todayIsBirthday => 'Today is their birthday! 🎉';

  @override
  String get addNoteCaption => 'Add a note for this student';

  @override
  String get whatHappened => 'Write note content...';

  @override
  String get studentDetails => 'Student Details';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get version => 'Version';

  @override
  String get admin => 'Admin';

  @override
  String get servant => 'Servant';

  @override
  String get studentNotFound => 'Student not found';

  @override
  String get details => 'Details';

  @override
  String get noAddress => 'No address provided';

  @override
  String get notSet => 'Not set';

  @override
  String get editStudent => 'Edit Student';

  @override
  String get name => 'Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get deleteStudentQuestion => 'Delete Student?';

  @override
  String get deleteStudentWarning =>
      'This student and all their records will be permanently removed. This action cannot be undone.';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get addNewStudent => 'Add New Student';

  @override
  String get addStudentCaption => 'Add a student to this class';

  @override
  String get studentName => 'Student Name';

  @override
  String get phoneNumberOptional => 'Phone Number (optional)';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get addStudentAction => 'Add Student';

  @override
  String get createNewClass => 'Create New Class';

  @override
  String get addClassCaption => 'Add a new class to manage students';

  @override
  String get className => 'Class Name';

  @override
  String get classNameHint => 'e.g. Sunday School - Grade 3';

  @override
  String get gradeOptional => 'Grade (optional)';

  @override
  String get gradeHint => 'e.g. Grade 3';

  @override
  String get create => 'Create';

  @override
  String get upcomingBirthdays => 'Upcoming Birthdays';

  @override
  String get today => 'Today!';

  @override
  String daysLeft(Object count) {
    return '$count days left';
  }

  @override
  String get markAbsentPast => 'Mark absent for past sessions';

  @override
  String get markAbsentPastCaption =>
      'Student will be recorded as ABSENT for all previous sessions.';

  @override
  String get sessionTime => 'Time';

  @override
  String get attendanceHistory => 'Attendance History';

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get excused => 'Excused';

  @override
  String get late => 'Late';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get resetDataCaption =>
      'If you manually reset the backend database, use this to clear local data.';

  @override
  String get resetSyncData => 'Reset Sync & Data';

  @override
  String get confirmReset => 'Confirm Reset';

  @override
  String get resetWarning =>
      'This will delete all local attendance data and force a full re-sync from the server. Use only if backend was cleared.';

  @override
  String get attendanceDetails => 'Attendance Details';

  @override
  String get attendanceRate => 'Attendance Rate';

  @override
  String get noAttendanceRecords => 'No attendance records';

  @override
  String get sortBy => 'Sort by';

  @override
  String get attendancePercentage => 'Attendance';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String absencesTotal(Object count) {
    return '$count Absences (Total)';
  }

  @override
  String consecutive(Object count) {
    return '$count Consecutive';
  }

  @override
  String get whatsappTemplate => 'WhatsApp Template';

  @override
  String get whatsappTemplateDesc =>
      'Customize the default message sent to students';

  @override
  String get newArrivals => 'New Arrivals';

  @override
  String get tapToAddToSession => 'Tap to add to this session';

  @override
  String get notInSession => 'Not in this session';

  @override
  String get whatsappCustomize => 'Customize Message';

  @override
  String get whatsappButton => 'WhatsApp';

  @override
  String get deleteSessionConfirmTitle => 'Delete Session?';

  @override
  String get deleteSessionConfirmMessage =>
      'Are you sure you want to delete this session? This action cannot be undone.';

  @override
  String get typeMessageHint => 'Type your message...';

  @override
  String get messageSaved => 'Message saved';

  @override
  String get viewAll => 'View All';

  @override
  String get takeAttendance => 'Take Attendance';

  @override
  String get newAttendance => 'New Attendance';

  @override
  String get changeDateTime => 'Change Date & Time';

  @override
  String get noStudentsInClass => 'No students in this class';

  @override
  String attendancePresentCount(Object present, Object total) {
    return '$present of $total present';
  }

  @override
  String get tapToMark => 'Tap students to mark attendance';

  @override
  String get markAll => 'Mark All';

  @override
  String get clearAll => 'Clear All';

  @override
  String get sessionNote => 'Session Note';

  @override
  String get sessionNoteHint => 'Add any note about this session (optional)...';

  @override
  String get saving => 'Saving...';

  @override
  String get saveAttendance => 'Save Attendance';

  @override
  String get attendanceSaved => 'Attendance saved!';
}
