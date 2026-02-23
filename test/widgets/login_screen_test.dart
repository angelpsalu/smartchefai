import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/features/auth/login_screen.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';

Widget buildLoginScreen(MockFirebaseService mockService) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/get-started',
        builder: (context, state) =>
            const Scaffold(body: Text('Get Started')),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const Scaffold(body: Text('Sign Up')),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            const Scaffold(body: Text('Forgot Password')),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => UserProvider(service: mockService),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockFirebaseService mockService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    when(mockService.currentUser).thenReturn(null);
    when(mockService.isSignedIn).thenReturn(false);
  });

  group('LoginScreen', () {
    testWidgets('renders email field, password field, and login button',
        (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockService));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty form submit', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('password field obscures text by default', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockService));
      await tester.pumpAndSettle();

      final editableTexts =
          tester.widgetList<EditableText>(find.byType(EditableText)).toList();
      expect(editableTexts.any((et) => et.obscureText), isTrue);
    });

    testWidgets('Forgot Password? link is present', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockService));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });
  });
}
