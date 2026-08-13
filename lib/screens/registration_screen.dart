import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/voice_wrapper.dart';

// ─────────────────────────────────────────────────────────────────
//  Particle model for background effect
// ─────────────────────────────────────────────────────────────────
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double opacity;
  int colorIndex;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
    required this.colorIndex,
  });
}

// ─────────────────────────────────────────────────────────────────
//  Bubble / particle painter
// ─────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final List<Color> palette = const [
    Color(0xFF2E7D32),
    Color(0xFF388E3C),
    Color(0xFF43A047),
    Color(0xFF66BB6A),
    Color(0xFFA5D6A7),
  ];

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = palette[p.colorIndex % palette.length]
            .withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────
//  Arc / decorative painter for top header
// ─────────────────────────────────────────────────────────────────
class _HeaderArcPainter extends CustomPainter {
  final double animValue;

  _HeaderArcPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.lineTo(0, size.height * 0.8);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height + 30,
      size.width * 0.5,
      size.height * 0.85,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.9,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Shimmering overlay
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final shimX = animValue * size.width * 1.5 - size.width * 0.25;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(shimX, size.height * 0.4),
          width: size.width * 0.6,
          height: size.height * 0.8),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(_HeaderArcPainter old) => old.animValue != animValue;
}

// ─────────────────────────────────────────────────────────────────
//  Animated text field (same design as login)
// ─────────────────────────────────────────────────────────────────
class _RegTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffixWidget;
  final String? hintText;
  final Function(String)? onChanged;
  final int maxLines;
  final int? maxLength;

  const _RegTextField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffixWidget,
    this.hintText,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<_RegTextField> createState() => _RegTextFieldState();
}

class _RegTextFieldState extends State<_RegTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glow;
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _glow = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _focus.addListener(() {
      setState(() => _focused = _focus.hasFocus);
      _focused ? _glowCtrl.forward() : _glowCtrl.reverse();
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: _glow.value * 0.3),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          style: const TextStyle(
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            counterText: '',
            prefixIcon: Icon(
              widget.prefixIcon,
              color: _focused ? const Color(0xFF2E7D32) : const Color(0xFF81C784),
              size: 22,
            ),
            suffixIcon: widget.suffixWidget,
            filled: true,
            fillColor: Colors.white,
            labelStyle: TextStyle(
              color: _focused ? const Color(0xFF2E7D32) : const Color(0xFF81C784),
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE8F5E9), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Step indicator widget
// ─────────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          final completed = stepBefore < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 2.5,
              decoration: BoxDecoration(
                gradient: completed
                    ? const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                      )
                    : null,
                color: completed ? null : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final step = index ~/ 2;
        final isActive = step == currentStep;
        final isCompleted = step < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: isActive ? 40 : 32,
          height: isActive ? 40 : 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: (isActive || isCompleted)
                ? const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: (isActive || isCompleted) ? null : const Color(0xFFF1F8E9),
            border: Border.all(
              color: (isActive || isCompleted)
                  ? Colors.transparent
                  : const Color(0xFFC8E6C9),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF81C784),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Animated register button
// ─────────────────────────────────────────────────────────────────
class _RegisterButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isLoading;

  const _RegisterButton({
    required this.onPressed,
    required this.label,
    required this.isLoading,
  });

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isLoading
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onPressed();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedBuilder(
          animation: _shimCtrl,
          builder: (_, child) => Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                  Color(0xFF43A047),
                  Color(0xFF2E7D32),
                  Color(0xFF1B5E20),
                ],
                stops: [
                  0.0,
                  (_shimCtrl.value - 0.3).clamp(0.0, 1.0),
                  _shimCtrl.value.clamp(0.0, 1.0),
                  (_shimCtrl.value + 0.3).clamp(0.0, 1.0),
                  1.0,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
          child: widget.isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'Creating account...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 22),
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
//  Role card widget
// ─────────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final String role;
  final String label;
  final IconData icon;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.label,
    required this.icon,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected
                  ? Colors.transparent
                  : const Color(0xFFE8F5E9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.selected
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: widget.selected ? 24 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFE8F5E9),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.selected
                      ? Colors.white
                      : const Color(0xFF2E7D32),
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: widget.selected ? Colors.white : const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.selected
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.grey.shade500,
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
//  Main Registration Screen
// ─────────────────────────────────────────────────────────────────
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // State
  String _selectedRole = 'farmer';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _currentStep = 0;

  // Pincode state
  bool _pincodeLoading = false;
  String _resolvedCity = '';
  String _resolvedDistrict = '';
  double _resolvedLat = 0.0;
  double _resolvedLng = 0.0;
  bool _pincodeVerified = false;
  String _pincodeError = '';
  bool _gpsLoading = false;

  // Animation controllers
  late AnimationController _headerShimCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _successCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _stepCtrl;

  // Animations
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _successScale;
  late Animation<double> _successFade;
  // _stepSlide removed (unused)

  // Particles
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();
  bool _showSuccess = false;

  final List<String> _stepLabels = ['Account', 'Role', 'Location'];

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initAnimations();
    _startEntrance();
  }

  void _initParticles() {
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        vx: (_rng.nextDouble() - 0.5) * 0.0012,
        vy: -0.0005 - _rng.nextDouble() * 0.0008,
        radius: 3 + _rng.nextDouble() * 8,
        opacity: 0.06 + _rng.nextDouble() * 0.12,
        colorIndex: _rng.nextInt(5),
      ));
    }
    _runParticleTicker();
  }

  void _runParticleTicker() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) _updateParticles();
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        if (p.y < -0.05) {
          p.y = 1.05;
          p.x = _rng.nextDouble();
        }
        if (p.x < -0.05 || p.x > 1.05) {
          p.x = _rng.nextDouble();
        }
      }
    });
  }

  void _initAnimations() {
    _headerShimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeIn),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
    _successFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

  }

  void _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _headerShimCtrl.dispose();
    _waveCtrl.dispose();
    _contentCtrl.dispose();
    _successCtrl.dispose();
    _particleCtrl.dispose();
    _stepCtrl.dispose();
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

  // ── GPS location ──────────────────────────────────────────────
  Future<void> _fetchGPSLocation() async {
    setState(() {
      _gpsLoading = true;
      _pincodeError = '';
      _pincodeVerified = false;
      _resolvedCity = '';
      _resolvedDistrict = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _pincodeError = 'Location services are disabled.';
          _gpsLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _pincodeError = 'Location permissions denied.';
          _gpsLoading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _resolvedLat = pos.latitude;
        _resolvedLng = pos.longitude;
        _resolvedCity = 'GPS Position';
        _resolvedDistrict = 'Current Location';
        _pincodeVerified = true;
        _pincodeController.text = '';
      });
    } catch (e) {
      setState(() {
        _pincodeError = 'Failed to get GPS location.';
      });
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  // ── Pincode lookup ────────────────────────────────────────────
  Future<void> _lookupPincode(String pincode) async {
    if (pincode.length != 6) {
      setState(() {
        _pincodeVerified = false;
        _resolvedCity = '';
        _resolvedDistrict = '';
        _pincodeError = '';
      });
      return;
    }

    setState(() {
      _pincodeLoading = true;
      _pincodeError = '';
      _pincodeVerified = false;
    });

    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/pincode_lookup?pincode=$pincode'),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          _resolvedLat = lat;
          _resolvedLng = lng;
          _resolvedCity = data['city'] ?? '';
          _resolvedDistrict = data['district'] ?? '';
          _pincodeVerified = lat != 0.0;
          _pincodeError =
              lat == 0.0 ? 'Could not resolve pincode location.' : '';
        });
      }
    } catch (e) {
      setState(() {
        _pincodeError = 'Could not verify pincode. Check server connection.';
        _pincodeVerified = false;
      });
    } finally {
      if (mounted) setState(() => _pincodeLoading = false);
    }
  }

  // ── Register ──────────────────────────────────────────────────
  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;

    if (_nameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError('Name and password are required.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    // Capture context-dependent values before any await
    final languageCode = Provider.of<LocaleProvider>(context, listen: false)
        .locale
        .languageCode;

    if (_selectedRole == 'contractor' &&
        _pincodeController.text.length == 6 &&
        !_pincodeVerified) {
      await _lookupPincode(_pincodeController.text.trim());
    }
    setState(() => _isLoading = true);
    try {
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'password': _passwordController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'language': languageCode,
      };

      if (_selectedRole == 'contractor') {
        body['address'] = _addressController.text.trim();
        body['pincode'] = _pincodeController.text.trim();
        body['lat'] = _resolvedLat;
        body['lng'] = _resolvedLng;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        HapticFeedback.lightImpact();
        setState(() => _showSuccess = true);
        _successCtrl.forward();

        String successMsg = l10n.registrationSuccess;
        if (_selectedRole == 'contractor' &&
            _pincodeVerified &&
            _resolvedCity.isNotEmpty) {
          successMsg += ' Location set to $_resolvedCity.';
        }

        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(successMsg)),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showError(data['error'] ?? l10n.registrationFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: VoiceWrapper(
        screenTitle: l10n.register,
        textToRead: 'Create your account to join the AgriNova community.',
        child: Stack(
          children: [
            // ── Background gradient ─────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFF5F7F5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── Particle layer ──────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ParticlePainter(_particles),
                ),
              ),
            ),

            // ── Animated header arc ─────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _headerShimCtrl,
                builder: (_, __) => SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: _HeaderArcPainter(_headerShimCtrl.value),
                  ),
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────
            SafeArea(
              child: _showSuccess
                  ? _buildSuccessOverlay()
                  : Column(
                      children: [
                        // Header area
                        _buildHeader(l10n, localeProvider),
                        // Form area
                        Expanded(
                          child: FadeTransition(
                            opacity: _contentFade,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 24),
                                    // Step indicator
                                    _StepIndicator(
                                      currentStep: _currentStep,
                                      totalSteps: _selectedRole == 'contractor'
                                          ? 3
                                          : 2,
                                      stepLabels: _stepLabels,
                                    ),
                                    const SizedBox(height: 28),

                                    // Role selector
                                    _buildRoleSelector(l10n),
                                    const SizedBox(height: 20),

                                    // Account fields
                                    _buildAccountFields(l10n),
                                    const SizedBox(height: 20),

                                    // Language selector
                                    _buildLanguageSelector(l10n, localeProvider),
                                    const SizedBox(height: 20),

                                    // Contractor location
                                    if (_selectedRole == 'contractor') ...[
                                      _buildLocationSection(),
                                      const SizedBox(height: 20),
                                    ],

                                    // Register button
                                    _RegisterButton(
                                      onPressed: _register,
                                      label: l10n.register,
                                      isLoading: _isLoading,
                                    ),

                                    const SizedBox(height: 20),

                                    // Login link
                                    _buildLoginLink(l10n),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header section ────────────────────────────────────────────
  Widget _buildHeader(AppLocalizations l10n, LocaleProvider localeProvider) {
    return Container(
      height: 135,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.register,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Join the AgriNova family 🌿',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Role selector ─────────────────────────────────────────────
  Widget _buildRoleSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          icon: Icons.badge_outlined,
          label: l10n.selectRole,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                role: 'farmer',
                label: l10n.farmer,
                icon: Icons.agriculture_rounded,
                description: 'Manage crops, markets & weather',
                selected: _selectedRole == 'farmer',
                onTap: () => setState(() {
                  _selectedRole = 'farmer';
                  _currentStep = 0;
                }),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _RoleCard(
                role: 'contractor',
                label: l10n.contractor,
                icon: Icons.business_center_rounded,
                description: 'Post jobs, find farm labourers',
                selected: _selectedRole == 'contractor',
                onTap: () => setState(() {
                  _selectedRole = 'contractor';
                  _currentStep = 0;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Account fields ────────────────────────────────────────────
  Widget _buildAccountFields(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.person_outline_rounded,
            label: 'Account Details',
          ),
          const SizedBox(height: 18),
          _RegTextField(
            controller: _nameController,
            label: l10n.username,
            prefixIcon: Icons.person_outline_rounded,
            hintText: 'Choose a username',
          ),
          const SizedBox(height: 16),
          _RegTextField(
            controller: _passwordController,
            label: l10n.password,
            prefixIcon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            hintText: 'Create a strong password',
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
          const SizedBox(height: 16),
          _RegTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            hintText: 'Re-enter your password',
            suffixWidget: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF81C784),
                size: 22,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 16),
          _RegTextField(
            controller: _phoneController,
            label: l10n.phoneNumber,
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            hintText: l10n.phoneHint,
          ),
        ],
      ),
    );
  }

  // ── Language selector ─────────────────────────────────────────
  Widget _buildLanguageSelector(
      AppLocalizations l10n, LocaleProvider localeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.translate_rounded,
            label: l10n.preferredLanguage,
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8F5E9),
                width: 1.5,
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: localeProvider.locale.languageCode,
              borderRadius: BorderRadius.circular(16),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.language,
                    color: Color(0xFF81C784), size: 22),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: Color(0xFFE8F5E9), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: Color(0xFF2E7D32), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              dropdownColor: Colors.white,
              items: ['en', 'te', 'hi', 'mr', 'ta', 'bn', 'gu', 'kn', 'ml', 'pa', 'or']
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(_getLanguageName(l)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) localeProvider.setLocale(Locale(v));
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Location section (contractor only) ───────────────────────
  Widget _buildLocationSection() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      Text(
                        'Farmers will find you based on this location',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Address field
            _RegTextField(
              controller: _addressController,
              label: 'Business Address',
              prefixIcon: Icons.home_outlined,
              hintText: 'e.g. Shop 12, Main Road, Village Name',
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Pincode row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _RegTextField(
                    controller: _pincodeController,
                    label: 'PIN Code *',
                    prefixIcon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    hintText: '6-digit PIN',
                    onChanged: (val) {
                      if (val.length == 6) _lookupPincode(val);
                      if (val.length < 6) {
                        setState(() {
                          _pincodeVerified = false;
                          _resolvedCity = '';
                          _resolvedDistrict = '';
                          _pincodeError = '';
                        });
                      }
                    },
                    suffixWidget: _pincodeLoading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          )
                        : _pincodeVerified &&
                                _pincodeController.text.isNotEmpty
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF2E7D32), size: 22)
                            : _pincodeError.isNotEmpty
                                ? const Icon(Icons.error_outline_rounded,
                                    color: Colors.red, size: 22)
                                : null,
                  ),
                ),
                const SizedBox(width: 10),
                // GPS button
                _GPSButton(
                  isLoading: _gpsLoading,
                  onTap: _gpsLoading ? () {} : _fetchGPSLocation,
                ),
              ],
            ),

            // Pincode error
            if (_pincodeError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pincodeError,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Verified location chip
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _pincodeVerified
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _buildVerifiedLocationChip(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedLocationChip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2E7D32),
            ),
            child: const Icon(Icons.location_city_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _resolvedCity.isNotEmpty
                      ? '$_resolvedCity${_resolvedDistrict.isNotEmpty ? ', $_resolvedDistrict' : ''}'
                      : 'Location Resolved',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    fontSize: 13,
                  ),
                ),
                Text(
                  '📍 ${_resolvedLat.toStringAsFixed(5)}, ${_resolvedLng.toStringAsFixed(5)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations l10n) {
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
            'Already have an account?',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text(
              'Sign in',
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

  // ── Success overlay ───────────────────────────────────────────
  Widget _buildSuccessOverlay() {
    return FadeTransition(
      opacity: _successFade,
      child: ScaleTransition(
        scale: _successScale,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 60),
              ),
              const SizedBox(height: 30),
              const Text(
                'Account Created! 🎉',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome to AgriNova family',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
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
//  GPS button widget
// ─────────────────────────────────────────────────────────────────
class _GPSButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GPSButton({required this.isLoading, required this.onTap});

  @override
  State<_GPSButton> createState() => _GPSButtonState();
}

class _GPSButtonState extends State<_GPSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: widget.isLoading ? _pulse.value : 1.0,
        child: child,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Container(
          width: 58,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.my_location_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'GPS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
//  Section label widget
// ─────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
