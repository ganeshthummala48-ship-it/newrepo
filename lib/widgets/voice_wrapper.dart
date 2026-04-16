import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/voice_command_service.dart';
import '../l10n/generated/app_localizations.dart';

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
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    VoiceService.init();
    VoiceService.addStateListener(_onVoiceStateChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutBack,
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    VoiceService.removeStateListener(_onVoiceStateChanged);
    _pulseController.dispose();
    _expandController.dispose();
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
      _waveController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _waveController.stop();
      _waveController.reset();
    }
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  Future<void> _onSpeakerTap() async {
    if (_voiceState == VoiceState.speaking) {
      await VoiceService.stop();
      return;
    }
    final content = widget.textToRead ?? "Welcome to ${widget.screenTitle ?? 'this screen'}.";
    await VoiceService.speakInProfileLanguage(content, context);
  }

  Future<void> _onMicTap() async {
    if (_voiceState == VoiceState.listening) {
      await VoiceService.stopListening();
      setState(() => _showListeningOverlay = false);
      return;
    }

    await VoiceService.stop(); // Stop any ongoing speech
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

    // Parse the command
    final command = VoiceCommandService.parseCommand(result, langCode);

    if (command != null) {
      // Speak the navigation feedback
      final navMessage = VoiceCommandService.getNavigatingMessage(command.screenLabel, langCode);
      await VoiceService.speak(navMessage, langCode);

      // Small delay for the user to hear feedback
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Navigate
      if (command.routeName != null) {
        Navigator.pushNamed(context, command.routeName!);
      } else if (command.screen != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => command.screen!),
        );
      }
    } else {
      // Didn't understand
      final msg = VoiceCommandService.getNotUnderstoodMessage(langCode);
      await VoiceService.speak(msg, langCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Listening overlay
        if (_showListeningOverlay) _buildListeningOverlay(),

        // Professional floating voice bar
        Positioned(
          right: 16,
          bottom: 24,
          child: _buildVoiceBar(),
        ),
      ],
    );
  }

  Widget _buildVoiceBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded actions
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mic button
                _buildActionButton(
                  icon: Icons.mic_rounded,
                  label: _voiceState == VoiceState.listening
                      ? AppLocalizations.of(context)!.stopVoice
                      : AppLocalizations.of(context)!.commandVoice,
                  color: _voiceState == VoiceState.listening
                      ? Colors.red
                      : const Color(0xFF1E88E5),
                  isActive: _voiceState == VoiceState.listening,
                  onTap: _onMicTap,
                ),
                const SizedBox(height: 8),
                // Speaker button
                _buildActionButton(
                  icon: _voiceState == VoiceState.speaking
                      ? Icons.stop_rounded
                      : Icons.volume_up_rounded,
                  label: _voiceState == VoiceState.speaking
                      ? AppLocalizations.of(context)!.stopVoice
                      : AppLocalizations.of(context)!.listenVoice,
                  color: _voiceState == VoiceState.speaking
                      ? Colors.orange
                      : const Color(0xFF43A047),
                  isActive: _voiceState == VoiceState.speaking,
                  onTap: _onSpeakerTap,
                ),
              ],
            ),
          ),
        ),

        // Main toggle button
        _buildMainButton(),
      ],
    );
  }

  Widget _buildMainButton() {
    final bool isActive = _voiceState != VoiceState.idle;

    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isActive ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isActive
                  ? [const Color(0xFF66BB6A), const Color(0xFF43A047)]
                  : [const Color(0xFF388E3C), const Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF43A047).withValues(alpha: 0.4),
                blurRadius: isActive ? 16 : 8,
                spreadRadius: isActive ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isExpanded ? Icons.close_rounded : Icons.record_voice_over_rounded,
              key: ValueKey(_isExpanded),
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: isActive ? 0.9 : 0.8),
                    boxShadow: [
                      if (isActive)
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
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
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated mic icon
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.red.withValues(
                                  alpha: 0.3 + (_waveController.value * 0.4),
                                ),
                                width: 2 + (_waveController.value * 2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(
                                    alpha: 0.1 + (_waveController.value * 0.2),
                                  ),
                                  blurRadius: 20 + (_waveController.value * 15),
                                  spreadRadius: _waveController.value * 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        listeningMsg,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Partial result text
                      if (_partialText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '"$_partialText"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Animated dots
                      _buildAnimatedDots(),
                      const SizedBox(height: 12),
                      Text(
                        _getHintText(langCode),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getHintText(String langCode) {
    final hints = {
      'hi': 'कहें: "बाजार", "रोग पहचान", "एआई सहायक"...',
      'te': 'చెప్పండి: "మార్కెట్", "రోగం", "AI అసిస్టెంట్"...',
      'ta': 'சொல்லுங்கள்: "சந்தை", "நோய்", "AI உதவியாளர்"...',
      'kn': 'ಹೇಳಿ: "ಮಾರುಕಟ್ಟೆ", "ರೋಗ", "AI ಸಹಾಯಕ"...',
      'bn': 'বলুন: "বাজার", "রোগ", "AI সহকারী"...',
      'mr': 'सांगा: "बाजार", "रोग", "AI सहाय्यक"...',
      'gu': 'કહો: "બજાર", "રોગ", "AI સહાયક"...',
      'ml': 'പറയൂ: "വിപണി", "രോഗം", "AI സഹായി"...',
      'pa': 'ਬੋਲੋ: "ਮੰਡੀ", "ਰੋਗ", "AI ਸਹਾਇਕ"...',
      'or': 'କୁହନ୍ତୁ: "ବଜାର", "ରୋଗ", "AI ସହାୟକ"...',
    };
    return hints[langCode] ?? 'Say: "Market", "Disease", "AI Assistant"...';
  }

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = ((_waveController.value + delay) % 1.0);
            final size = 6.0 + (value * 6.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3 + (value * 0.5)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
