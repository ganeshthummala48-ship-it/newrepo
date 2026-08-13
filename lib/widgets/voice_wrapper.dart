import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/voice_command_service.dart';
import '../services/ai_service.dart';
import '../l10n/generated/app_localizations.dart';

class VoiceWrapper extends StatefulWidget {
  final Widget child;
  final String? textToRead;
  final String? screenTitle;
  final Future<bool> Function(String query, String langCode)? onVoiceQuery;

  const VoiceWrapper({
    super.key,
    required this.child,
    this.textToRead,
    this.screenTitle,
    this.onVoiceQuery,
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
  bool _handsFreeMode = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _waveController;
  late AnimationController _handsFreeController;
  late Animation<double> _handsFreeAnimation;

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

    _handsFreeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _handsFreeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _handsFreeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    VoiceService.removeStateListener(_onVoiceStateChanged);
    if (_handsFreeMode) {
      VoiceService.stopWakeWordListening();
    }
    _pulseController.dispose();
    _expandController.dispose();
    _waveController.dispose();
    _handsFreeController.dispose();
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

  // ----------------------------------------------------------------
  // Hands-Free Mode toggle
  // ----------------------------------------------------------------

  Future<void> _toggleHandsFree() async {
    if (_handsFreeMode) {
      // Turn OFF
      await VoiceService.stopWakeWordListening();
      _handsFreeController.stop();
      _handsFreeController.reset();
      setState(() => _handsFreeMode = false);
    } else {
      // Turn ON
      final langCode = VoiceService.getLanguageCode(context);
      setState(() => _handsFreeMode = true);
      _handsFreeController.repeat(reverse: true);
      await VoiceService.startWakeWordListening(langCode, _onWakeWordDetected);
    }
  }

  /// Called by VoiceService when the wake word is heard.
  void _onWakeWordDetected() {
    if (!mounted) return;
    // Auto-trigger the command mic flow
    _onMicTap();
  }

  // ----------------------------------------------------------------
  // Command listening
  // ----------------------------------------------------------------

  Future<void> _onMicTap() async {
    if (_voiceState == VoiceState.listening) {
      await VoiceService.stopListening();
      setState(() => _showListeningOverlay = false);
      // Resume wake-word loop after manual stop
      if (_handsFreeMode) VoiceService.resumeWakeWord();
      return;
    }

    // Pause wake-word loop so it doesn't conflict
    if (_handsFreeMode) VoiceService.pauseWakeWord();

    // Capture context-dependent values before any await
    final langCode = VoiceService.getLanguageCode(context);

    await VoiceService.stop(); // Stop any ongoing speech

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

    if (result.isNotEmpty) {
      // 1. Check if the active screen handles the query directly
      if (widget.onVoiceQuery != null) {
        final handledLocally = await widget.onVoiceQuery!(result, langCode);
        if (handledLocally) {
          if (_handsFreeMode) VoiceService.resumeWakeWord();
          return;
        }
      }

      // 2. Parse command for screen navigation
      final command = VoiceCommandService.parseCommand(result, langCode);

      if (command != null) {
        if (command.isPop) {
          final navMessage = VoiceCommandService.getGoingBackMessage(langCode);
          await VoiceService.speak(navMessage, langCode);
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (_handsFreeMode) VoiceService.resumeWakeWord();
          return;
        }

        // Prevent self-redirect: check if user is ALREADY on this screen
        bool isAlreadyOnScreen = false;
        if (widget.screenTitle != null) {
          final titleLower = widget.screenTitle!.toLowerCase();
          final labelLower = command.screenLabel.toLowerCase();
          if (titleLower == labelLower ||
              titleLower.contains(labelLower) ||
              labelLower.contains(titleLower)) {
            isAlreadyOnScreen = true;
          }
        }

        if (isAlreadyOnScreen) {
          // User is ALREADY on this screen! Do NOT push a duplicate route!
          final msg = VoiceCommandService.getAlreadyOnScreenMessage(command.screenLabel, langCode);
          await VoiceService.speak(msg, langCode);

          // Read out current page text if available
          if (widget.textToRead != null && widget.textToRead!.isNotEmpty) {
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) {
              await VoiceService.speakInProfileLanguage(widget.textToRead!, context);
            }
          }
        } else {
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
        }
      } else {
        // 3. Spoken input is NOT a navigation command -> Treat as AI Query in profile language!
        await _handleVoiceQueryWithAI(result, langCode);
      }
    }

    // Resume wake-word loop after command finished
    if (_handsFreeMode) VoiceService.resumeWakeWord();
  }

  /// Handles natural language voice questions by querying AIService in profile language
  /// and reading out the response aloud with an interactive glassmorphic modal.
  Future<void> _handleVoiceQueryWithAI(String question, String langCode) async {
    final thinkingMsg = VoiceCommandService.getThinkingMessage(langCode);
    await VoiceService.speak(thinkingMsg, langCode);

    try {
      final answer = await AIService.getAIResponse(question, language: langCode);
      if (!mounted) return;

      // Show interactive answer modal
      _showAIAnswerModal(question, answer, langCode);

      // Read out answer in profile language
      await VoiceService.speak(answer, langCode);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = VoiceCommandService.getNotUnderstoodMessage(langCode);
      await VoiceService.speak(errorMsg, langCode);
    }
  }

  void _showAIAnswerModal(String question, String answer, String langCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF34D399), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () {
                          VoiceService.stop();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          answer,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => VoiceService.speak(answer, langCode),
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                        label: const Text("Replay Voice", style: TextStyle(color: Colors.white)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          VoiceService.stop();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text("Stop"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                // Hands-Free toggle button
                _buildActionButton(
                  icon: _handsFreeMode
                      ? Icons.hearing_rounded
                      : Icons.hearing_disabled_rounded,
                  label: _handsFreeMode ? 'Hands-Free ON' : 'Hands-Free',
                  color: _handsFreeMode
                      ? const Color(0xFFFFB300)  // amber when active
                      : const Color(0xFF78909C), // grey when off
                  isActive: _handsFreeMode,
                  onTap: _toggleHandsFree,
                ),
                const SizedBox(height: 8),
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
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
            // Hands-Free indicator dot
            if (_handsFreeMode)
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _handsFreeAnimation,
                  builder: (context, _) {
                    return Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFB300).withValues(
                          alpha: _handsFreeAnimation.value,
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
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
          if (_handsFreeMode) VoiceService.resumeWakeWord();
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
                      // Hands-free badge
                      if (_handsFreeMode)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hearing_rounded,
                                  color: Color(0xFFFFB300), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Hands-Free',
                                style: TextStyle(
                                  color: Color(0xFFFFB300),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
      'hi': 'à¤•à¤¹à¥‡à¤‚: "à¤¬à¤¾à¤œà¤¾à¤°", "à¤°à¥‹à¤— à¤ªà¤¹à¤šà¤¾à¤¨", "à¤à¤†à¤ˆ à¤¸à¤¹à¤¾à¤¯à¤•"...',
      'te': 'à°šà±†à°ªà±à°ªà°‚à°¡à°¿: "à°®à°¾à°°à±à°•à±†à°Ÿà±", "à°°à±‹à°—à°‚", "AI à°…à°¸à°¿à°¸à±à°Ÿà±†à°‚à°Ÿà±"...',
      'ta': 'à®šà¯Šà®²à¯à®²à¯à®™à¯à®•à®³à¯: "à®šà®¨à¯à®¤à¯ˆ", "à®¨à¯‹à®¯à¯", "AI à®‰à®¤à®µà®¿à®¯à®¾à®³à®°à¯"...',
      'kn': 'à²¹à³‡à²³à²¿: "à²®à²¾à²°à³à²•à²Ÿà³à²Ÿà³†", "à²°à³‹à²—", "AI à²¸à²¹à²¾à²¯à²•"...',
      'bn': 'à¦¬à¦²à§à¦¨: "à¦¬à¦¾à¦œà¦¾à¦°", "à¦°à§‹à¦—", "AI à¦¸à¦¹à¦•à¦¾à¦°à§€"...',
      'mr': 'à¤¸à¤¾à¤‚à¤—à¤¾: "à¤¬à¤¾à¤œà¤¾à¤°", "à¤°à¥‹à¤—", "AI à¤¸à¤¹à¤¾à¤¯à¥à¤¯à¤•"...',
      'gu': 'àª•àª¹à«‹: "àª¬àªœàª¾àª°", "àª°à«‹àª—", "AI àª¸àª¹àª¾àª¯àª•"...',
      'ml': 'à´ªà´±à´¯àµ‚: "à´µà´¿à´ªà´£à´¿", "à´°àµ‹à´—à´‚", "AI à´¸à´¹à´¾à´¯à´¿"...',
      'pa': 'à¨¬à©‹à¨²à©‹: "à¨®à©°à¨¡à©€", "à¨°à©‹à¨—", "AI à¨¸à¨¹à¨¾à¨‡à¨•"...',
      'or': 'à¬•à­à¬¹à¬¨à­à¬¤à­: "à¬¬à¬œà¬¾à¬°", "à¬°à­‹à¬—", "AI à¬¸à¬¹à¬¾à­Ÿà¬•"...',
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
