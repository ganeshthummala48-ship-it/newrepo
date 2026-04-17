import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/voice_service.dart';
import '../services/voice_command_service.dart';

class VoiceWrapper extends StatefulWidget {
  final Widget child;
  final String? textToRead;
  final String? screenTitle;

  const VoiceWrapper({
    super.key,
    required this.child,
    this.textToRead,
    this.screenTitle,
  });

  @override
  State<VoiceWrapper> createState() => _VoiceWrapperState();
}

class _VoiceWrapperState extends State<VoiceWrapper>
    with TickerProviderStateMixin {
  VoiceState _voiceState = VoiceState.idle;
  bool _isExpanded = false;
  String _partialText = '';
  bool _showListeningOverlay = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _guidePulseController;
  late Animation<double> _guidePulseAnimation;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    VoiceService.init();
    VoiceService.addStateListener(_onVoiceStateChanged);

    // Pulse when speaking
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Subtle guide pulse on screen entry
    _guidePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _guidePulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _guidePulseController, curve: Curves.easeOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Trigger guidance animation after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _guidePulseController.forward();
    });
  }

  @override
  void dispose() {
    VoiceService.removeStateListener(_onVoiceStateChanged);
    _pulseController.dispose();
    _guidePulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onVoiceStateChanged() {
    if (!mounted) return;
    setState(() {
      _voiceState = VoiceService.state;
    });
    if (_voiceState == VoiceState.speaking) {
      _pulseController.repeat(reverse: true);
    } else if (_voiceState == VoiceState.listening) {
      _waveController.repeat();
    } else {
      _pulseController.stop();
      _waveController.stop();
    }
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
  }

  Future<void> _onSpeakerTap() async {
    if (_voiceState == VoiceState.speaking) {
      await VoiceService.stop();
      return;
    }
    final content = widget.textToRead ?? "Viewing ${widget.screenTitle ?? 'this screen'}. How can I assist you?";
    await VoiceService.speakInProfileLanguage(content, context);
  }

  Future<void> _onMicTap() async {
    if (_voiceState == VoiceState.listening) {
      await VoiceService.stopListening();
      setState(() => _showListeningOverlay = false);
      return;
    }

    await VoiceService.stop();
    if (!mounted) return;
    final langCode = VoiceService.getLanguageCode(context);

    setState(() {
      _showListeningOverlay = true;
      _partialText = '';
    });

    final result = await VoiceService.listenForCommand(
      langCode,
      onPartialResult: (partial) {
        if (mounted) {
          setState(() => _partialText = partial);
        }
      },
    );

    if (!mounted) return;
    setState(() => _showListeningOverlay = false);
    if (result.isEmpty) return;

    final command = VoiceCommandService.parseCommand(result, langCode);
    if (command != null) {
      if (command.isPop) {
        final backMsg = VoiceCommandService.getGoingBackMessage(langCode);
        await VoiceService.speak(backMsg, langCode);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.maybePop(context);
        return;
      }

      final navMessage = VoiceCommandService.getNavigatingMessage(command.screenLabel, langCode);
      await VoiceService.speak(navMessage, langCode);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      if (command.routeName != null) {
        Navigator.pushNamed(context, command.routeName!);
      } else if (command.screen != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => command.screen!));
      }
    } else {
      final msg = VoiceCommandService.getNotUnderstoodMessage(langCode);
      await VoiceService.speak(msg, langCode);
    }
  }

  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Initial position: Bottom Center
    // We use a normalized alignment system for robust overflow prevention
    double xAlign = _offset.dx == 0 ? 0 : (_offset.dx / (size.width / 2) - 1).clamp(-1.0, 1.0);
    double yAlign = _offset.dy == 0 ? 0.9 : (_offset.dy / (size.height / 2) - 1).clamp(-1.0, 1.0);

    return Stack(
      children: [
        widget.child,

        // Smooth Listening Overlay (Siri Style)
        if (_showListeningOverlay) _buildListeningOverlay(),

        // Draggable Dynamic Island Assistant (Robust Alignment Version)
        Positioned.fill(
          child: SafeArea(
            child: Align(
              alignment: Alignment(xAlign, yAlign),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      // Update screen-space offset
                      double newX = (_offset.dx == 0 ? size.width / 2 : _offset.dx) + details.delta.dx;
                      double newY = (_offset.dy == 0 ? size.height * 0.95 : _offset.dy) + details.delta.dy;
                      _offset = Offset(newX, newY);
                    });
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: size.width - 48),
                    child: _buildDynamicIsland(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicIsland() {
    final bool isActive = _voiceState != VoiceState.idle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (isActive)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Guidance / State Indicator
          _buildIndicator(),
          
          // Interaction Area
          if (!_isExpanded) ...[
            const SizedBox(width: 8),
            Flexible(
              child: GestureDetector(
                onTap: _toggleExpand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _voiceState == VoiceState.speaking
                        ? 'AgriNova is speaking...'
                        : (widget.textToRead != null ? 'Listen to info?' : 'How can I help?'),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],

            if (_isExpanded) ...[
              const SizedBox(width: 12),
              _buildPillAction(
                icon: Icons.mic_rounded,
                color: _voiceState == VoiceState.listening ? Colors.red : Colors.green,
                onTap: _onMicTap,
              ),
              const SizedBox(width: 12),
              _buildPillAction(
                icon: _voiceState == VoiceState.speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                color: Colors.blueAccent,
                onTap: _onSpeakerTap,
              ),
              const SizedBox(width: 12),
              _buildPillAction(
                icon: Icons.close_rounded,
                color: Colors.white24,
                onTap: _toggleExpand,
              ),
            ],
            
            if (!_isExpanded) const SizedBox(width: 4),
          ],
        ),
      );
  }

  Widget _buildIndicator() {
    return FadeTransition(
      opacity: _guidePulseAnimation,
      child: ScaleTransition(
        scale: _voiceState == VoiceState.speaking ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.lightGreenAccent],
            ),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildPillAction({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildListeningOverlay() {
    final langCode = VoiceService.getLanguageCode(context);
    final listeningMsg = VoiceCommandService.getListeningMessage(langCode);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () async {
          await VoiceService.stopListening();
          setState(() => _showListeningOverlay = false);
        },
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // Colorful Siri-like wave
                  _buildWaveAnimation(),
                  const SizedBox(height: 40),
                  Text(
                    listeningMsg,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (_partialText.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        '"$_partialText"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveAnimation() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            // Simpler dynamic height
            final h = 20 + (30 * (0.5 + 0.5 * (index % 2 == 0 ? _waveController.value : 1.0 - _waveController.value)));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                    Colors.green.shade400,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
