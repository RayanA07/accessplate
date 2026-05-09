import '../domain/entities/user_profile.dart';
import '../domain/repositories/profile_repository.dart';

class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<UserProfile> loadOrDefault() async {
    return await _repository.load() ?? UserProfile.defaults();
  }

  Future<void> save(UserProfile profile) {
    return _repository.save(profile);
  }

  Future<void> clear() {
    return _repository.clear();
  }
}
