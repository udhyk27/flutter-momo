import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../controller/home_controller.dart';
import '../widgets/vmidc.dart';

/// stateVal
/// 0 => 노래 분석 중
/// 1 => 기본 화면
/// 2 => 분석 실패 화면

bool firstRecord = true;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {

  final HomeController controller = Get.put(HomeController());
  final VMIDC _vmidc = VMIDC();

  Future<void>? _asyncTask;

  // nullable로 선언 → build()에서 null 체크로 안전하게 접근
  AnimationController? _pulseController;
  AnimationController? _fadeController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _vmidc.init();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeOut),
    );
  }

  Future<void> asyncFunction() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) return;

    PermissionStatus status = await Permission.microphone.status;
    if (status == PermissionStatus.permanentlyDenied) {
      PermissionToast();
      await Permission.microphone.request();
      return;
    } else if (status == PermissionStatus.denied) {
      final result = await Permission.microphone.request();
      if (result.isGranted) {
        await _vmidc.start();
      }
    }

    try {
      if (!mounted) return;
      await _vmidc.start();
    } catch (e) {
      print('녹음 실패 $e');
      controller.changeState(2);
    }
  }

  void cancelAsyncTask() async {
    if (_asyncTask != null) {
      await _vmidc.stop();
    }
    controller.changeState(2);
  }

  @override
  void dispose() {
    controller.changeState(1);
    _vmidc.dispose();
    _pulseController?.dispose();
    _fadeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeValue = context.watch<MyAppState>().selectedValue;
    final isChecked = context.watch<MyAppState>().isChecked;
    final hasStarted = context.watch<MyAppState>().hasStarted;

    if (isChecked && !hasStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Future.delayed(const Duration(milliseconds: 500), () async {
          _asyncTask = asyncFunction();
        });
        await _asyncTask;
        context.read<MyAppState>().setHasStarted(true);
      });
    }

    // ── 테마별 색상 정의 ──────────────────────────────────────────
    final _ThemeTokens tokens = _ThemeTokens.of(themeValue);

    return GetX<HomeController>(
      builder: (controller) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: tokens.overlayStyle,
        child: Scaffold(
          backgroundColor: tokens.bgTop,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tokens.bgTop, tokens.bgBottom],
                stops: const [0.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: Stack(
                  children: [

                    // ── 배경 장식 원 ──────────────────────────────
                    Positioned(
                      top: -80,
                      right: -60,
                      child: _DecorCircle(color: tokens.decorColor, size: 260),
                    ),
                    Positioned(
                      bottom: -100,
                      left: -80,
                      child: _DecorCircle(color: tokens.decorColor, size: 300),
                    ),

                    // ── 메인 콘텐츠 ───────────────────────────────
                    Column(
                      children: [

                        // ── 상단 액션 버튼 ────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisAlignment: controller.stateVal.value == 1
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              controller.stateVal.value == 1
                                  ? _GlassIconButton(
                                icon: Image.asset(
                                  'assets/settings.png',
                                  width: 20,
                                  height: 20,
                                  color: Colors.white,
                                ),
                                onTap: () {
                                  context.read<MyAppState>().setPageIdx(3);
                                },
                                tokens: tokens,
                              )
                                  : _GlassIconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: themeValue == 2 ? Colors.white : Colors.white,
                                ),
                                onTap: () {
                                  controller.stateVal.value == 0
                                      ? cancelAsyncTask()
                                      : controller.changeState(1);
                                },
                                tokens: tokens,
                              ),
                            ],
                          ),
                        ),

                        // ── 중앙 콘텐츠 ───────────────────────────
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final screenWidth = MediaQuery.of(context).size.width;
                              final screenHeight = MediaQuery.of(context).size.height;
                              final logoSize = (screenWidth * 0.58).clamp(180.0, 260.0);
                              final buttonBoxSize = (screenWidth * 0.85).clamp(280.0, 340.0);
                              final labelBoxHeight = screenHeight < 700 ? 72.0 : 64.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [

                                    const Spacer(),

                                    const Spacer(flex: 3),

                                    // ── 상태 레이블 ──────────────────
                                    SizedBox(
                                      height: labelBoxHeight,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(opacity: anim, child: child),
                                        child: _StatusLabel(
                                          key: ValueKey(controller.stateVal.value),
                                          stateVal: controller.stateVal.value,
                                          tokens: tokens,
                                        ),
                                      ),
                                    ),

                                    // ── 버튼 ─────────────────────
                                    GestureDetector(
                                      onTap: () async {
                                        controller.stateVal.value == 0
                                            ? cancelAsyncTask()
                                            : _asyncTask = asyncFunction();
                                      },
                                      child: SizedBox(
                                        width: buttonBoxSize,
                                        height: buttonBoxSize,
                                        child: Center(
                                          child: controller.stateVal.value == 0
                                              ? _PulseRing(
                                            tokens: tokens,
                                            logoSize: logoSize,
                                            child: _LogoContainer(
                                              themeValue: themeValue,
                                              stateVal: controller.stateVal.value,
                                              size: logoSize,
                                            ),
                                          )
                                              : AnimatedBuilder(
                                            animation: _pulseAnimation ?? const AlwaysStoppedAnimation(1.0),
                                            builder: (_, child) => Transform.scale(
                                              scale: controller.stateVal.value == 1
                                                  ? (_pulseAnimation?.value ?? 1.0)
                                                  : 1.0,
                                              child: child,
                                            ),
                                            child: _LogoContainer(
                                              themeValue: themeValue,
                                              stateVal: controller.stateVal.value,
                                              size: logoSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // ── 서브 힌트 ────────────────────
                                    SizedBox(
                                      height: 28,
                                      child: AnimatedOpacity(
                                        opacity: controller.stateVal.value == 2 ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: Text(
                                          '다시 눌러 재시도해보세요',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: tokens.labelColor.withValues(alpha: 0.55),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const Spacer(flex: 1),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // ── 하단 브랜드 워터마크 ──────────────────
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Text(
                            'momo',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w300,
                              color: tokens.labelColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 로고 컨테이너 ────────────────────────────────────────────────────
class _LogoContainer extends StatelessWidget {
  final int themeValue;
  final int stateVal;
  final double size;
  const _LogoContainer({required this.themeValue, required this.stateVal, required this.size});

  @override
  Widget build(BuildContext context) {
    if (stateVal == 0) {
      final String gifPath = themeValue == 1
          ? 'assets/loading1_blue2.gif'
          : 'assets/loading1_pink2.gif';

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            gifPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final AssetImage image = themeValue == 1
        ? const AssetImage('assets/momo_assets/blue_logo.png')
        : const AssetImage('assets/momo_assets/berry_logo.png');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(image: image, fit: BoxFit.cover),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }
}

// ── 파동 링 (분석 중 상태) ────────────────────────────────────────────
class _PulseRing extends StatefulWidget {
  final Widget child;
  final _ThemeTokens tokens;
  final double logoSize;
  const _PulseRing({required this.child, required this.tokens, required this.logoSize});

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none, // 파동이 SizedBox 밖으로 넘쳐도 레이아웃 영향 없음
          children: [
            // 외부 파동 — overflow로 그리되 레이아웃 크기는 0
            Positioned.fill(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Opacity(
                  opacity: (1 - _anim.value).clamp(0.0, 1.0),
                  child: Container(
                    width: widget.logoSize + _anim.value * 70,
                    height: widget.logoSize + _anim.value * 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.tokens.ringColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

// ── 상태 레이블 ──────────────────────────────────────────────────────
class _StatusLabel extends StatelessWidget {
  final int stateVal;
  final _ThemeTokens tokens;
  const _StatusLabel({super.key, required this.stateVal, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData? icon;

    switch (stateVal) {
      case 0:
        text = '노래 분석 중';
        icon = null;
        break;
      case 1:
        text = '지금 이 곡을 찾으려면 모모를 눌러주세요';
        icon = null;
        break;
      default:
        text = '노래를 인식할 수 없습니다';
        icon = Icons.music_off_rounded;
    }

    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, color: tokens.labelColor.withValues(alpha: 0.5), size: 22),
          const SizedBox(height: 8),
        ],
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: stateVal == 1 ? 14 : 16,
            fontWeight: stateVal == 0 ? FontWeight.w600 : FontWeight.w500,
            color: tokens.labelColor,
            letterSpacing: 0.2,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── 유리 질감 아이콘 버튼 ─────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final _ThemeTokens tokens;
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: tokens.glassBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }
}

// ── 배경 장식 원 ─────────────────────────────────────────────────────
class _DecorCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _DecorCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ── 테마 토큰 ────────────────────────────────────────────────────────
class _ThemeTokens {
  final Color bgTop;
  final Color bgBottom;
  final Color labelColor;
  final Color glassBg;
  final Color glassBorder;
  final Color decorColor;
  final Color ringColor;
  final SystemUiOverlayStyle overlayStyle;

  const _ThemeTokens({
    required this.bgTop,
    required this.bgBottom,
    required this.labelColor,
    required this.glassBg,
    required this.glassBorder,
    required this.decorColor,
    required this.ringColor,
    required this.overlayStyle,
  });

  factory _ThemeTokens.of(int themeValue) {
    switch (themeValue) {
      case 1: // Ocean Blue
        return _ThemeTokens(
          bgTop: const Color(0xFF1A8FD1),
          bgBottom: const Color(0xFF9B1FBE),
          labelColor: Colors.white,
          glassBg: Colors.white.withValues(alpha: 0.18),
          glassBorder: Colors.white.withValues(alpha: 0.3),
          decorColor: Colors.white.withValues(alpha: 0.06),
          ringColor: Colors.white.withValues(alpha: 0.6),
          overlayStyle: SystemUiOverlayStyle.light,
        );
      case 2: // Dark Mode
        return _ThemeTokens(
          bgTop: const Color(0xFF0D0D0D),
          bgBottom: const Color(0xFF2A2A2A),
          labelColor: Colors.white,
          glassBg: Colors.white.withValues(alpha: 0.08),
          glassBorder: Colors.white.withValues(alpha: 0.12),
          decorColor: Colors.white.withValues(alpha: 0.03),
          ringColor: Colors.white.withValues(alpha: 0.4),
          overlayStyle: SystemUiOverlayStyle.light,
        );
      default: // Berry Pink
        return _ThemeTokens(
          bgTop: const Color(0xFFFF7BAC),
          bgBottom: const Color(0xFFFFD6E7),
          labelColor: const Color(0xFF3D1A26),
          glassBg: Colors.white.withValues(alpha: 0.3),
          glassBorder: Colors.white.withValues(alpha: 0.5),
          decorColor: Colors.white.withValues(alpha: 0.12),
          ringColor: const Color(0xFFFF7BAC).withValues(alpha: 0.7),
          overlayStyle: SystemUiOverlayStyle.dark,
        );
    }
  }
}

// ── 마이크 권한 거부 토스트 ───────────────────────────────────────────
void PermissionToast() {
  print('마이크 권한 영구적 거부');
  Fluttertoast.showToast(
    msg: '마이크 권한을 허용해주세요.',
    backgroundColor: const Color(0xFF444444),
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.CENTER,
  );
}

_showDialog(BuildContext context) {
  final themeValue = context.watch<MyAppState>().selectedValue;
  final tokens = _ThemeTokens.of(themeValue);

  return AlertDialog(
    backgroundColor: themeValue == 2 ? const Color(0xFF1E1E1E) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 24,
    content: Builder(
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;
        return SizedBox(
          width: width * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: themeValue == 2 ? Colors.white : const Color(0xFF1A1A1A),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  children: const [
                    TextSpan(text: '음악 인식을 위해 마이크 권한을 '),
                    TextSpan(
                      text: '허용',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' 해주세요'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: tokens.bgTop.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => openAppSettings(),
                    child: Text(
                      '권한 설정',
                      style: TextStyle(
                        color: tokens.bgTop,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}