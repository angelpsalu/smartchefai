import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/features/auth/signup_screen.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';

Widget buildSignupScreen(MockFirebaseService mockService) {
  final router = GoRouter(
    initialLocation: '/signup',
    routes: [
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
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
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login')),
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

  group('SignupScreen', () {
    testWidgets('renders name, email, password fields and signup button',
        (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockService));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Account'), findsWidgets);
    });

    testWidgets('shows validation errors on empty form submit', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockService));
      await tester.pumpAndSettle();

      // Tap the Create Account button (ElevatedButton)
      final createAccountButton = find.byType(ElevatedButton);
      await tester.ensureVisible(createAccountButton);
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('password fields obscure text by default', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockService));
      await tester.pumpAndSettle();

      final editableTexts =
          tester.widgetList<EditableText>(find.byType(EditableText)).toList();
      final obscuredFields = editableTexts.where((et) => et.obscureText).toList();
      // Both password and confirm password fields should be obscured
      expect(obscuredFields.length, greaterThanOrEqualTo(2));
    });

    testWidgets('shows Sign In link back to login', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockService));
      await tester.pumpAndSettle();

      expect(find.text('Already have an account? '), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Sign In'),
          matching: find.byType(TextButton),
        ),
        findsOneWidget,
      );
    });
  });
}
