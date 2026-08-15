import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/users.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase>
    with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<int> insertUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  Future<void> upsertUser(UsersCompanion user) async {
    await into(users).insertOnConflictUpdate(user);
  }

  Future<User?> getUserById(String userId) {
    return (select(users)
          ..where(
            (table) => table.userId.equals(userId),
          ))
        .getSingleOrNull();
  }

  Future<User?> getUserByEmail(String email) {
    return (select(users)
          ..where(
            (table) => table.email.equals(email),
          ))
        .getSingleOrNull();
  }

  Future<List<User>> getAllUsers() {
    return select(users).get();
  }

  Future<int> updateUser(UsersCompanion user) {
    return update(users).write(user);
  }

  Future<int> deleteUser(String userId) {
    return (delete(users)
          ..where(
            (table) => table.userId.equals(userId),
          ))
        .go();
  }

  Future<bool> userExists(String userId) async {
    final user = await getUserById(userId);
    return user != null;
  }
}