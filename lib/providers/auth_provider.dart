// providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 認証状態の管理
class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    // 初期化時に認証状態をチェック
    _init();
  }

  final supabase = Supabase.instance.client;

  void _init() {
    // 現在のセッションを取得
    state = supabase.auth.currentUser;
    
    // 認証状態の変更を監視
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
      print('🔵 SignUp started for: $email');
      
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      print('🔵 Auth signUp response: ${response.user?.id}');

      if (response.user != null) {
        final userId = response.user!.id;
        
        // ユーザー情報を保存
        try {
          print('🔵 Inserting into users table...');
          await supabase.from('users').insert({
            'id': userId,
            'email': email,
            'store_name': storeName,
          });
          print('✅ Users insert successful');
        } catch (e) {
          print('❌ Users insert error: $e');
          // ユーザーテーブルへの挿入が失敗してもログインはできるようにする
        }

        // 14日間の無料トライアル開始
        try {
          print('🔵 Inserting into subscriptions table...');
          final trialEnd = DateTime.now().add(const Duration(days: 14));
          await supabase.from('subscriptions').insert({
            'user_id': userId,
            'status': 'trialing',
            'current_period_end': trialEnd.toIso8601String(),
          });
          print('✅ Subscriptions insert successful');
          
          // 挿入が確実に完了したことを確認（最大5回リトライ）
          print('🔵 Verifying subscription data...');
          for (int i = 0; i < 5; i++) {
            await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
            
            final checkResponse = await supabase
                .from('subscriptions')
                .select()
                .eq('user_id', userId)
                .maybeSingle();
            
            if (checkResponse != null) {
              print('✅ Subscription verified!');
              break;
            }
            print('⚠️ Subscription not found yet, retrying... (${i + 1}/5)');
          }
        } catch (e) {
          print('❌ Subscriptions insert error: $e');
          rethrow; // subscriptionsの挿入失敗は致命的なのでエラーを投げる
        }

        state = response.user;
        print('✅ SignUp completed successfully');
      }
    } catch (e) {
      print('❌ SignUp error: $e');
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

  /// サブスクリプション状態をチェック
  Future<SubscriptionStatus> checkSubscription() async {
    final userId = state?.id;
    print('🔵 Checking subscription for user: $userId');
    
    if (userId == null) {
      print('⚠️ No user ID, returning none');
      return SubscriptionStatus.none;
    }

    try {
      final response = await supabase
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      print('🔵 Subscription response: $response');

      if (response == null) {
        print('⚠️ No subscription found, returning none');
        return SubscriptionStatus.none;
      }

      final status = response['status'] as String;
      final periodEndStr = response['current_period_end'] as String?;

      print('🔵 Status: $status, Period end: $periodEndStr');

      if (periodEndStr != null) {
        final periodEnd = DateTime.parse(periodEndStr);
        final now = DateTime.now();

        if (status == 'trialing') {
          if (now.isBefore(periodEnd)) {
            print('✅ Active trial');
            return SubscriptionStatus.active; // トライアル期間中
          } else {
            print('⚠️ Trial expired');
            return SubscriptionStatus.trialExpired; // トライアル終了
          }
        }

        if (status == 'active' && now.isBefore(periodEnd)) {
          print('✅ Active subscription');
          return SubscriptionStatus.active;
        }
      }

      print('⚠️ Subscription expired');
      return SubscriptionStatus.expired;
    } catch (e) {
      print('❌ Error checking subscription: $e');
      return SubscriptionStatus.none;
    }
  }

  /// トライアル残り日数を取得
  Future<int?> getTrialDaysRemaining() async {
    final userId = state?.id;
    if (userId == null) return null;

    try {
      final response = await supabase
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'trialing')
          .maybeSingle();

      if (response == null) return null;

      final periodEndStr = response['current_period_end'] as String?;
      if (periodEndStr == null) return null;

      final periodEnd = DateTime.parse(periodEndStr);
      final now = DateTime.now();
      final difference = periodEnd.difference(now);

      return difference.inDays;
    } catch (e) {
      return null;
    }
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
      print('Error getting user info: $e');
      return null;
    }
  }

/// Stripe Checkoutセッションを作成
Future<String?> createCheckoutSession() async {
  try {
    final session = supabase.auth.currentSession;
    if (session == null) {
      print('❌ No active session');
      return null;
    }

    print('🔵 Creating checkout with token...');
    
    final response = await supabase.functions.invoke(
      'create-checkout-session',
      method: HttpMethod.post,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    print('🔵 Response: ${response.data}');

    if (response.data != null && response.data['url'] != null) {
      return response.data['url'] as String;
    }

    return null;
  } catch (e) {
    print('❌ Error: $e');
    return null;
  }
}
}

/// サブスクリプション状態
enum SubscriptionStatus {
  none, // サブスクなし
  active, // 有効（トライアル中 or 契約中）
  trialExpired, // トライアル終了
  expired, // 契約終了
}

/// 認証プロバイダー
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});