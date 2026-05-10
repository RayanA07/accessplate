import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../local/profile_dao.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._profileDao);

  final ProfileDao _profileDao;

  @override
  Future<UserProfile?> load() async {
    final json = await _profileDao.loadProfileJson();
    if (json == null) {
      return null;
    }
    return UserProfile.fromJson(json);
  }

  @override
  Future<void> save(UserProfile profile) async {
    await _profileDao.saveProfileJson(profile.toJson());
  }

  @override
  Future<void> clear() async {
    await _profileDao.clear();
  }
}
