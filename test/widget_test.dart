import 'package:flutter_test/flutter_test.dart';
import 'package:serik/providers/auth_provider.dart';

void main() {
  test('AuthProvider tracks login and logout state', () {
    final authProvider = AuthProvider();

    expect(authProvider.isLoggedIn, isFalse);
    expect(authProvider.isLandlord, isFalse);

    authProvider.login(
      userId: '1',
      userName: 'Serik User',
      userEmail: 'user@example.com',
      userRole: 'landlord',
      token: 'test-token',
      phone: '255700000000',
    );

    expect(authProvider.isLoggedIn, isTrue);
    expect(authProvider.isLandlord, isTrue);
    expect(authProvider.userEmail, 'user@example.com');

    authProvider.logout();

    expect(authProvider.isLoggedIn, isFalse);
    expect(authProvider.userEmail, isNull);
  });
}
