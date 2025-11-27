import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 認証状態の管理
class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    _init();
  }

  final supabase = Supabase.instance.client;

  void _init() {
    state = supabase.auth.currentUser;
    
    supabase.auth.onAuthStateChange.listen((data) {
      state = data.session?.user;
    });
  }

  /// サインアップ（新規登録）
  Future<void> signUp({
    required String email,
    required String password,
    required String storeName,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;
        
        // ユーザー情報を保存
        await supabase.from('users').insert({
          'id': userId,
          'email': email,
          'store_name': storeName,
        });

        state = response.user;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// ログイン
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = response.user;
    } catch (e) {
      rethrow;
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    await supabase.auth.signOut();
    state = null;
  }

  /// ユーザー情報を取得
  Future<Map<String, dynamic>?> getUserInfo() async {
    final userId = state?.id;
    if (userId == null) return null;

    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}

/// 認証プロバイダー
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});