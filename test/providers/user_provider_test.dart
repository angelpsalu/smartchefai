import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/providers/firebase_providers.dart';
import '../helpers/mock_firebase_service.mocks.dart';
import '../helpers/test_data.dart';

void main() {
  late MockFirebaseService mockService;
  late UserProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockService = MockFirebaseService();
    // No signed-in Firebase user — _initUser() skips profile load
    when(mockService.currentUser).thenReturn(null);
    provider = UserProvider(service: mockService);
    await Future<void>.delayed(Duration.zero);
  });

  group('UserProvider', () {
    test('isAuthenticated returns false initially (no current user)', () {
      expect(provider.isAuthenticated, false);
    });

    test('createUser() success — user profile created', () async {
      when(
        mockService.createUserProfile(
          name: anyNamed('name'),
          email: anyNamed('email'),
        ),
      ).thenAnswer((_) async {});
      when(mockService.getUserProfile())
          .thenAnswer((_) async => TestData.appUser);

      final result = await provider.createUser('Test User', 'test@example.com');

      expect(result, true);
      expect(provider.currentUser, TestData.appUser);
      expect(provider.error, null);
    });

    test('createUser() failure — error set', () async {
      when(
        mockService.createUserProfile(
          name: anyNamed('name'),
          email: anyNamed('email'),
        ),
      ).thenThrow(Exception('Network error'));

      final result = await provider.createUser('Test User', 'test@example.com');

      expect(result, false);
      expect(provider.error, isNotNull);
      expect(provider.currentUser, null);
    });

    test('logout() calls signOut and clears user', () async {
      when(mockService.signOut()).thenAnswer((_) async {});

      await provider.logout();

      verify(mockService.signOut()).called(1);
      expect(provider.currentUser, null);
      expect(provider.isAuthenticated, false);
    });

    test('setPreferences() calls updatePreferences', () async {
      when(
        mockService.updatePreferences(
          dietaryPreferences: anyNamed('dietaryPreferences'),
          allergies: anyNamed('allergies'),
        ),
      ).thenAnswer((_) async {});

      final result = await provider.setPreferences(['vegetarian'], ['nuts']);

      expect(result, true);
      verify(
        mockService.updatePreferences(
          dietaryPreferences: ['vegetarian'],
          allergies: ['nuts'],
        ),
      ).called(1);
    });

    test('toggleDarkMode() flips dark mode state', () async {
      expect(provider.isDarkMode, false);

      provider.toggleDarkMode();
      await Future<void>.delayed(Duration.zero);

      expect(provider.isDarkMode, true);

      provider.toggleDarkMode();
      await Future<void>.delayed(Duration.zero);

      expect(provider.isDarkMode, false);
    });
  });
}
