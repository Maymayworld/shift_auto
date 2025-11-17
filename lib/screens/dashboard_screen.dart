import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/shift_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/shift_data.dart';

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftData = ref.watch(shiftDataProvider);
    final trialDaysRemaining = useState<int?>(null);
    final isLoading = useState(true);

    useEffect(() {
      Future<void> loadTrialInfo() async {
        final days = await ref.read(authProvider.notifier).getTrialDaysRemaining();
        trialDaysRemaining.value = days;
        isLoading.value = false;
      }
      
      loadTrialInfo();
      return null;
    }, []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Icon(Icons.dashboard, color: primaryColor, size: 32),
              const SizedBox(width: 12),
              Text(
                'ダッシュボード',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // トライアル期間バナー
          if (!isLoading.value && trialDaysRemaining.value != null)
            _buildTrialBanner(context, ref, trialDaysRemaining.value!),
          
          const SizedBox(height: 24),

          // 統計情報カード
          _buildStatsCards(context, ref, shiftData),
          
          const SizedBox(height: 32),

          // クイックアクセス
          Text(
            'クイックアクセス',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickAccessCards(context, ref),
          
          const SizedBox(height: 32),

          // 使い方ガイド
          _buildGettingStarted(context, ref, shiftData),
        ],
      ),
    );
  }

  Widget _buildTrialBanner(BuildContext context, WidgetRef ref, int daysRemaining) {
    final isExpiringSoon = daysRemaining <= 3;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpiringSoon
              ? [Colors.orange[400]!, Colors.orange[600]!]
              : [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isExpiringSoon ? Colors.orange[300]! : primaryColor).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpiringSoon ? Icons.warning_amber : Icons.celebration,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isExpiringSoon
                      ? '無料トライアル期間終了まであと${daysRemaining}日'
                      : '無料トライアル期間中（残り${daysRemaining}日）',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isExpiringSoon
                ? 'トライアル期間終了後も引き続きご利用いただくには、有料プランへのアップグレードが必要です。'
                : 'ShiftAutoの全機能を無料でお試しいただけます。気に入っていただけましたら、ぜひ有料プランをご検討ください。',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              // Stripe Checkoutセッションを作成
              final url = await ref.read(authProvider.notifier).createCheckoutSession();
              
              if (url != null) {
                // URLを開く
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('決済ページを開けませんでした')),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('エラーが発生しました')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isExpiringSoon ? Colors.orange[700] : primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '有料プランを見る',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: isExpiringSoon ? Colors.orange[700] : primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, WidgetRef ref, ShiftData shiftData) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'スタッフ数',
            value: '${shiftData.people.length}人',
            color: Colors.blue,
            onTap: () {
              ref.read(navigationProvider.notifier).navigateTo(ScreenType.peopleManagement);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.build,
            label: 'スキル数',
            value: '${shiftData.skills.length}種',
            color: Colors.green,
            onTap: () {
              ref.read(navigationProvider.notifier).navigateTo(ScreenType.storeSettings);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.event_note,
            label: 'シフトパターン',
            value: '${shiftData.shiftPatterns.length}種',
            color: Colors.orange,
            onTap: () {
              ref.read(navigationProvider.notifier).navigateTo(ScreenType.storeSettings);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCards(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildQuickAccessCard(
          icon: Icons.edit_calendar,
          title: 'シフト管理',
          description: 'シフトの作成・編集',
          color: primaryColor,
          onTap: () {
            ref.read(navigationProvider.notifier).navigateTo(ScreenType.shiftManagement);
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.people,
          title: 'スタッフ管理',
          description: 'スタッフの追加・編集',
          color: Colors.blue,
          onTap: () {
            ref.read(navigationProvider.notifier).navigateTo(ScreenType.peopleManagement);
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.settings,
          title: '店舗情報',
          description: 'スキル・パターン設定',
          color: Colors.orange,
          onTap: () {
            ref.read(navigationProvider.notifier).navigateTo(ScreenType.storeSettings);
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.help_outline,
          title: '使い方',
          description: 'ヘルプ・ガイド',
          color: Colors.green,
          onTap: () {
            ref.read(navigationProvider.notifier).navigateTo(ScreenType.help);
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGettingStarted(BuildContext context, WidgetRef ref, ShiftData shiftData) {
    // セットアップの進捗を計算
    final hasSkills = shiftData.skills.isNotEmpty;
    final hasPeople = shiftData.people.isNotEmpty;
    final hasPatterns = shiftData.shiftPatterns.isNotEmpty;

    if (hasSkills && hasPeople && hasPatterns) {
      // セットアップ完了
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'セットアップ完了！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'すべての準備が整いました。シフト管理を始めましょう！',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // セットアップ未完了
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
              const SizedBox(width: 12),
              Text(
                'はじめに',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'ShiftAutoを使い始めるには、以下のセットアップが必要です：',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 16),
          _buildSetupItem(
            icon: hasSkills ? Icons.check_circle : Icons.radio_button_unchecked,
            label: 'スキルを登録',
            isDone: hasSkills,
            onTap: () {
              ref.read(navigationProvider.notifier).navigateTo(ScreenType.storeSettings);
            },
          ),
          const SizedBox(height: 12),
          _buildSetupItem(
            icon: hasPeople ? Icons.check_circle : Icons.radio_button_unchecked,
            label: 'スタッフを登録',
            isDone: hasPeople,
            onTap: () {
              ref.read(navigationProvider.notifier).navigateTo(ScreenType.peopleManagement);
            },
          ),
          const SizedBox(height: 12),
          _buildSetupItem(
            icon: hasPatterns ? Icons.check_circle : Icons.radio_button_unchecked,
            label: 'シフトパターンを設定',
            isDone: hasPatterns,
            onTap: () {
              ref.read(navigationProvider.notifier).navigateTo(ScreenType.storeSettings);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSetupItem({
    required IconData icon,
    required String label,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isDone ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDone ? Colors.green[50] : Colors.white,
          border: Border.all(
            color: isDone ? Colors.green[300]! : Colors.blue[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDone ? Colors.green[700] : Colors.blue[700],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDone ? Colors.green[900] : Colors.blue[900],
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (!isDone)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.blue[700],
              ),
          ],
        ),
      ),
    );
  }
}