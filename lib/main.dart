import 'dart:async';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'collections_provider.dart';
import 'collections_repository.dart';

// --- МОДЕЛІ ДАНИХ ---

class CollectorItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final DateTime purchaseDate;
  final String condition;

  const CollectorItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.purchaseDate,
    required this.condition,
  });

  factory CollectorItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CollectorItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      condition: data['condition'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'condition': condition,
    };
  }
}

class Collection {
  final String id;
  final String name;
  final int iconCode;
  final List<CollectorItem> items;

  const Collection({
    required this.id,
    required this.name,
    required this.iconCode,
    this.items = const [],
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  factory Collection.fromFirestore(DocumentSnapshot doc, [List<CollectorItem>? items]) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Collection(
      id: doc.id,
      name: data['name'] ?? '',
      iconCode: data['iconCode'] ?? 58336,
      items: items ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCode': iconCode,
    };
  }
}

// --- СЕРВІСНІ КЛАСИ ---

class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    return AppStrings(AppState.of(context).locale);
  }

  static const Map<String, Map<String, String>> _values = {
    'uk': {
      'app_name': 'CollectorHub',
      'login_credential': 'Електронна пошта',
      'password': 'Пароль',
      'login': 'Увійти',
      'login_error': 'Помилка входу.',
      'no_account': 'Немає акаунту? Зареєструватися',
      'create_account_title': 'Створення акаунту',
      'email': 'Електронна пошта',
      'confirm_password': 'Підтвердіть пароль',
      'register': 'Зареєструватися',
      'registration_error': 'Помилка реєстрації.',
      'password_mismatch': 'Паролі не співпадають',
      'have_account': 'Вже є акаунт? Увійти',
      'collections': 'Колекції',
      'profile': 'Профіль',
      'my_collections': 'Мої колекції',
      'items_count': 'Предметів',
      'add_new_item': 'Додати новий предмет',
      'sort_by': 'Сортувати за',
      'sort_name': 'за Назвою',
      'sort_count': 'за Кількістю',
      'item_details': 'Деталі предмету',
      'settings': 'Налаштування',
      'logout': 'Вийти',
      'dark_theme': 'Темна тема',
      'test_crash': 'Тестувати Crashlytics',
      'field_required': 'Це поле обов\'язкове',
      'invalid_email': 'Неправильний формат email',
      'password_too_short': 'Пароль має бути не менше 6 символів',
      'loading': 'Завантаження...',
      'add_photo': 'Додати фото',
      'item_title': 'Назва предмету',
      'save_item': 'Зберегти предмет',
      'new_collection': 'Нова колекція',
      'collection_name': 'Назва колекції',
      'cancel': 'Скасувати',
      'create': 'Створити',
      'error_loading': 'Помилка завантаження',
      'retry': 'Спробувати ще',
      'empty_list': 'Список порожній',
      'purchase_date': 'Дата придбання',
      'price': 'Ціна',
      'condition': 'Стан',
      'description': 'Опис',
      'notifications_history': 'Історія сповіщень',
      'notifications_history_empty': 'Сповіщень немає',
      'select_language': 'Виберіть мову',
      'language_name_uk': 'Українська',
      'language_name_en': 'English',
      'about_app_title': 'Про застосунок',
      'app_version_info': 'Версія 1.0.0',
      'close': 'Закрити',
      'language': 'Мова',
      'about_app': 'Про застосунок',
      'delete': 'Видалити',
      'delete_confirm': 'Видалити цей елемент?',
    },
    'en': {
      'app_name': 'CollectorHub',
      'login_credential': 'Email',
      'password': 'Password',
      'login': 'Log In',
      'login_error': 'Login failed.',
      'no_account': 'No account? Sign Up',
      'create_account_title': 'Create Account',
      'email': 'Email',
      'confirm_password': 'Confirm Password',
      'register': 'Sign Up',
      'registration_error': 'Registration failed.',
      'password_mismatch': 'Passwords do not match',
      'have_account': 'Already have an account? Log In',
      'collections': 'Collections',
      'profile': 'Profile',
      'my_collections': 'My Collections',
      'items_count': 'Items',
      'add_new_item': 'Add New Item',
      'sort_by': 'Sort by',
      'sort_name': 'Name',
      'sort_count': 'Count',
      'item_details': 'Item Details',
      'settings': 'Settings',
      'logout': 'Log Out',
      'dark_theme': 'Dark Theme',
      'test_crash': 'Test Crashlytics',
      'field_required': 'This field is required',
      'invalid_email': 'Invalid email format',
      'password_too_short': 'Password must be at least 6 characters',
      'loading': 'Loading...',
      'add_photo': 'Add Photo',
      'item_title': 'Item Name',
      'save_item': 'Save Item',
      'new_collection': 'New Collection',
      'collection_name': 'Collection Name',
      'cancel': 'Cancel',
      'create': 'Create',
      'error_loading': 'Error loading',
      'retry': 'Retry',
      'empty_list': 'List is empty',
      'purchase_date': 'Purchase Date',
      'price': 'Price',
      'condition': 'Condition',
      'description': 'Description',
      'notifications_history': 'Notifications History',
      'notifications_history_empty': 'No notifications',
      'select_language': 'Select Language',
      'language_name_uk': 'Ukrainian',
      'language_name_en': 'English',
      'about_app_title': 'About App',
      'app_version_info': 'Version 1.0.0',
      'close': 'Close',
      'language': 'Language',
      'about_app': 'About App',
      'delete': 'Delete',
      'delete_confirm': 'Delete this item?',
    }
  };

  String get(String key) => _values[locale.languageCode]?[key] ?? key;
}

class AppState extends StatefulWidget {
  final Widget child;
  final _AppStateState initialState;

  const AppState({Key? key, required this.child, required this.initialState}) : super(key: key);

  static _AppStateState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppStateProvider>()!.data;
  }

  @override
  _AppStateState createState() => initialState;
}

class _AppStateState extends State<AppState> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('uk');
  static const _themeKey = 'app_theme_mode';

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
      _saveThemePreference(themeMode);
    });
  }

  void _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AppStateProvider(data: this, child: widget.child);
  }
}

class _AppStateProvider extends InheritedWidget {
  final _AppStateState data;
  const _AppStateProvider({Key? key, required this.data, required Widget child}) : super(key: key, child: child);
  @override
  bool updateShouldNotify(_AppStateProvider oldWidget) => true;
}

// --- MAIN ENTRY POINT ---

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    final appState = _AppStateState();
    await appState.loadPreferences();

    runApp(AppState(initialState: appState, child: const CollectorHubApp()));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class CollectorHubApp extends StatelessWidget {
  const CollectorHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    const primaryColor = Color(0xFF436147);

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.grey[100],
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.light),
      appBarTheme: const AppBarTheme(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 2),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: primaryColor, foregroundColor: Colors.white),
      cardTheme: CardThemeData(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark),
      appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900], foregroundColor: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: primaryColor, foregroundColor: Colors.white),
      cardTheme: CardThemeData(color: Colors.grey[850], elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );

    return MaterialApp(
      title: 'CollectorHub',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: appState.themeMode,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (snapshot.hasData) return const MainPage();
          return const LoginPage();
        },
      ),
    );
  }
}

// --- AUTH SCREENS ---

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text);
      await FirebaseAnalytics.instance.logLogin(loginMethod: 'email_password');
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    final strings = AppStrings.of(context);
    if (value == null || value.isEmpty) return strings.get('field_required');
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return strings.get('invalid_email');
    return null;
  }

  String? _validatePassword(String? value) {
    final strings = AppStrings.of(context);
    if (value == null || value.isEmpty) return strings.get('field_required');
    if (value.length < 6) return strings.get('password_too_short');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(Icons.collections_bookmark, size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                Text(strings.get('app_name'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: strings.get('login_credential'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.email_outlined)),
                  validator: _validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(labelText: strings.get('password'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible))),
                  validator: _validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _login, child: Text(strings.get('login')))),
                const SizedBox(height: 16),
                TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegistrationPage())), child: Text(strings.get('no_account'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.of(context).get('password_mismatch'))));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text);
      await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email_password');
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    final strings = AppStrings.of(context);
    if (value == null || value.isEmpty) return strings.get('field_required');
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return strings.get('invalid_email');
    return null;
  }

  String? _validatePassword(String? value) {
    final strings = AppStrings.of(context);
    if (value == null || value.isEmpty) return strings.get('field_required');
    if (value.length < 6) return strings.get('password_too_short');
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final strings = AppStrings.of(context);
    if (value == null || value.isEmpty) return strings.get('field_required');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.get('create_account_title')), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(controller: _emailController, decoration: InputDecoration(labelText: strings.get('email'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: _validateEmail, autovalidateMode: AutovalidateMode.onUserInteraction),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordController, obscureText: !_isPasswordVisible, decoration: InputDecoration(labelText: strings.get('password'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible))), validator: _validatePassword, autovalidateMode: AutovalidateMode.onUserInteraction),
                const SizedBox(height: 16),
                TextFormField(controller: _confirmController, obscureText: !_isConfirmPasswordVisible, decoration: InputDecoration(labelText: strings.get('confirm_password'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible))), validator: _validateConfirmPassword, autovalidateMode: AutovalidateMode.onUserInteraction),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _register, child: Text(strings.get('register')))),
                const SizedBox(height: 16),
                TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: Text(strings.get('have_account'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[HomePage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard_rounded), label: strings.get('collections')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: strings.get('profile')),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// --- HOME & COLLECTIONS ---

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CollectionsProvider()..init(),
      child: const HomePageView(),
    );
  }
}

class HomePageView extends StatelessWidget {
  const HomePageView({Key? key}) : super(key: key);

  void _showAddCollectionDialog(BuildContext context) {
    final strings = AppStrings.of(context);
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.get('new_collection')),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(hintText: strings.get('collection_name')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  context.read<CollectionsProvider>().addCollection(nameController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(strings.get('create')),
            ),
          ],
        );
      },
    );
  }

  // Функція підтвердження видалення колекції
  void _confirmDeleteCollection(BuildContext context, String collectionId) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.get('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              // Викликаємо метод видалення з Provider
              context.read<CollectionsProvider>().deleteCollection(collectionId);
              Navigator.of(dialogContext).pop();
            },
            child: Text(strings.get('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.get('my_collections')),
      ),
      body: Consumer<CollectionsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${strings.get('error_loading')}: ${provider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.init(),
                    child: Text(strings.get('retry')),
                  ),
                ],
              ),
            );
          }

          if (provider.collections.isEmpty) {
            return Center(child: Text(strings.get('empty_list')));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: provider.collections.length,
            itemBuilder: (context, index) {
              final collection = provider.collections[index];
              return Card(
                child: ListTile(
                  leading: Icon(collection.icon, color: Theme.of(context).primaryColor),
                  title: Text(collection.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // НОВЕ: Кнопка видалення замість стрілки
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDeleteCollection(context, collection.id),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: CollectionPage(collection: collection),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCollectionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CollectionPage extends StatelessWidget {
  final Collection collection;
  const CollectionPage({Key? key, required this.collection}) : super(key: key);

  // Функція підтвердження видалення предмету
  void _confirmDeleteItem(BuildContext context, String itemId, CollectionsProvider provider) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.get('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              // Викликаємо метод видалення з переданого Provider
              provider.deleteItem(collection.id, itemId);
              Navigator.of(dialogContext).pop();
            },
            child: Text(strings.get('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = FirestoreRepository();
    // Отримуємо доступ до провайдера для передачі у функцію видалення
    final provider = context.read<CollectionsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(collection.name)),
      body: StreamBuilder<List<CollectorItem>>(
          stream: repository.getItems(collection.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final items = snapshot.data ?? [];

            if (items.isEmpty) return const Center(child: Text('Empty'));

            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.75,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(item: item),
                    ),
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
                              )
                                  : const Center(child: Icon(Icons.image, size: 50)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(item.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('${item.price} \$', style: TextStyle(color: Colors.green[700])),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Кнопка видалення у правому верхньому куті
                        Positioned(
                          right: 4,
                          top: 4,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () => _confirmDeleteItem(context, item.id, provider),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddItemPage(collectionId: collection.id, provider: context.read<CollectionsProvider>()),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ItemDetailPage extends StatelessWidget {
  final CollectorItem item;
  const ItemDetailPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.get('item_details'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                item.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Container(height: 300, color: Colors.grey[300], child: const Icon(Icons.image_not_supported)),
              )
                  : Container(height: 300, width: double.infinity, color: Colors.grey[300], child: const Icon(Icons.image, size: 100)),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(strings.get('item_title'), item.name),
            _buildDetailRow(strings.get('purchase_date'), item.purchaseDate.toString().split(' ')[0]),
            _buildDetailRow(strings.get('price'), '${item.price} \$'),
            _buildDetailRow(strings.get('condition'), item.condition),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(strings.get('description'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(item.description, style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    ),
  );
}

class AddItemPage extends StatefulWidget {
  final String collectionId;
  final CollectionsProvider provider;

  const AddItemPage({Key? key, required this.collectionId, required this.provider}) : super(key: key);
  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _conditionController = TextEditingController();
  File? _imageFile;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final newItem = CollectorItem(
        id: '',
        name: _nameController.text,
        description: _descController.text,
        imageUrl: '', // Буде оновлено в provider
        price: double.tryParse(_priceController.text) ?? 0.0,
        purchaseDate: DateTime.now(),
        condition: _conditionController.text,
      );

      await widget.provider.addItemWithPhoto(widget.collectionId, newItem, _imageFile);

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.get('add_new_item')),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: CircularProgressIndicator(color: Colors.white)))
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveItem)
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey), const SizedBox(height: 8), Text(strings.get('add_photo'))])),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: InputDecoration(labelText: strings.get('item_title'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? strings.get('field_required') : null),
              const SizedBox(height: 16),
              TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: strings.get('price'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextFormField(controller: _conditionController, decoration: InputDecoration(labelText: strings.get('condition'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextFormField(controller: _descController, maxLines: 3, decoration: InputDecoration(labelText: strings.get('description'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _isSaving ? null : _saveItem, child: Text(strings.get('save_item'))),
            ],
          ),
        ),
      ),
    );
  }
}

// ... ProfilePage та SettingsPage (без змін) ...
// Для скорочення я не дублюю ProfilePage і SettingsPage, вони залишаються ідентичними до попередньої версії.
// Просто залиште їх у кінці файлу main.dart.
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(strings.get('profile'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            Text(
              user?.email ?? strings.get('loading'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ListTile(leading: const Icon(Icons.notifications), title: Text(strings.get('notifications_history')), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsPage()))),
            ListTile(leading: const Icon(Icons.settings), title: Text(strings.get('settings')), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()))),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(strings.get('logout')),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.get('notifications_history'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(strings.get('notifications_history_empty'), style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _showLanguagePicker() {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(strings.get('select_language')),
          children: <Widget>[
            SimpleDialogOption(onPressed: () { AppState.of(context).changeLocale(const Locale('uk')); Navigator.pop(context); }, child: Text(strings.get('language_name_uk'))),
            SimpleDialogOption(onPressed: () { AppState.of(context).changeLocale(const Locale('en')); Navigator.pop(context); }, child: Text(strings.get('language_name_en'))),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(strings.get('about_app_title')),
          content: Text(strings.get('app_version_info')),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.get('close'))),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.get('settings'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          SwitchListTile(
            title: Text(strings.get('dark_theme')),
            value: appState.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              appState.changeTheme(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(strings.get('language')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(appState.locale.languageCode == 'uk' ? strings.get('language_name_uk') : strings.get('language_name_en')),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              ],
            ),
            onTap: _showLanguagePicker,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(strings.get('about_app')),
            onTap: _showAboutDialog,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              onPressed: () {
                FirebaseCrashlytics.instance.crash();
              },
              child: Text(strings.get('test_crash')),
            ),
          ),
        ],
      ),
    );
  }
}