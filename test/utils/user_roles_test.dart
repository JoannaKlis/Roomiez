import 'package:flutter_test/flutter_test.dart';
import 'package:roomies/utils/user_roles.dart';

void main() {
  test('UserRole constants should have correct values', () {
    expect(UserRole.user, 'user');
    expect(UserRole.apartmentManager, 'apartment_manager');
    expect(UserRole.landlord, 'landlord');
    expect(UserRole.administrator, 'admin');
  });
}