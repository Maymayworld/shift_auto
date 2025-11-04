// screens/help_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';

class HelpScreen extends HookConsumerWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '使い方',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. 店舗情報の設定',
              content: 'まず、「店舗情報」からスキルとスタッフを登録してください。',
              steps: [
                'スキル情報：ホール、キッチンなど、必要なスキルを追加',
                'スタッフ情報：スタッフを追加し、それぞれが持つスキルを選択',
              ],
            ),
            _buildSection(
              title: '2. シフト希望の入力',
              content: 'シフト管理画面で、各日程のシフト希望を入力します。',
              steps: [
                '日程をクリックして編集画面を開く',
                '希望するスタッフとスキルを選択',
                '必要人数を設定',
              ],
            ),
            _buildSection(
              title: '3. シフトの自動生成',
              content: '希望を入力したら、シフトを自動計算できます。',
              steps: [
                '「全て計算」：全ての未確定シフトを一括計算',
                '「選択して計算」：特定の日程のみを選んで計算',
              ],
            ),
            _buildSection(
              title: '4. 固定シフトの設定',
              content: '特定のスタッフを固定で配置したい場合は、固定シフト機能を使用してください。',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    List<String>? steps,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          if (steps != null) ...[
            const SizedBox(height: 12),
            ...steps.map((step) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: primaryColor)),
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}