import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../data/models/user_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';

class AuthState {
  final bool isAuthenticated;
  final UserModel? user;
  final String? role;
  final String? approvalStatus;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.role,
    this.approvalStatus,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? user,
    String? role,
    String? approvalStatus,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const _storage = FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final role = await _storage.read(key: AppConstants.userRoleKey);
    final approvalStatus = await _storage.read(
      key: AppConstants.approvalStatusKey,
    );
    if (token != null && role != null) {
      state = state.copyWith(
        isAuthenticated: true,
        role: role,
        approvalStatus: approvalStatus ?? 'approved',
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final token = response.data['token'];
      final user = UserModel.fromJson(response.data['user']);
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userRoleKey, value: user.role);
      await _storage.write(key: AppConstants.userIdKey, value: user.id);
      await _storage.write(
        key: AppConstants.approvalStatusKey,
        value: user.approvalStatus,
      );
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        role: user.role,
        approvalStatus: user.approvalStatus,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Erreur de connexion';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    Map<String, String> captainDocuments = const {},
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final formValues = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      };
      for (final entry in captainDocuments.entries) {
        formValues[entry.key] = await MultipartFile.fromFile(entry.value);
      }
      final response = await ApiClient.instance.post(
        '/auth/register',
        data: FormData.fromMap(formValues),
      );
      final token = response.data['token'];
      final user = UserModel.fromJson(response.data['user']);
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.userRoleKey, value: user.role);
      await _storage.write(key: AppConstants.userIdKey, value: user.id);
      await _storage.write(
        key: AppConstants.approvalStatusKey,
        value: user.approvalStatus,
      );
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        role: user.role,
        approvalStatus: user.approvalStatus,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Erreur d\'inscription';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final response = await ApiClient.instance.get('/auth/me');
      final user = UserModel.fromJson(response.data['user']);
      await _storage.write(
        key: AppConstants.approvalStatusKey,
        value: user.approvalStatus,
      );
      state = state.copyWith(
        user: user,
        role: user.role,
        approvalStatus: user.approvalStatus,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        error: error.response?.data['message'] ?? 'Erreur de connexion',
      );
    }
  }

  Future<String?> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      state = state.copyWith(isLoading: false, error: null);
      return response.data['dev_code']?.toString();
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.response?.data['message'] ?? 'Erreur de connexion',
      );
      return null;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiClient.instance.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'password': password},
      );
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.response?.data['message'] ?? 'Erreur de connexion',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
