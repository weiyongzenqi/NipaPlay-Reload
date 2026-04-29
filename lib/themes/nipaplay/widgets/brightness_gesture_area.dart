import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nipaplay/utils/video_player_state.dart';

class BrightnessGestureArea extends StatefulWidget {
  const BrightnessGestureArea({super.key});

  @override
  State<BrightnessGestureArea> createState() => _BrightnessGestureAreaState();
}

class _BrightnessGestureAreaState extends State<BrightnessGestureArea> {
  // 防误触区域高度
  static const double _topSafeArea = 48.0; // 顶部安全区域（状态栏+通知栏下拉区域）
  static const double _bottomSafeArea = 40.0; // 底部安全区域
  // 最小滑动距离阈值（只有超过这个距离才开始调节）
  static const double _minDragDistance = 10.0;

  double _accumulatedDrag = 0.0;
  bool _hasStartedAdjustment = false;

  void _onVerticalDragStart(BuildContext context, DragStartDetails details) {
    _accumulatedDrag = 0.0;
    _hasStartedAdjustment = false;
  }

  void _onVerticalDragUpdate(BuildContext context, DragUpdateDetails details) {
    // 累计滑动距离
    _accumulatedDrag += details.delta.dy.abs();

    // 只有超过最小距离阈值才开始调节
    if (!_hasStartedAdjustment && _accumulatedDrag > _minDragDistance) {
      _hasStartedAdjustment = true;
      final videoState = Provider.of<VideoPlayerState>(context, listen: false);
      videoState.startBrightnessDrag();
    }

    if (_hasStartedAdjustment) {
      final videoState = Provider.of<VideoPlayerState>(context, listen: false);
      videoState.updateBrightnessOnDrag(details.delta.dy, context);
    }
  }

  void _onVerticalDragEnd(BuildContext context, DragEndDetails details) {
    if (_hasStartedAdjustment) {
      final videoState = Provider.of<VideoPlayerState>(context, listen: false);
      videoState.endBrightnessDrag();
    }
    _accumulatedDrag = 0.0;
    _hasStartedAdjustment = false;
  }

  void _onVerticalDragCancel(BuildContext context) {
    if (_hasStartedAdjustment) {
      final videoState = Provider.of<VideoPlayerState>(context, listen: false);
      videoState.endBrightnessDrag();
    }
    _accumulatedDrag = 0.0;
    _hasStartedAdjustment = false;
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // 计算有效的防误触区域
    final effectiveTopSafeArea = safeTop + _topSafeArea;
    final effectiveBottomSafeArea = safeBottom + _bottomSafeArea;

    return Positioned(
      left: 0,
      top: effectiveTopSafeArea, // 添加顶部安全区域
      bottom: effectiveBottomSafeArea, // 添加底部安全区域
      width: MediaQuery.of(context).size.width / 2.2,
      child: GestureDetector(
        onVerticalDragStart: (details) =>
            _onVerticalDragStart(context, details),
        onVerticalDragUpdate: (details) =>
            _onVerticalDragUpdate(context, details),
        onVerticalDragEnd: (details) => _onVerticalDragEnd(context, details),
        onVerticalDragCancel: () => _onVerticalDragCancel(context),
        behavior: HitTestBehavior.translucent,
        child: Container(),
      ),
    );
  }
}
