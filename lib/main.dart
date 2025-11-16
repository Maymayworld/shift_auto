// main.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/subscription_required_screen.dart';
import 'screens/main_layout.dart';
import 'providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env ファイルを読み込む
  await dotenv.load(fileName: ".env");
  
  // Supabase 初期化
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftAuto',
      theme: ThemeData(
        primaryColor: primaryColor,
        textTheme: GoogleFonts.zenKakuGothicNewTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 認証状態に応じて画面を切り替える
class AuthGate extends HookConsumerWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final subscriptionStatus = useState<SubscriptionStatus?>(null);
    final isLoading = useState(true);

    useEffect(() {
      // 認証状態が変わったらサブスク状態をチェック
      Future<void> checkStatus() async {
        if (authState != null) {
          final status = await ref.read(authProvider.notifier).checkSubscription();
          subscriptionStatus.value = status;
        }
        isLoading.value = false;
      }
      
      checkStatus();
      return null;
    }, [authState]);

    // ローディング中
    if (isLoading.value) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 未ログイン
    if (authState == null) {
      return const LoginScreen();
    }

    // サブスク状態チェック
    final status = subscriptionStatus.value;
    
    // サブスクなし（データベースにsubscriptionレコードがない）
    if (status == SubscriptionStatus.none) {
      return const SubscriptionRequiredScreen();
    }
    
    if (status == SubscriptionStatus.trialExpired ||
        status == SubscriptionStatus.expired) {
      return const SubscriptionRequiredScreen();
    }

    if (status == SubscriptionStatus.active) {
      return const MainLayout();
    }

    // デフォルト（エラー時など）
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}