// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wadeea';

  @override
  String get churchName =>
      'Church of Martyr Rafqa and Her Children in Al-Qanater Al-Khayriya';

  @override
  String get loginVerse =>
      'اِحْفَظِ الْوَدِيعَةَ الصَّالِحَةَ بِالرُّوحِ الْقُدُسِ السَّاكِنِ فِينَا. (2 تي 1: 14).';

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
  String get waitingForClassAssignment => 'Waiting for class assignment';

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
  String get serverTimeout =>
      'Server connection timed out. Please check your internet or try again.';

  @override
  String get rename => 'Rename';

  @override
  String get hi => 'Hi';

  @override
  String get user => 'User';

  @override
  String get search => 'Search';

  @override
  String get call => 'Call';

  @override
  String get phone => 'Phone';

  @override
  String get noPhone => 'No Phone';

  @override
  String get phoneNumberCopied => 'Phone number copied';

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
  String get classNameHint => 'e.g. Primary 3';

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
  String get tomorrow => 'Tomorrow';

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
  String get noAttendanceSessionsYet => 'No attendance sessions yet';

  @override
  String get tapBelowToTakeAttendance => 'Tap below to take attendance';

  @override
  String get addStudentsFirst => 'Add students first';

  @override
  String get addStudentsFirstToTakeAttendance =>
      'Add students first to take attendance';

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
  String get unknownClass => 'Unknown class';

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
  String removeManagerConfirmation(Object name) {
    return 'Are you sure you want to remove $name as a manager from this class?';
  }

  @override
  String addManagerConfirmation(Object name) {
    return 'Are you sure you want to add $name as a manager for this class?';
  }

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
  String get whatsappMessageHint => 'Hello [firstname], how are you?';

  @override
  String get whatsappDefaultTemplate => 'إزيك يا [firstname]';

  @override
  String get notificationSettingsDesc => 'Manage push notifications';

  @override
  String get notesNotification => 'Notes';

  @override
  String get notesNotificationDesc => 'Get notified when a note is added';

  @override
  String get attendanceNotification => 'Attendance';

  @override
  String get attendanceNotificationDesc =>
      'Get notified when attendance is recorded';

  @override
  String get birthdayNotification => 'Birthday Reminders';

  @override
  String get birthdayNotificationDesc => 'Get reminders for student birthdays';

  @override
  String get inactiveNotification => 'Inactive Students';

  @override
  String get inactiveNotificationDesc =>
      'Alert when a student becomes inactive';

  @override
  String get newUserNotification => 'New Registrations';

  @override
  String get newUserNotificationDesc => 'Notify when a new user registers';

  @override
  String get inactiveThresholdDesc =>
      'Threshold to consider a student inactive';

  @override
  String get birthdayReminderDays => 'Days before birthday';

  @override
  String get birthdayReminderDaysDesc =>
      'How many days before to send reminder';

  @override
  String get sameDay => 'Same day';

  @override
  String daysBefore(Object count) {
    return '$count days before';
  }

  @override
  String get tapToChangeTime => 'Tap to change time';

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
  String get appearance => 'Appearance';

  @override
  String get preferences => 'Preferences';

  @override
  String get about => 'About';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get resetAllData => 'Synchronize with the server';

  @override
  String get resetAllDataDesc => 'Sync all sessions and records';

  @override
  String get resetDataTitle => 'Sync Data?';

  @override
  String get resetDataConfirm =>
      'Are you sure you want to synchronize all data?';

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
  String get accountDeniedDesc =>
      'Your activation request was denied. If you believe this was a mistake, please contact the administrator for assistance.';

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
  String get userEnabled => 'User enabled!';

  @override
  String get userDisabled => 'User disabled.';

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
  String get viewDeniedUsersDesc =>
      'View and manage users whose activation was denied';

  @override
  String get reactivate => 'Reactivate';

  @override
  String reactivateConfirmation(Object name) {
    return 'Are you sure you want to reactivate $name? They will be able to log in again.';
  }

  @override
  String get deny => 'Deny';

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
  String get systemThemeDesc => 'Follow device settings';

  @override
  String get lightThemeDesc => 'Bright appearance';

  @override
  String get darkThemeDesc => 'Dark appearance';

  @override
  String get englishLanguageDesc => 'English language';

  @override
  String get arabicLanguageDesc => 'Arabic language';

  @override
  String get activityNotifications => 'Activity notifications';

  @override
  String get importantWarnings => 'Important warnings';

  @override
  String get customizeBehavior => 'Customize behavior';

  @override
  String get manage => 'Manage';

  @override
  String get good => 'Good';

  @override
  String get average => 'Average';

  @override
  String get poor => 'Poor';

  @override
  String get manageClassManagers => 'Manage Managers';

  @override
  String classManagersDescription(Object className) {
    return 'Managers for $className';
  }

  @override
  String get enabled => 'Enabled';

  @override
  String get accountPendingActivationDesc =>
      'Your account has been created successfully but is waiting for administrator approval. You will be notified once your account is active.';

  @override
  String removingManager(Object name) {
    return 'Removing $name...';
  }

  @override
  String addingManager(Object name) {
    return 'Adding $name...';
  }

  @override
  String get availableUsers => 'Available Users';

  @override
  String get serverConnectionError =>
      'Cannot connect to server. Please check your internet connection.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get cannotConnect => 'Cannot Connect';

  @override
  String get somethingWentWrong => 'Something Went Wrong';

  @override
  String get autoRetrying => 'Auto-retrying...';

  @override
  String get willAutoRetry => 'Will auto-retry when connected';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get unauthorized => 'Unauthorized. Please log in again.';

  @override
  String get actionFailedCheckConnection =>
      'Action failed. Check your internet connection.';

  @override
  String get managerAssigned => 'Manager assigned!';

  @override
  String get managerRemoved => 'Manager removed.';

  @override
  String get loadingAdminPanel => 'Loading Admin Panel...';

  @override
  String get loadingClassManagers => 'Loading class managers...';

  @override
  String enableUserConfirmation(Object name) {
    return 'Are you sure you want to enable \"$name\"?';
  }

  @override
  String disableUserConfirmation(Object name) {
    return 'Are you sure you want to disable \"$name\"?';
  }

  @override
  String get enable => 'Enable';

  @override
  String get disable => 'Disable';

  @override
  String get noStudentsYet => 'No students yet';

  @override
  String get tapAddStudentsAbove => 'Tap the + button above to add students';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get emailOrPhone => 'Email or Phone';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneHint => 'Enter your phone number';

  @override
  String get phoneAlreadyExists =>
      'An account with this phone number already exists';

  @override
  String get emailNotConfirmed => 'Please confirm your email before logging in';

  @override
  String get checkYourEmail => 'Check Your Email';

  @override
  String get confirmEmailDescription =>
      'We\'ve sent a confirmation link to your email. Please click it to activate your account.';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get emailResent => 'Confirmation email resent';

  @override
  String get goBackToLogin => 'Go back to Login';

  @override
  String get forgotPasswordTitle => 'Recover Password';

  @override
  String get forgotPasswordSubtitle =>
      'Choose how you want to recover your password';

  @override
  String get recoverViaEmail => 'Recover via Email';

  @override
  String get recoverViaPhone => 'Recover via Phone';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get sendOTP => 'Send OTP';

  @override
  String get resetLinkSent => 'Reset link sent successfully';

  @override
  String get enterNewPassword => 'Enter New Password';

  @override
  String get newPasswordHint => 'Enter at least 6 characters';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get resetPasswordAction => 'Reset Password';

  @override
  String get passwordResetSuccess => 'Password reset successfully';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get pleaseEnterOtp => 'Please enter the OTP code';

  @override
  String get otpCode => 'OTP Code';

  @override
  String get confirm => 'Confirm';

  @override
  String get emailConfirmedSuccess => 'Email confirmed successfully!';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get enterOtpAndNewPassword =>
      'Enter the OTP code sent to you and your new password.';

  @override
  String get newPassword => 'New Password';

  @override
  String get atLeast8Chars => 'At least 8 characters';

  @override
  String get atLeast1Upper => 'At least 1 uppercase letter';

  @override
  String get atLeast1Lower => 'At least 1 lowercase letter';

  @override
  String get atLeast1Digit => 'At least 1 number';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get invalidName => 'Name must be at least 2 characters';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get phoneNumberTooShort => 'Phone number is too short';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get verify => 'Verify';

  @override
  String get enterCode => 'Enter Code';

  @override
  String get enterCodeDesc => 'Enter the verification code sent to your email';

  @override
  String get resendConfirmation => 'Resend Confirmation';

  @override
  String get invalidToken => 'Invalid code';

  @override
  String get expiredToken => 'Expired code';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get continueAction => 'Continue';

  @override
  String get changeEmail => 'Change Email';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get googleSignIn => 'Google';

  @override
  String get googleSignInAborted => 'Sign in aborted by user';

  @override
  String get invalidOtp => 'Invalid verification code';

  @override
  String get noSessionsYet => 'No sessions yet';

  @override
  String get showAll => 'Show All';

  @override
  String get atRiskOnly => 'At Risk Only';

  @override
  String get assignManagers => 'Assign Managers';

  @override
  String get assignManagersCaption =>
      'Search and select users to manage this class';

  @override
  String deleteClassConfirmation(Object className) {
    return 'Delete $className?';
  }
}
