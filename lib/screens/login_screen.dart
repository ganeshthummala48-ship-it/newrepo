import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/voice_wrapper.dart';

// ─────────────────────────────────────────────────────────────────
//  Floating leaf particle model
// ─────────────────────────────────────────────────────────────────
class _Leaf {
  double x;
  double y;
  double speed;
  double size;
  double angle;
  double rotationSpeed;
  double opacity;
  int colorIndex;

  _Leaf({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.angle,
    required this.rotationSpeed,
    required this.opacity,
    required this.colorIndex,
  });
}

// ─────────────────────────────────────────────────────────────────
//  Leaf painter – draws animated floating leaves
// ─────────────────────────────────────────────────────────────────
class _LeafPainter extends CustomPainter {
  final List<_Leaf> leaves;
  final List<Color> palette = const [
    Color(0xFF2E7D32),
    Color(0xFF388E3C),
    Color(0xFF43A047),
    Color(0xFF66BB6A),
    Color(0xFFA5D6A7),
    Color(0xFF81C784),
  ];

  _LeafPainter(this.leaves);

  @override
  void paint(Canvas canvas, Size size) {
    for (final leaf in leaves) {
      final paint = Paint()
        ..color = palette[leaf.colorIndex % palette.length]
            .withValues(alpha: leaf.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(leaf.x * size.width, leaf.y * size.height);
      canvas.rotate(leaf.angle);

      // Draw a simple leaf shape
      final path = Path();
      final s = leaf.size;
      path.moveTo(0, -s);
      path.cubicTo(s * 0.8, -s * 0.5, s * 0.8, s * 0.5, 0, s);
      path.cubicTo(-s * 0.8, s * 0.5, -s * 0.8, -s * 0.5, 0, -s);
      canvas.drawPath(path, paint);

      // Leaf vein
      final veinPaint = Paint()
        ..color = Colors.white.withValues(alpha: leaf.opacity * 0.4)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, -s * 0.7), Offset(0, s * 0.7), veinPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LeafPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────
//  Wave painter – draws animated bottom wave
// ─────────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double animValue;
  final Color color;
  final double heightFraction;

  _WavePainter({
    required this.animValue,
    required this.color,
    required this.heightFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 22.0;
    final baseY = size.height * heightFraction;

    path.moveTo(0, baseY);
    for (double x = 0; x <= size.width; x++) {
      final y = baseY +
          math.sin((x / size.width * 2 * math.pi) + (animValue * 2 * math.pi)) *
              waveHeight;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}

// ─────────────────────────────────────────────────────────────────
//  Animated text field with focus glow effect
// ─────────────────────────────────────────────────────────────────
class _AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffixWidget;
  final String? hintText;
  final VoidCallback? onTap;
  final bool readOnly;

  const _AnimatedTextField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffixWidget,
    this.hintText,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _glowController.forward();
      } else {
        _glowController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32)
                    .withValues(alpha: _glowAnimation.value * 0.35),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText,
              prefixIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  widget.prefixIcon,
                  color: _isFocused
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF81C784),
                  size: 22,
                ),
              ),
              suffixIcon: widget.suffixWidget,
              filled: true,
              fillColor: Colors.white,
              labelStyle: TextStyle(
                color: _isFocused
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF81C784),
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE8F5E9),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D32),
                  width: 2.0,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Shimmer loading button
// ─────────────────────────────────────────────────────────────────
class _ShimmerButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _ShimmerButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  State<_ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<_ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: const [
                    Color(0xFF1B5E20),
                    Color(0xFF2E7D32),
                    Color(0xFF388E3C),
                    Color(0xFF2E7D32),
                    Color(0xFF1B5E20),
                  ],
                  stops: [
                    0.0,
                    (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                    _shimmerController.value.clamp(0.0, 1.0),
                    (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                    1.0,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Main Login Screen
// ─────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _loginFailed = false;
  String _loginFailMsg = '';

  // Animation controllers
  late AnimationController _masterController;
  late AnimationController _waveController;
  late AnimationController _leafController;
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;
  late Animation<double> _shakeAnim;
  late Animation<double> _pulseAnim;

  // Leaf particles
  final List<_Leaf> _leaves = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _initLeaves();
    _initAnimations();
    _startSequence();
  }

  void _initLeaves() {
    for (int i = 0; i < 18; i++) {
      _leaves.add(_Leaf(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        speed: 0.0004 + _rng.nextDouble() * 0.0006,
        size: 5 + _rng.nextDouble() * 10,
        angle: _rng.nextDouble() * 2 * math.pi,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 0.03,
        opacity: 0.08 + _rng.nextDouble() * 0.18,
        colorIndex: _rng.nextInt(6),
      ));
    }
  }

  void _initAnimations() {
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateLeaves);
    // Run leaf animation in a repeating tick
    _runLeafTicker();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic));
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeIn),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _runLeafTicker() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) _updateLeaves();
    }
  }

  void _updateLeaves() {
    if (!mounted) return;
    setState(() {
      for (final leaf in _leaves) {
        leaf.y -= leaf.speed;
        leaf.x += math.sin(leaf.angle) * 0.002;
        leaf.angle += leaf.rotationSpeed;
        if (leaf.y < -0.05) {
          leaf.y = 1.05;
          leaf.x = _rng.nextDouble();
        }
      }
    });
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _formController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _masterController.dispose();
    _waveController.dispose();
    _leafController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Language helpers ──────────────────────────────────────────
  String _getLanguageName(String code) {
    const names = {
      'te': 'తెలుగు (Telugu)',
      'hi': 'हिन्दी (Hindi)',
      'mr': 'मराठी (Marathi)',
      'ta': 'தமிழ் (Tamil)',
      'bn': 'বাংলা (Bengali)',
      'gu': 'ગુજરાતી (Gujarati)',
      'kn': 'ಕನ್ನಡ (Kannada)',
      'ml': 'മലയാളം (Malayalam)',
      'pa': 'ਪੰਜਾਬੀ (Punjabi)',
      'or': 'ଓଡ଼ିଆ (Odia)',
    };
    return names[code] ?? 'English';
  }

  // ── Login logic ───────────────────────────────────────────────
  Future<void> _login() async {
    if (_nameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _triggerShake('Please enter username and password.');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _loginFailed = false;
      _loginFailMsg = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        HapticFeedback.lightImpact();
        final role = data['role'];
        final phone = data['phone'] ?? '';
        final box = Hive.box('profileBox');
        await box.put('name', _nameController.text.trim());
        await box.put('role', role);
        await box.put('phone', phone);
        await box.put('setup_done', true);
        await box.put('address', data['address'] ?? '');
        await box.put('pincode', data['pincode'] ?? '');
        await box.put('lat', (data['lat'] as num?)?.toDouble() ?? 0.0);
        await box.put('lng', (data['lng'] as num?)?.toDouble() ?? 0.0);

        if (!mounted) return;
        if (role == 'contractor') {
          Navigator.pushReplacementNamed(context, '/contractor');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _triggerShake(data['error'] ?? l10n.loginFailed);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      _triggerShake('Connection error. Please try again.');
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _triggerShake(String msg) {
    setState(() {
      _loginFailed = true;
      _loginFailMsg = msg;
    });
    _shakeController.forward(from: 0);
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: VoiceWrapper(
        screenTitle: l10n.login,
        textToRead:
            'Welcome to AgriNova. Please login to continue.',
        child: Stack(
          children: [
            // ── Animated background gradient ────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE8F5E9),
                      Color(0xFFF1F8E9),
                      Color(0xFFF5F7F5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // ── Floating leaf particles ─────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LeafPainter(_leaves),
                ),
              ),
            ),

            // ── Top decorative circle ───────────────────────────
            Positioned(
              top: -80,
              right: -60,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF66BB6A).withValues(alpha: 0.25),
                          const Color(0xFF2E7D32).withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom decorative circle ────────────────────────
            Positioned(
              bottom: -100,
              left: -70,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: 2.0 - _pulseAnim.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF43A047).withValues(alpha: 0.15),
                          const Color(0xFF1B5E20).withValues(alpha: 0.03),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Animated bottom wave ────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) => SizedBox(
                  height: 120,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(screenSize.width, 120),
                        painter: _WavePainter(
                          animValue: _waveController.value,
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.07),
                          heightFraction: 0.4,
                        ),
                      ),
                      CustomPaint(
                        size: Size(screenSize.width, 120),
                        painter: _WavePainter(
                          animValue: _waveController.value + 0.3,
                          color: const Color(0xFF43A047).withValues(alpha: 0.05),
                          heightFraction: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),


            // ── Main scrollable content ─────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Language selector moved inside safe area
                    Align(
                      alignment: Alignment.topRight,
                      child: _LanguageDropdown(
                        currentCode: localeProvider.locale.languageCode,
                        getLanguageName: _getLanguageName,
                        onChanged: (v) {
                          if (v != null) {
                            localeProvider.setLocale(Locale(v));
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Logo + title ──────────────────────────
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _buildLogoSection(),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Login form card ───────────────────────
                    FadeTransition(
                      opacity: _formFade,
                      child: SlideTransition(
                        position: _formSlide,
                        child: AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(_shakeAnim.value, 0),
                            child: child,
                          ),
                          child: _buildFormCard(l10n),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Register link ─────────────────────────
                    FadeTransition(
                      opacity: _formFade,
                      child: _buildRegisterLink(l10n),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logo section ──────────────────────────────────────────────
  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo with glowing border
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                blurRadius: 30,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFF66BB6A).withValues(alpha: 0.2),
                blurRadius: 60,
                spreadRadius: 8,
              ),
            ],
            border: Border.all(
              color: const Color(0xFFA5D6A7),
              width: 2.5,
            ),
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                AppConstants.appLogo,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // App name
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF66BB6A)],
          ).createShader(bounds),
          child: const Text(
            'AgriNova',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🌱 Smart Farming, Better Future',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ── Form card ────────────────────────────────────────────────
  Widget _buildFormCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.login,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      'Sign in to your account',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Error banner
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _loginFailed
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _loginFailMsg,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _loginFailed = false),
                            child: Icon(Icons.close,
                                color: Colors.red.shade400, size: 18),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Username field
            _AnimatedTextField(
              controller: _nameController,
              label: l10n.username,
              prefixIcon: Icons.person_outline_rounded,
              hintText: 'Enter your username',
            ),

            const SizedBox(height: 18),

            // Password field
            _AnimatedTextField(
              controller: _passwordController,
              label: l10n.password,
              prefixIcon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              hintText: 'Enter your password',
              suffixWidget: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF81C784),
                  size: 22,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            const SizedBox(height: 10),

            // Forgot password row
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF388E3C),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Login button
            _isLoading
                ? _buildLoadingIndicator()
                : _ShimmerButton(
                    onPressed: _login,
                    label: l10n.login,
                    icon: Icons.login_rounded,
                  ),

            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ],
            ),

            const SizedBox(height: 20),

            // Social login placeholders
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    icon: Icons.fingerprint,
                    label: 'Biometric',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    icon: Icons.qr_code_rounded,
                    label: 'QR Login',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(width: 14),
          Text(
            'Signing in...',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.noAccount,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/register');
            },
            child: const Text(
              'Sign up',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Social button widget
// ─────────────────────────────────────────────────────────────────
class _SocialButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: const Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Language dropdown widget
// ─────────────────────────────────────────────────────────────────
class _LanguageDropdown extends StatefulWidget {
  final String currentCode;
  final String Function(String) getLanguageName;
  final ValueChanged<String?> onChanged;

  const _LanguageDropdown({
    required this.currentCode,
    required this.getLanguageName,
    required this.onChanged,
  });

  @override
  State<_LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<_LanguageDropdown> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: widget.currentCode,
        dropdownColor: Colors.white,
        iconEnabledColor: const Color(0xFF2E7D32),
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(16),
        icon: const Icon(Icons.language, size: 18),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        items: ['en', 'te', 'hi', 'mr', 'ta', 'bn', 'gu', 'kn', 'ml', 'pa', 'or']
            .map((l) => DropdownMenuItem(
                  value: l,
                  child: Text(widget.getLanguageName(l)),
                ))
            .toList(),
        onChanged: widget.onChanged,
      ),
    );
  }
}
