// screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SignUpScreen extends HookConsumerWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> handleSignUp() async {
      // バリデーション
      if (storeNameController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        errorMessage.value = 'すべての項目を入力してください';
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        errorMessage.value = 'パスワードが一致しません';
        return;
      }

      if (passwordController.text.length < 6) {
        errorMessage.value = 'パスワードは6文字以上で入力してください';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        await ref.read(authProvider.notifier).signUp(
              email: emailController.text.trim(),
              password: passwordController.text,
              storeName: storeNameController.text.trim(),
            );

        // signUp成功後、AuthGateが自動的にメイン画面に遷移する
        // Navigator.popは不要
      } catch (e) {
        errorMessage.value = '登録に失敗しました。別のメールアドレスをお試しください。';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('新規登録'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // タイトル
                Text(
                  '14日間無料トライアル',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'クレジットカード登録不要で今すぐ始められます',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 店舗名
                TextField(
                  controller: storeNameController,
                  decoration: InputDecoration(
                    labelText: '店舗名',
                    prefixIcon: const Icon(Icons.store),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  enabled: !isLoading.value,
                ),
                const SizedBox(height: 16),

                // メールアドレス
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading.value,
                ),
                const SizedBox(height: 16),

                // パスワード
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'パスワード（6文字以上）',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                  enabled: !isLoading.value,
                ),
                const SizedBox(height: 16),

                // パスワード確認
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'パスワード（確認）',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                  enabled: !isLoading.value,
                  onSubmitted: (_) => handleSignUp(),
                ),
                const SizedBox(height: 24),

                // エラーメッセージ
                if (errorMessage.value != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage.value!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 登録ボタン
                ElevatedButton(
                  onPressed: isLoading.value ? null : handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '無料で始める',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // 注意書き
                Text(
                  '※トライアル期間終了後、月額4,980円で継続利用できます',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}