import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenService {
  Future<void> saveTokens(String access, String refresh);
  String? get accessToken;
  String? get refreshToken;
  Future<void> clear();
}

@LazySingleton(as: TokenService)
class TokenServiceImpl implements TokenService {
  final SharedPreferences prefs;

  TokenServiceImpl(this.prefs);

  static const _accessKey = 'accessToken';
  static const _refreshKey = 'refreshToken';

  @override
  Future<void> saveTokens(String access, String refresh) async {
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  @override
  String? get accessToken => prefs.getString(_accessKey);

  @override
  String? get refreshToken => prefs.getString(_refreshKey);

  @override
  Future<void> clear() async {
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
