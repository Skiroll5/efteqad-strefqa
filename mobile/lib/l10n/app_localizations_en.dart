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
  String thresholdCaption(Object threshold) {
    return 'Flag student after $threshold consecutive absences';
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
  String get gradeOptional => 'Grade (Optional)';

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
  String get lastSession => 'Last Session';

  @override
  String get attendanceSessions => 'Attendance Sessions';

  @override
  String get noUpcomingBirthdays => 'No upcoming birthdays';

  @override
  String get attendanceDetails => 'Attendance Details';

  @override
  String get attendanceRate => 'Attendance Rate';

  @override
  String get showMore => 'Read More';

  @override
  String get showLess => 'Show Less';

  @override
  String get deleteWarning => 'Are you sure you want to delete this?';

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
  String get sortByName => 'Name';

  @override
  String get sortByStatus => 'Status';

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
  String get markAll => 'All';

  @override
  String get clearAll => 'Clear';

  @override
  String get sessionNote => 'Session Note';

  @override
  String get sessionNoteHint => 'Add session note...';

  @override
  String get saving => 'Saving...';

  @override
  String get saveAttendance => 'Save Attendance';

  @override
  String get attendanceSaved => 'Attendance saved!';

  @override
  String get defaultAttendanceNote => 'Default Attendance Note';

  @override
  String get defaultAttendanceNoteDesc =>
      'Set the default note for new sessions';

  @override
  String get editSessionNote => 'Edit Session Note';

  @override
  String get defaultNoteHint => 'Enter default note...';

  @override
  String get status => 'Status';

  @override
  String get unknown => 'Unknown';

  @override
  String get discardChanges => 'Discard Changes?';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes. Are you sure you want to discard them?';

  @override
  String get discard => 'Discard Changes';

  @override
  String get consecutiveAbsences => 'Consecutive';

  @override
  String get successAddStudent => 'Student added successfully';

  @override
  String errorAddStudent(Object error) {
    return 'Error adding student: $error';
  }

  @override
  String errorGeneric(Object error) {
    return 'Error: $error';
  }

  @override
  String get errorWhatsApp => 'Could not launch WhatsApp';

  @override
  String errorSave(Object error) {
    return 'Error saving: $error';
  }

  @override
  String get successSaveTemplate => 'Template saved successfully';

  @override
  String get errorSaveTemplate => 'Failed to save template';

  @override
  String get successResetData => 'Success: Local data reset and re-synced.';

  @override
  String errorResetData(Object error) {
    return 'Error resetting data: $error';
  }

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get inactiveAfterDays => 'Inactive after (days)';

  @override
  String daysUnit(Object count) {
    return '$count days';
  }

  @override
  String get birthdayAlertTime => 'Birthday alert time';

  @override
  String get addNewClassTitle => 'Add New Class';

  @override
  String get add => 'Add';

  @override
  String get manageClasses => 'Manage Classes';

  @override
  String get noClassesFoundAdd => 'No classes found. Add one!';

  @override
  String get noClassSelected => 'No class selected';

  @override
  String get userManagement => 'User Management';

  @override
  String get noPendingUsers => 'No pending users';

  @override
  String get activate => 'Activate';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get errorUpdateUser => 'Failed to update user';

  @override
  String get classManagement => 'Class Management';

  @override
  String get noClassesFound => 'No classes found';

  @override
  String managersForClass(Object className) {
    return 'Managers: $className';
  }

  @override
  String get removeManager => 'Remove Manager';

  @override
  String get remove => 'Remove';

  @override
  String get noEligibleUsers => 'No eligible users';

  @override
  String get allUsersAreManagers => 'All eligible users are already managers';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get notEnoughData => 'Not enough data';

  @override
  String get genericError => 'Error';

  @override
  String get availablePlaceholders => 'Available placeholders:';

  @override
  String get preview => 'Preview';

  @override
  String get emptyMessage => '(Empty message)';

  @override
  String whatsappMessageHint(Object firstname) {
    return 'Hello $firstname, how are you?';
  }

  @override
  String get notificationSettingsDesc => 'Manage push notifications';

  @override
  String get notesNotification => '📝 Notes';

  @override
  String get attendanceNotification => '📊 Attendance';

  @override
  String get birthdayNotification => '🎂 Birthday Reminders';

  @override
  String get inactiveNotification => '⚠️ Inactive Students';

  @override
  String get newUserNotification => '👤 New Registrations';

  @override
  String get morningTime => 'Morning (8:00 AM)';

  @override
  String get eveningTime => 'Evening before (8:00 PM)';

  @override
  String get pendingActivation => 'Pending Activation';

  @override
  String get allUsers => 'All Users';

  @override
  String get userActivated => 'User activated!';

  @override
  String get userActivationFailed => 'Failed to activate';

  @override
  String get currentManagers => 'Current Managers';

  @override
  String get noManagersAssigned => 'No managers assigned';

  @override
  String get removeManagerTitle => 'Remove Manager';

  @override
  String removeManagerConfirm(Object name) {
    return 'Remove $name as manager?';
  }

  @override
  String get addManager => 'Add Manager';

  @override
  String managerAdded(Object name) {
    return '$name added as manager';
  }

  @override
  String get managerAddFailed => 'Failed to add manager';

  @override
  String get noAdminPrivileges => 'You do not have admin privileges.';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get adminPanelDesc => 'Manage users, classes & data';

  @override
  String get management => 'Management';

  @override
  String get userManagementDesc => 'Activate, enable/disable users';

  @override
  String get classManagementDesc => 'Manage classes and managers';

  @override
  String get statistics => 'Statistics';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get resetAllData => 'Reset All Data';

  @override
  String get resetAllDataDesc => 'Delete all sessions and records';

  @override
  String get resetDataTitle => 'Reset Data?';

  @override
  String get resetDataConfirm =>
      'Are you sure you want to reset all data? This cannot be undone.';

  @override
  String get reset => 'Reset';

  @override
  String get classCreated => 'Class created successfully';

  @override
  String get classCreationError => 'Failed to create class';

  @override
  String get enterClassName => 'Enter class name';

  @override
  String get enterGrade => 'Enter grade';

  @override
  String get accountPendingActivation =>
      'Your account is awaiting admin activation';

  @override
  String get accountDenied =>
      'Your activation request was denied by the administrator';

  @override
  String get accountDisabled =>
      'Your account has been disabled by the administrator';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get registrationSuccessful => 'Registration Successful!';

  @override
  String get registrationSuccessfulDesc =>
      'Please wait for the administrator to activate your account';

  @override
  String get emailAlreadyExists => 'An account with this email already exists';

  @override
  String get createAccountToStart => 'Create your account to get started';

  @override
  String get contactAdminForActivation =>
      'Please contact the administrator to activate your account';

  @override
  String get abortActivation => 'Deny Activation';

  @override
  String get abortActivationConfirm =>
      'Are you sure you want to deny this user\'s activation request?';

  @override
  String get userActivationAborted => 'User activation denied';

  @override
  String get enableUser => 'Enable User';

  @override
  String get disableUser => 'Disable User';

  @override
  String get enableUserConfirm => 'Enable this user\'s access to the app?';

  @override
  String get disableUserConfirm =>
      'Disable this user\'s access? They will be logged out immediately.';

  @override
  String get userEnabled => 'User enabled successfully';

  @override
  String get userDisabled => 'User disabled successfully';

  @override
  String get deleteUser => 'Delete User';

  @override
  String get deleteUserConfirm =>
      'Are you sure you want to delete this user? This action cannot be undone.';

  @override
  String get userDeleted => 'User deleted successfully';

  @override
  String get abortedActivations => 'Denied Activations';

  @override
  String get noAbortedUsers => 'No denied activation requests';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get classManagers => 'Managers';

  @override
  String get disabled => 'Disabled';

  @override
  String get active => 'Active';

  @override
  String get pending => 'Pending';

  @override
  String get events => 'Events';

  @override
  String get alerts => 'Alerts';

  @override
  String get configuration => 'Configuration';

  @override
  String get notesNotificationDesc => 'Get notified when a note is added';
}
