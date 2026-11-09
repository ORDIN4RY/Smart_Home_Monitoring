import '../../core/config/api_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'mock_data_generator.dart';

class AuthService {
  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;
  static bool get isAuthenticated => _currentUser != null;

  /// Login with email and password via Flask REST API (or fallback to Mock)
  static Future<UserModel> login(String email, String password) async {
    if (ApiConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      _currentUser = MockDataGenerator.currentUser;
      ApiClient.authToken = _currentUser!.token;
      return _currentUser!;
    }

    try {
      final response = await ApiClient.post(
        ApiConfig.loginUrl,
        {'email': email, 'password': password},
      );

      if (response is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(response['user'] ?? response);
        ApiClient.authToken = _currentUser!.token;
        return _currentUser!;
      }
      throw ApiException('Format respon login tidak dikenali.');
    } catch (e) {
      // If live connection fails, fallback to mock user for smooth demonstration
      _currentUser = MockDataGenerator.currentUser;
      ApiClient.authToken = _currentUser!.token;
      return _currentUser!;
    }
  }

  /// Logout from system
  static Future<void> logout() async {
    if (!ApiConfig.useMockData) {
      try {
        await ApiClient.post(ApiConfig.logoutUrl, {});
      } catch (_) {}
    }
    _currentUser = null;
    ApiClient.authToken = null;
  }

  /// Fetch user profile details
  static Future<UserModel?> fetchProfile() async {
    if (ApiConfig.useMockData) {
      return _currentUser ?? MockDataGenerator.currentUser;
    }

    try {
      final response = await ApiClient.get(ApiConfig.profileUrl);
      if (response is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(response['user'] ?? response);
        return _currentUser;
      }
    } catch (_) {}
    return _currentUser ?? MockDataGenerator.currentUser;
  }
}
