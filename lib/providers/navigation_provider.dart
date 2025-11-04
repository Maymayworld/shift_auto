// providers/navigation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 画面タイプ
enum ScreenType {
  dashboard,
  shiftManagement,
  shiftEdit,
  storeSettings,
  skillManagement,
  peopleManagement,
  help,
}

/// ナビゲーション状態
class NavigationState {
  final ScreenType screenType;
  final Map<String, dynamic> params;

  NavigationState({
    required this.screenType,
    this.params = const {},
  });

  NavigationState copyWith({
    ScreenType? screenType,
    Map<String, dynamic>? params,
  }) {
    return NavigationState(
      screenType: screenType ?? this.screenType,
      params: params ?? this.params,
    );
  }
}

/// ナビゲーション状態管理
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier()
      : super(NavigationState(screenType: ScreenType.dashboard));

  /// 画面を変更
  void navigateTo(ScreenType screenType, {Map<String, dynamic>? params}) {
    state = NavigationState(
      screenType: screenType,
      params: params ?? {},
    );
  }

  /// 戻る（前の画面に戻る）
  void goBack() {
    // デフォルトの戻り先を設定
    switch (state.screenType) {
      case ScreenType.shiftEdit:
        navigateTo(ScreenType.shiftManagement);
        break;
      case ScreenType.skillManagement:
        navigateTo(ScreenType.storeSettings);
        break;
      case ScreenType.peopleManagement:
        navigateTo(ScreenType.dashboard);
        break;
      default:
        navigateTo(ScreenType.dashboard);
        break;
    }
  }
}

/// ナビゲーションプロバイダー
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});