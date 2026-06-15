import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_locale.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('km')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  bool get isKhmer => locale.languageCode == AppLocale.khmer.languageCode;

  String get appTitle => _text('appTitle');
  String get dashboard => _text('dashboard');
  String get pos => _text('pos');
  String get orders => _text('orders');
  String get products => _text('products');
  String get staff => _text('staff');
  String get attendance => _text('attendance');
  String get profile => _text('profile');
  String get more => _text('more');
  String get myAccount => _text('myAccount');
  String get managementAndAccount => _text('managementAndAccount');
  String get staffManagement => _text('staffManagement');
  String get staffManagementSubtitle => _text('staffManagementSubtitle');
  String get staffAttendance => _text('staffAttendance');
  String get staffAttendanceSubtitle => _text('staffAttendanceSubtitle');
  String get payrollSummary => _text('payrollSummary');
  String get payrollSummarySubtitle => _text('payrollSummarySubtitle');
  String get leaveManagement => _text('leaveManagement');
  String get leaveManagementSubtitle => _text('leaveManagementSubtitle');
  String get notifications => _text('notifications');
  String get notificationsSubtitle => _text('notificationsSubtitle');
  String get shopSettingsSubtitle => _text('shopSettingsSubtitle');
  String get staffDirectory => _text('staffDirectory');
  String get staffDirectorySubtitle => _text('staffDirectorySubtitle');
  String get attendanceMonitor => _text('attendanceMonitor');
  String get attendanceMonitorSubtitle => _text('attendanceMonitorSubtitle');
  String get myAttendance => _text('myAttendance');
  String get myAttendanceSubtitle => _text('myAttendanceSubtitle');
  String get myPayroll => _text('myPayroll');
  String get myPayrollSubtitle => _text('myPayrollSubtitle');
  String get myNotifications => _text('myNotifications');
  String get myNotificationsSubtitle => _text('myNotificationsSubtitle');
  String get appSettingsSubtitle => _text('appSettingsSubtitle');
  String get editProfile => _text('editProfile');
  String get language => _text('language');
  String get switchShop => _text('switchShop');
  String get signOut => _text('signOut');
  String get signOutTitle => _text('signOutTitle');
  String get signOutMessage => _text('signOutMessage');
  String get cancel => _text('cancel');
  String get save => _text('save');
  String get change => _text('change');
  String get changePassword => _text('changePassword');
  String get shopSettings => _text('shopSettings');
  String get appSettings => _text('appSettings');
  String get chooseLanguage => _text('chooseLanguage');
  String get chooseLanguageHint => _text('chooseLanguageHint');
  String get languageUpdated => _text('languageUpdated');
  String get fullName => _text('fullName');
  String get phoneNumber => _text('phoneNumber');
  String get currentPassword => _text('currentPassword');
  String get newPassword => _text('newPassword');
  String get confirmNewPassword => _text('confirmNewPassword');
  String get userNameFallback => _text('userNameFallback');
  String get noEmail => _text('noEmail');
  String get nameRequired => _text('nameRequired');
  String get currentPasswordRequired => _text('currentPasswordRequired');
  String get newPasswordRequired => _text('newPasswordRequired');
  String get passwordTooShort => _text('passwordTooShort');
  String get passwordsDoNotMatch => _text('passwordsDoNotMatch');
  String get profileUpdatedSuccess => _text('profileUpdatedSuccess');
  String get profileUpdateFailed => _text('profileUpdateFailed');
  String get passwordChangedSuccess => _text('passwordChangedSuccess');
  String get passwordChangeFailed => _text('passwordChangeFailed');
  String get shopDetails => _text('shopDetails');
  String get shopDetailsSubtitle => _text('shopDetailsSubtitle');
  String get selfAttendanceSettings => _text('selfAttendanceSettings');
  String get selfAttendanceSubtitle => _text('selfAttendanceSubtitle');
  String get shopName => _text('shopName');
  String get latitude => _text('latitude');
  String get longitude => _text('longitude');
  String get attendanceRadius => _text('attendanceRadius');
  String get qrSecretKey => _text('qrSecretKey');
  String get requiredField => _text('requiredField');
  String get managerSelfAttendance => _text('managerSelfAttendance');
  String get managerSelfAttendanceSubtitle =>
      _text('managerSelfAttendanceSubtitle');
  String get staffSelfAttendance => _text('staffSelfAttendance');
  String get staffSelfAttendanceSubtitle =>
      _text('staffSelfAttendanceSubtitle');
  String get selfAttendanceInfo => _text('selfAttendanceInfo');
  String get settingsSavedSuccess => _text('settingsSavedSuccess');

  String failedToSave(String message) =>
      isKhmer ? 'រក្សាទុកមិនបាន៖ $message' : 'Failed to save: $message';

  String raw(String value) {
    return _rawLocalizedValues[locale.languageCode]?[value] ??
        _rawLocalizedValues['en']?[value] ??
        value;
  }

  String _text(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key]!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'ERP Mobile',
      'dashboard': 'Dashboard',
      'pos': 'POS',
      'orders': 'Orders',
      'products': 'Products',
      'staff': 'Staff',
      'attendance': 'Attendance',
      'profile': 'Profile',
      'more': 'More',
      'myAccount': 'My Account',
      'managementAndAccount': 'Management & Account',
      'staffManagement': 'Staff Management',
      'staffManagementSubtitle':
          'Workforce directory and team member status.',
      'staffAttendance': 'Staff Attendance',
      'staffAttendanceSubtitle': 'Daily check-in activity and GPS logs.',
      'payrollSummary': 'Payroll Summary',
      'payrollSummarySubtitle':
          'Monthly compensation plans and payouts.',
      'leaveManagement': 'Leave Management',
      'leaveManagementSubtitle':
          'Track team leave requests and time-off.',
      'notifications': 'Notifications',
      'notificationsSubtitle':
          'System updates and business notifications.',
      'shopSettingsSubtitle':
          'Manage coordinates, radius, and business details.',
      'staffDirectory': 'Staff Directory',
      'staffDirectorySubtitle':
          'View your workforce directory and status.',
      'attendanceMonitor': 'Attendance Monitor',
      'attendanceMonitorSubtitle':
          'Monitor clock-in and out timestamps.',
      'myAttendance': 'My Attendance',
      'myAttendanceSubtitle':
          'Clock in, check out, and track shift history.',
      'myPayroll': 'My Payroll',
      'myPayrollSubtitle':
          'Review personal payslips and compensation.',
      'myNotifications': 'My Notifications',
      'myNotificationsSubtitle':
          'Check personal updates and system alerts.',
      'appSettingsSubtitle': 'Preferences and user configurations.',
      'editProfile': 'Edit Profile',
      'language': 'Language',
      'switchShop': 'Switch Shop',
      'signOut': 'Sign Out',
      'signOutTitle': 'Sign Out',
      'signOutMessage': 'Are you sure you want to sign out of your account?',
      'cancel': 'Cancel',
      'save': 'Save',
      'change': 'Change',
      'changePassword': 'Change Password',
      'shopSettings': 'Shop Settings',
      'appSettings': 'App Settings',
      'chooseLanguage': 'Choose language',
      'chooseLanguageHint': 'Pick the app language you want to use.',
      'languageUpdated': 'Language updated',
      'fullName': 'Full Name',
      'phoneNumber': 'Phone Number',
      'currentPassword': 'Current Password',
      'newPassword': 'New Password',
      'confirmNewPassword': 'Confirm New Password',
      'userNameFallback': 'User Name',
      'noEmail': 'No email',
      'nameRequired': 'Name cannot be empty',
      'currentPasswordRequired': 'Current password is required',
      'newPasswordRequired': 'New password is required',
      'passwordTooShort': 'Password must be at least 6 characters',
      'passwordsDoNotMatch': 'Passwords do not match',
      'profileUpdatedSuccess': 'Profile updated successfully!',
      'profileUpdateFailed': 'Failed to update profile',
      'passwordChangedSuccess': 'Password changed successfully!',
      'passwordChangeFailed': 'Failed to change password',
      'shopDetails': 'Shop Details',
      'shopDetailsSubtitle':
          'Basic shop information used for attendance tracking.',
      'selfAttendanceSettings': 'Self-Attendance Settings',
      'selfAttendanceSubtitle':
          'Allow employees to clock in without scanning a QR code. GPS location is still verified.',
      'shopName': 'Shop Name',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'attendanceRadius': 'Attendance Radius (meters)',
      'qrSecretKey': 'QR Secret Key',
      'requiredField': 'Required',
      'managerSelfAttendance': 'Manager Self-Attendance',
      'managerSelfAttendanceSubtitle':
          'Managers can clock in/out with just GPS verification (no QR code from owner needed).',
      'staffSelfAttendance': 'Staff Self-Attendance',
      'staffSelfAttendanceSubtitle':
          'Staff can clock in/out with GPS when manager is absent or on day off.',
      'selfAttendanceInfo':
          'Self-attendance still requires the employee to be within the shop\'s GPS radius. Only the QR code scanning step is bypassed.',
      'settingsSavedSuccess': 'Settings saved successfully!',
    },
    'km': {
      'appTitle': 'ERP ទូរស័ព្ទ',
      'dashboard': 'ផ្ទាំងគ្រប់គ្រង',
      'pos': 'លក់ទំនិញ',
      'orders': 'ការបញ្ជាទិញ',
      'products': 'ទំនិញ',
      'staff': 'បុគ្គលិក',
      'attendance': 'វត្តមាន',
      'profile': 'ប្រវត្តិរូប',
      'more': 'បន្ថែម',
      'myAccount': 'គណនីរបស់ខ្ញុំ',
      'managementAndAccount': 'ការគ្រប់គ្រង និង គណនី',
      'staffManagement': 'គ្រប់គ្រងបុគ្គលិក',
      'staffManagementSubtitle': 'បញ្ជីកម្លាំងការងារ និង ស្ថានភាពសមាជិកក្រុម។',
      'staffAttendance': 'វត្តមានបុគ្គលិក',
      'staffAttendanceSubtitle': 'សកម្មភាពចូលវត្តមានប្រចាំថ្ងៃ និង កំណត់ត្រា GPS។',
      'payrollSummary': 'សង្ខេបប្រាក់ខែ',
      'payrollSummarySubtitle': 'ផែនការប្រាក់ខែប្រចាំខែ និង ការទូទាត់។',
      'leaveManagement': 'គ្រប់គ្រងការឈប់សម្រាក',
      'leaveManagementSubtitle': 'តាមដានសំណើសុំឈប់សម្រាក និង ពេលសម្រាករបស់ក្រុម។',
      'notifications': 'ការជូនដំណឹង',
      'notificationsSubtitle': 'ព័ត៌មានថ្មីៗពីប្រព័ន្ធ និង អាជីវកម្ម។',
      'shopSettingsSubtitle': 'គ្រប់គ្រងទីតាំង កាំវង់ និង ព័ត៌មានអាជីវកម្ម។',
      'staffDirectory': 'បញ្ជីបុគ្គលិក',
      'staffDirectorySubtitle': 'មើលបញ្ជីកម្លាំងការងារ និង ស្ថានភាពបុគ្គលិក។',
      'attendanceMonitor': 'តាមដានវត្តមាន',
      'attendanceMonitorSubtitle': 'តាមដានម៉ោងចូល និង ចេញការងារ។',
      'myAttendance': 'វត្តមានរបស់ខ្ញុំ',
      'myAttendanceSubtitle': 'ចូលវត្តមាន ចេញវត្តមាន និង តាមដានប្រវត្តិវេនការងារ។',
      'myPayroll': 'ប្រាក់ខែរបស់ខ្ញុំ',
      'myPayrollSubtitle': 'ពិនិត្យស្លីបប្រាក់ខែ និង ប្រាក់សំណងផ្ទាល់ខ្លួន។',
      'myNotifications': 'ការជូនដំណឹងរបស់ខ្ញុំ',
      'myNotificationsSubtitle': 'ពិនិត្យព័ត៌មានថ្មីៗ និង សារពីប្រព័ន្ធ។',
      'appSettingsSubtitle': 'ចំណូលចិត្ត និង ការកំណត់របស់អ្នកប្រើ។',
      'editProfile': 'កែប្រវត្តិរូប',
      'language': 'ភាសា',
      'switchShop': 'ប្តូរហាង',
      'signOut': 'ចាកចេញ',
      'signOutTitle': 'ចាកចេញ',
      'signOutMessage': 'តើអ្នកប្រាកដថាចង់ចាកចេញពីគណនីនេះមែនទេ?',
      'cancel': 'បោះបង់',
      'save': 'រក្សាទុក',
      'change': 'ផ្លាស់ប្តូរ',
      'changePassword': 'ប្តូរពាក្យសម្ងាត់',
      'shopSettings': 'ការកំណត់ហាង',
      'appSettings': 'ការកំណត់កម្មវិធី',
      'chooseLanguage': 'ជ្រើសរើសភាសា',
      'chooseLanguageHint': 'ជ្រើសភាសាដែលអ្នកចង់ប្រើក្នុងកម្មវិធី។',
      'languageUpdated': 'បានប្តូរភាសា',
      'fullName': 'ឈ្មោះពេញ',
      'phoneNumber': 'លេខទូរស័ព្ទ',
      'currentPassword': 'ពាក្យសម្ងាត់បច្ចុប្បន្ន',
      'newPassword': 'ពាក្យសម្ងាត់ថ្មី',
      'confirmNewPassword': 'បញ្ជាក់ពាក្យសម្ងាត់ថ្មី',
      'userNameFallback': 'ឈ្មោះអ្នកប្រើ',
      'noEmail': 'មិនមានអ៊ីមែល',
      'nameRequired': 'សូមបញ្ចូលឈ្មោះ',
      'currentPasswordRequired': 'សូមបញ្ចូលពាក្យសម្ងាត់បច្ចុប្បន្ន',
      'newPasswordRequired': 'សូមបញ្ចូលពាក្យសម្ងាត់ថ្មី',
      'passwordTooShort': 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច 6 តួអក្សរ',
      'passwordsDoNotMatch': 'ពាក្យសម្ងាត់មិនដូចគ្នា',
      'profileUpdatedSuccess': 'បានកែប្រវត្តិរូបដោយជោគជ័យ!',
      'profileUpdateFailed': 'កែប្រវត្តិរូបមិនបានជោគជ័យ',
      'passwordChangedSuccess': 'បានប្តូរពាក្យសម្ងាត់ដោយជោគជ័យ!',
      'passwordChangeFailed': 'ប្តូរពាក្យសម្ងាត់មិនបានជោគជ័យ',
      'shopDetails': 'ព័ត៌មានហាង',
      'shopDetailsSubtitle': 'ព័ត៌មានមូលដ្ឋានរបស់ហាងសម្រាប់ការតាមដានវត្តមាន។',
      'selfAttendanceSettings': 'ការកំណត់វត្តមានដោយខ្លួនឯង',
      'selfAttendanceSubtitle':
          'អនុញ្ញាតឱ្យបុគ្គលិកចូលវត្តមានដោយមិនចាំបាច់ស្កេន QR Code។ ទីតាំង GPS នៅតែត្រូវបានផ្ទៀងផ្ទាត់។',
      'shopName': 'ឈ្មោះហាង',
      'latitude': 'រយៈទទឹង',
      'longitude': 'រយៈបណ្តោយ',
      'attendanceRadius': 'កាំវង់វត្តមាន (ម៉ែត្រ)',
      'qrSecretKey': 'លេខសម្ងាត់ QR',
      'requiredField': 'ត្រូវបំពេញ',
      'managerSelfAttendance': 'វត្តមានអ្នកគ្រប់គ្រងដោយខ្លួនឯង',
      'managerSelfAttendanceSubtitle':
          'អ្នកគ្រប់គ្រងអាចចូល និង ចេញវត្តមានដោយផ្ទៀងផ្ទាត់ GPS ប៉ុណ្ណោះ។',
      'staffSelfAttendance': 'វត្តមានបុគ្គលិកដោយខ្លួនឯង',
      'staffSelfAttendanceSubtitle':
          'បុគ្គលិកអាចចូល និង ចេញវត្តមានដោយ GPS នៅពេលអ្នកគ្រប់គ្រងអវត្តមាន។',
      'selfAttendanceInfo':
          'វត្តមានដោយខ្លួនឯងនៅតែតម្រូវឱ្យបុគ្គលិកស្ថិតក្នុងកាំវង់ GPS របស់ហាង។ គ្រាន់តែបិទជំហានស្កេន QR Code ប៉ុណ្ណោះ។',
      'settingsSavedSuccess': 'បានរក្សាទុកការកំណត់ដោយជោគជ័យ!',
    },
  };

  static const Map<String, Map<String, String>> _rawLocalizedValues = {
    'en': {},
    'km': {
      'Dashboard': 'ផ្ទាំងគ្រប់គ្រង',
      'POS': 'លក់ទំនិញ',
      'Operations': 'ប្រតិបត្តិការ',
      'More': 'បន្ថែម',
      'COMING SOON': 'នឹងមកដល់ឆាប់ៗ',
      'Go Back': 'ត្រឡប់ក្រោយ',
      'Something went wrong': 'មានបញ្ហាកើតឡើង',
      'Try Again': 'សាកម្តងទៀត',
      'Got it': 'យល់ព្រម',
      'Login Failed': 'ចូលប្រើមិនបាន',
      'Product Catalog': 'កាតាឡុកទំនិញ',
      'Supplier Management': 'គ្រប់គ្រងអ្នកផ្គត់ផ្គង់',
      'Inventory': 'ស្តុកទំនិញ',
      'Track stock counts and receive low stock alerts.':
          'តាមដានបរិមាណស្តុក និង ទទួលការជូនដំណឹងពេលស្តុកជិតអស់។',
      'Manage items, pricing, and category catalog.':
          'គ្រប់គ្រងទំនិញ តម្លៃ និង ប្រភេទទំនិញ។',
      'Suppliers': 'អ្នកផ្គត់ផ្គង់',
      'Directory of suppliers and vendor records.':
          'បញ្ជីអ្នកផ្គត់ផ្គង់ និង កំណត់ត្រាអ្នកលក់។',
      'Purchase Orders': 'ការបញ្ជាទិញស្តុក',
      'Raise, monitor, and receive restocking orders.':
          'បង្កើត តាមដាន និង ទទួលការបញ្ជាទិញស្តុកឡើងវិញ។',
      'Reports': 'របាយការណ៍',
      'View sales trends, revenue summary, and analytics.':
          'មើលនិន្នាការលក់ សង្ខេបចំណូល និង ការវិភាគទិន្នន័យ។',
      'View sales orders and transaction history.':
          'មើលការបញ្ជាទិញលក់ និង ប្រវត្តិប្រតិបត្តិការ។',
      'Expenses': 'ចំណាយ',
      'Log and track operating costs and cash outflows.':
          'កត់ត្រា និង តាមដានចំណាយប្រតិបត្តិការ និង លំហូរសាច់ប្រាក់ចេញ។',
      'Operations Hub': 'មជ្ឈមណ្ឌលប្រតិបត្តិការ',
      'ERP Business Tools': 'ឧបករណ៍អាជីវកម្ម ERP',
      'Manage items, track stock, review vendor directories, and analyze financial reports.':
          'គ្រប់គ្រងទំនិញ តាមដានស្តុក ពិនិត្យបញ្ជីអ្នកផ្គត់ផ្គង់ និង វិភាគរបាយការណ៍ហិរញ្ញវត្ថុ។',
      'Business Reports': 'របាយការណ៍អាជីវកម្ម',
      'Expense Management': 'គ្រប់គ្រងចំណាយ',
      'Leave Management': 'គ្រប់គ្រងការឈប់សម្រាក',
      'Notifications': 'ការជូនដំណឹង',
      'Payroll Management': 'គ្រប់គ្រងប្រាក់ខែ',
      'Inventory Tracking': 'តាមដានស្តុក',
      'This feature will be available in a future release.':
          'មុខងារនេះនឹងមាននៅក្នុងការចេញផ្សាយពេលក្រោយ។',
      'Orders': 'ការបញ្ជាទិញ',
      'Order Module - Order List Here': 'ម៉ូឌុលការបញ្ជាទិញ - បញ្ជីការបញ្ជាទិញនៅទីនេះ',
      'Profile': 'ប្រវត្តិរូប',
      'Sign Out': 'ចាកចេញ',
      'Are you sure you want to sign out?': 'តើអ្នកប្រាកដថាចង់ចាកចេញមែនទេ?',
      'User Information': 'ព័ត៌មានអ្នកប្រើ',
      'Account Information': 'ព័ត៌មានគណនី',
      'Role': 'តួនាទី',
      'Email': 'អ៊ីមែល',
      'Phone': 'ទូរស័ព្ទ',
      'Quick Stats': 'ស្ថិតិសង្ខេប',
      'Staff Attendance Summary': 'សង្ខេបវត្តមានបុគ្គលិក',
      'Recent Activity': 'សកម្មភាពថ្មីៗ',
      'View All': 'មើលទាំងអស់',
      'Staff Check-in': 'បុគ្គលិកចូលវត្តមាន',
      'Today\'s Shift Status': 'ស្ថានភាពវេនការងារថ្ងៃនេះ',
      'Todayâ€™s Shift Status': 'ស្ថានភាពវេនការងារថ្ងៃនេះ',
      'Attendance': 'វត្តមាន',
      'Present': 'មានវត្តមាន',
      'Late': 'យឺត',
      'Absent': 'អវត្តមាន',
      'Orders Today': 'ការបញ្ជាទិញថ្ងៃនេះ',
      'Revenue': 'ចំណូល',
      'Avg. Value': 'តម្លៃមធ្យម',
      'Refunds': 'ការសងប្រាក់',
      'Good Morning': 'អរុណសួស្តី',
      'Good Afternoon': 'ទិវាសួស្តី',
      'Good Evening': 'សាយណ្ហសួស្តី',
      'Create Account': 'បង្កើតគណនី',
      'Creating account...': 'កំពុងបង្កើតគណនី...',
      'Fill in your details to get started': 'បំពេញព័ត៌មានរបស់អ្នកដើម្បីចាប់ផ្តើម',
      'Please agree to the terms and conditions':
          'សូមយល់ព្រមលក្ខខណ្ឌ និង ខទូទៅសិន',
      'Full Name': 'ឈ្មោះពេញ',
      'Enter your full name': 'បញ្ចូលឈ្មោះពេញរបស់អ្នក',
      'Phone Number': 'លេខទូរស័ព្ទ',
      'Phone (Optional)': 'ទូរស័ព្ទ (ជម្រើស)',
      'Enter your phone number': 'បញ្ចូលលេខទូរស័ព្ទរបស់អ្នក',
      'Password': 'ពាក្យសម្ងាត់',
      'Confirm Password': 'បញ្ជាក់ពាក្យសម្ងាត់',
      'Create a password': 'បង្កើតពាក្យសម្ងាត់',
      'Re-enter your password': 'បញ្ចូលពាក្យសម្ងាត់ម្តងទៀត',
      'Register': 'ចុះឈ្មោះ',
      'Already have an account?': 'មានគណនីរួចហើយឬនៅ?',
      'Login': 'ចូលប្រើ',
      'Staff': 'បុគ្គលិក',
      'Add Staff': 'បន្ថែមបុគ្គលិក',
      'Add New Staff': 'បន្ថែមបុគ្គលិកថ្មី',
      'Cancel': 'បោះបង់',
      'Save': 'រក្សាទុក',
      'Save Changes': 'រក្សាទុកការកែប្រែ',
      'Monthly': 'ប្រចាំខែ',
      'Daily': 'ប្រចាំថ្ងៃ',
      'Error': 'កំហុស',
      'Success!': 'ជោគជ័យ!',
      'Signing in...': 'កំពុងចូលប្រើ...',
      'Welcome Back!': 'សូមស្វាគមន៍មកវិញ!',
      'Sign in with your manager or employee account':
          'ចូលប្រើដោយគណនីអ្នកគ្រប់គ្រង ឬ បុគ្គលិករបស់អ្នក',
      'Enter your email': 'បញ្ចូលអ៊ីមែលរបស់អ្នក',
      'Enter your password': 'បញ្ចូលពាក្យសម្ងាត់របស់អ្នក',
      'This app currently supports MANAGER and EMPLOYEE accounts only.':
          'កម្មវិធីនេះគាំទ្រតែគណនី MANAGER និង EMPLOYEE ប៉ុណ្ណោះ។',
      'Sign In': 'ចូលប្រើ',
      'English': 'អង់គ្លេស',
      'Khmer': 'ខ្មែរ',
      'Choose language': 'ជ្រើសរើសភាសា',
      'Today\'s Gross Sales': 'ការលក់សរុបថ្ងៃនេះ',
      '2 items · \$45.00': '2 មុខទំនិញ · \$45.00',
      '2 items Â· \$45.00': '2 មុខទំនិញ · \$45.00',
      '1 item · \$12.50': '1 មុខទំនិញ · \$12.50',
      '1 item Â· \$12.50': '1 មុខទំនិញ · \$12.50',
      'Just now': 'មុននេះបន្តិច',
      '15m ago': '15 នាទីមុន',
      '1h ago': '1 ម៉ោងមុន',
      'Order #1042': 'ការបញ្ជាទិញ #1042',
      'Order #1041': 'ការបញ្ជាទិញ #1041',
      'Sok Dara arrived': 'សុខ ដារា បានមកដល់',
      'Products': 'ទំនិញ',
      '5 Present': '5 នាក់មានវត្តមាន',
      '1 Late': '1 នាក់យឺត',
      '0 Absent': '0 នាក់អវត្តមាន',
      'Welcome back,': 'សូមស្វាគមន៍មកវិញ,',
      'Shift Active': 'វេនកំពុងដំណើរការ',
      'Clocked in at 08:30 AM': 'បានចូលម៉ោងនៅ 08:30 ព្រឹក',
      'ON-SITE': 'នៅកន្លែងការងារ',
      '22 Days': '22 ថ្ងៃ',
      'Present this month': 'មានវត្តមានក្នុងខែនេះ',
      'Est. Earnings': 'ប្រាក់ចំណូលប៉ាន់ស្មាន',
      'Payday: Jun 30': 'ថ្ងៃបើកប្រាក់ខែ៖ 30 មិថុនា',
      'Recent Notifications': 'ការជូនដំណឹងថ្មីៗ',
      'New Policy Update': 'ការអាប់ដេតគោលការណ៍ថ្មី',
      'New check-in radius updated to 50m.':
          'កាំវង់ចូលវត្តមានថ្មី ត្រូវបានកែប្រែទៅ 50 ម៉ែត្រ។',
      '2h ago': '2 ម៉ោងមុន',
      'Payslip Available': 'ស្លីបប្រាក់ខែអាចមើលបាន',
      'Your payslip for May is now ready to view.':
          'ស្លីបប្រាក់ខែសម្រាប់ខែឧសភា អាចមើលបានហើយ។',
      '1d ago': '1 ថ្ងៃមុន',
      'Must be at least 8 characters with uppercase, lowercase, and number':
          'ត្រូវមានយ៉ាងតិច 8 តួ និង មានអក្សរធំ អក្សរតូច និង លេខ',
      'Terms of Service': 'លក្ខខណ្ឌសេវាកម្ម',
      ' and ': ' និង ',
      'Privacy Policy': 'គោលការណ៍ឯកជនភាព',
      'Point of Sale': 'ចំណុចលក់',
      'POS Module - Products Grid Here': 'ម៉ូឌុល POS - ផ្ទាំងទំនិញនៅទីនេះ',
      'N/A': 'មិនមាន',
      'You have clocked in successfully.': 'អ្នកបានចូលវត្តមានដោយជោគជ័យ។',
      'Check-in Failed': 'ចូលវត្តមានមិនបាន',
      'Scan Attendance QR Code': 'ស្កេន QR កូដវត្តមាន',
      'Align the shop QR code within the frame to check in automatically':
          'ដាក់ QR កូដរបស់ហាងឱ្យស្ថិតក្នុងស៊ុម ដើម្បីចូលវត្តមានដោយស្វ័យប្រវត្តិ។',
      'Checking In...': 'កំពុងចូលវត្តមាន...',
      'Manual Correction': 'កែតម្រូវដោយដៃ',
      'Correct timestamps or status below. Doing so will flag this log as "Manual" and record your user audit trail.':
          'កែតម្រូវម៉ោង ឬ ស្ថានភាពខាងក្រោម។ ការធ្វើបែបនេះនឹងសម្គាល់កំណត់ត្រានេះថា "ដោយដៃ" និងរក្សាទុកប្រវត្តិអ្នកកែប្រែ។',
      'Attendance Status': 'ស្ថានភាពវត្តមាន',
      'Check-In Time (HH:mm)': 'ម៉ោងចូល (HH:mm)',
      'Check-Out Time (HH:mm)': 'ម៉ោងចេញ (HH:mm)',
      'Reason / Note': 'មូលហេតុ / កំណត់សម្គាល់',
      'Enter reason for this correction': 'បញ្ចូលមូលហេតុសម្រាប់ការកែតម្រូវនេះ',
      'Correction Applied!': 'បានអនុវត្តការកែតម្រូវ!',
      'Attendance record updated and audit trail saved.':
          'កំណត់ត្រាវត្តមានត្រូវបានធ្វើបច្ចុប្បន្នភាព និង បានរក្សាទុកប្រវត្តិត្រួតពិនិត្យ។',
      'Save Correction': 'រក្សាទុកការកែតម្រូវ',
      'Staff Member': 'បុគ្គលិក',
      'Employee': 'បុគ្គលិក',
      'EMP-N/A': 'EMP-មិនមាន',
      'Attendance Detail': 'ព័ត៌មានលម្អិតវត្តមាន',
      'No manual corrections have been recorded for this log. The record matches initial device timestamps.':
          'មិនមានការកែតម្រូវដោយដៃសម្រាប់កំណត់ត្រានេះទេ។ កំណត់ត្រានេះត្រូវគ្នានឹងម៉ោងដើមពីឧបករណ៍។',
      'No staff yet': 'មិនទាន់មានបុគ្គលិកទេ',
      'Add your first team member to get started.':
          'បន្ថែមសមាជិកក្រុមដំបូងរបស់អ្នកដើម្បីចាប់ផ្តើម។',
      'Active': 'សកម្ម',
      'Inactive': 'អសកម្ម',
      'Edit Staff': 'កែប្រែបុគ្គលិក',
      'Edit Attendance': 'កែប្រែវត្តមាន',
      'Deactivate': 'បិទសកម្មភាព',
      'Activate': 'បើកសកម្មភាព',
      'Deactivate Staff': 'បិទសកម្មភាពបុគ្គលិក',
      'Activate Staff': 'បើកសកម្មភាពបុគ្គលិក',
      'Are you sure you want to deactivate': 'តើអ្នកប្រាកដថាចង់បិទសកម្មភាព',
      'They will no longer be able to log in.':
          'ពួកគេនឹងមិនអាចចូលប្រើបានទៀតទេ។',
      'Are you sure you want to activate': 'តើអ្នកប្រាកដថាចង់បើកសកម្មភាព',
      'They will be allowed to log in.':
          'ពួកគេនឹងអាចចូលប្រើបាន។',
      'Add Custom Position': 'បន្ថែមតួនាទីផ្ទាល់ខ្លួន',
      'Position Name': 'ឈ្មោះតួនាទី',
      'Add': 'បន្ថែម',
      'Add Custom Department': 'បន្ថែមផ្នែកផ្ទាល់ខ្លួន',
      'Department Name': 'ឈ្មោះផ្នែក',
      'Add Shift Template': 'បន្ថែមគំរូវេនការងារ',
      'You have self-clocked in successfully.':
          'អ្នកបានចូលវត្តមានដោយខ្លួនឯងដោយជោគជ័យ។',
      'Your Shift:': 'វេនរបស់អ្នក៖',
      'Standard': 'ស្តង់ដារ',
      'Current Lateness Status:': 'ស្ថានភាពការយឺតបច្ចុប្បន្ន៖',
      'LATE (Check-in now)': 'យឺត (ចូលវត្តមានឥឡូវនេះ)',
      'ON-TIME': 'ទាន់ពេល',
      'Attendance Actions': 'សកម្មភាពវត្តមាន',
      'Scan QR': 'ស្កេន QR',
      'Check Out': 'ចេញវត្តមាន',
      'Self Clock In (GPS Only)': 'ចូលវត្តមានដោយខ្លួនឯង (GPS ប៉ុណ្ណោះ)',
      'My Recent Shifts': 'វេនថ្មីៗរបស់ខ្ញុំ',
      'No shifts recorded yet': 'មិនទាន់មានកំណត់ត្រាវេនទេ',
      'In:': 'ចូល៖',
      'Out:': 'ចេញ៖',
      'Shift:': 'វេន៖',
      'Staff Added Successfully': 'បានបន្ថែមបុគ្គលិកដោយជោគជ័យ',
      'Please share these login credentials with the employee:':
          'សូមចែករំលែកព័ត៌មានចូលប្រើទាំងនេះជាមួយបុគ្គលិក៖',
      'Copy & Done': 'ចម្លង និង រួចរាល់',
      'Credentials copied to clipboard!': 'បានចម្លងព័ត៌មានចូលប្រើទៅកាន់ក្តារចម្លង!',
      'Loading metadata & onboarding staff...':
          'កំពុងផ្ទុកទិន្នន័យ និង បង្កើតបុគ្គលិក...',
      'Create Staff Account': 'បង្កើតគណនីបុគ្គលិក',
      'Staff record updated successfully!':
          'បានធ្វើបច្ចុប្បន្នភាពកំណត់ត្រាបុគ្គលិកដោយជោគជ័យ!',
      'Shift Name (e.g. Morning, Afternoon)':
          'ឈ្មោះវេន (ឧ. ព្រឹក, រសៀល)',
      'Start Time': 'ម៉ោងចាប់ផ្តើម',
      'End Time': 'ម៉ោងបញ្ចប់',
      'Add Template': 'បន្ថែមគំរូ',
      'Edit': 'កែប្រែ',
      'Login Authorization': 'សិទ្ធិចូលប្រើ',
      'Active (Allowed to log in)': 'សកម្ម (អនុញ្ញាតឱ្យចូលប្រើ)',
      'Inactive (Access Blocked)': 'អសកម្ម (បានបិទការចូលប្រើ)',
      'Salary Type': 'ប្រភេទប្រាក់ខែ',
      'Attendance saved successfully.': 'បានរក្សាទុកវត្តមានដោយជោគជ័យ។',
      'e.g. 08:30': 'ឧ. 08:30',
      'e.g. 17:30': 'ឧ. 17:30',
      'Enter note or adjustment reason': 'បញ្ចូលកំណត់សម្គាល់ ឬ មូលហេតុនៃការកែតម្រូវ',
      'Note: An attendance record already exists for this date. Saving will overwrite the record.':
          'ចំណាំ៖ មានកំណត់ត្រាវត្តមានសម្រាប់កាលបរិច្ឆេទនេះរួចហើយ។ ការរក្សាទុកនឹងសរសេរជាន់លើកំណត់ត្រាចាស់។',
      'Note: No record exists for this date. Saving will create a new manual log.':
          'ចំណាំ៖ មិនទាន់មានកំណត់ត្រាសម្រាប់កាលបរិច្ឆេទនេះទេ។ ការរក្សាទុកនឹងបង្កើតកំណត់ត្រាដោយដៃថ្មីមួយ។',
      'Personal Information': 'ព័ត៌មានផ្ទាល់ខ្លួន',
      'Required': 'ត្រូវបំពេញ',
      'Email Address': 'អាសយដ្ឋានអ៊ីមែល',
      'Phone Number (Optional)': 'លេខទូរស័ព្ទ (ជម្រើស)',
      'Hire Date': 'ថ្ងៃចូលបម្រើការងារ',
      'Work & Scheduling Info': 'ព័ត៌មានការងារ និង កាលវិភាគ',
      'Assign Shift': 'កំណត់វេន',
      'Please assign a shift': 'សូមកំណត់វេនមួយ',
      'Add Custom Shift Template': 'បន្ថែមគំរូវេនផ្ទាល់ខ្លួន',
      'Shift Start Time': 'ម៉ោងចាប់ផ្តើមវេន',
      'Shift End Time': 'ម៉ោងបញ្ចប់វេន',
      'Position': 'តួនាទី',
      'Department': 'ផ្នែក',
      'Default Settings (Options for Managers)':
          'ការកំណត់លំនាំដើម (ជម្រើសសម្រាប់អ្នកគ្រប់គ្រង)',
      'Select which positions and departments your managers are allowed to assign to new staff:':
          'ជ្រើសរើសតួនាទី និង ផ្នែកដែលអ្នកគ្រប់គ្រងរបស់អ្នកអាចកំណត់ឱ្យបុគ្គលិកថ្មីបាន៖',
      'Allowed Positions:': 'តួនាទីដែលអនុញ្ញាត៖',
      'Allowed Departments:': 'ផ្នែកដែលអនុញ្ញាត៖',
      'Salary Details': 'ព័ត៌មានប្រាក់ខែ',
      'Base Salary': 'ប្រាក់ខែមូលដ្ឋាន',
      'Invalid amount': 'ចំនួនទឹកប្រាក់មិនត្រឹមត្រូវ',
      'You have clocked out successfully.': 'អ្នកបានចេញវត្តមានដោយជោគជ័យ។',
      'Pin Current GPS': 'កំណត់ GPS បច្ចុប្បន្ន',
      'Paste Maps Link': 'បិទភ្ជាប់តំណផែនទី',
      'Tap to enlarge': 'ចុចដើម្បីពង្រីក',
      'Staff Attendance Monitor': 'តាមដានវត្តមានបុគ្គលិក',
      'No attendance records found today': 'មិនមានកំណត់ត្រាវត្តមានសម្រាប់ថ្ងៃនេះទេ',
      'Paste Google Maps Link': 'បិទភ្ជាប់តំណ Google Maps',
      'https://maps.app.goo.gl/...': 'https://maps.app.goo.gl/...',
      'Location Updated!': 'បានធ្វើបច្ចុប្បន្នភាពទីតាំង!',
      'Successfully updated shop to:': 'បានធ្វើបច្ចុប្បន្នភាពទីតាំងហាងទៅ៖',
      'Confirm': 'បញ្ជាក់',
      'Shop Location Pinned!': 'បានកំណត់ទីតាំងហាង!',
      'Check-In': 'ចូលវត្តមាន',
      'Check-Out': 'ចេញវត្តមាន',
      'Reason:': 'មូលហេតុ៖',
      'Failed to customize shift timing:': 'មិនអាចកែតម្រូវម៉ោងវេនបាន៖',
      'Assigned Shift Duration': 'រយៈពេលវេនដែលបានកំណត់',
      'Error loading record:': 'មានបញ្ហាក្នុងការផ្ទុកកំណត់ត្រា៖',
      'Email is required': 'សូមបញ្ចូលអ៊ីមែល',
      'Please enter a valid email address': 'សូមបញ្ចូលអាសយដ្ឋានអ៊ីមែលដែលត្រឹមត្រូវ',
      'Password is required': 'សូមបញ្ចូលពាក្យសម្ងាត់',
      'Password must be at least 8 characters': 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច 8 តួអក្សរ',
      'Password must contain at least one uppercase letter':
          'ពាក្យសម្ងាត់ត្រូវមានអក្សរធំយ៉ាងតិច 1 តួ',
      'Password must contain at least one lowercase letter':
          'ពាក្យសម្ងាត់ត្រូវមានអក្សរតូចយ៉ាងតិច 1 តួ',
      'Password must contain at least one number':
          'ពាក្យសម្ងាត់ត្រូវមានលេខយ៉ាងតិច 1 តួ',
      'Password must be at least 6 characters': 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច 6 តួអក្សរ',
      'Name is required': 'សូមបញ្ចូលឈ្មោះ',
      'Name must be at least 2 characters': 'ឈ្មោះត្រូវមានយ៉ាងតិច 2 តួអក្សរ',
      'Name must not exceed 50 characters': 'ឈ្មោះមិនត្រូវលើស 50 តួអក្សរ',
      'Phone number is required': 'សូមបញ្ចូលលេខទូរស័ព្ទ',
      'Please enter a valid phone number': 'សូមបញ្ចូលលេខទូរស័ព្ទដែលត្រឹមត្រូវ',
      'Please confirm your password': 'សូមបញ្ជាក់ពាក្យសម្ងាត់របស់អ្នក',
      'Passwords do not match': 'ពាក្យសម្ងាត់មិនដូចគ្នា',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'km'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String value) => l10n.raw(value);
}
