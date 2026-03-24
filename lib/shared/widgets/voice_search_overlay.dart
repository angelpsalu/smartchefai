import 'package:flutter/material.dart';
import '../../app/theme/theme.dart';
import '../../services/voice_search_service.dart';
import '../../utils/ingredient_parser.dart';

/// Determines which voice flow the overlay is serving.
enum VoiceOverlayMode { recipeSearch, ingredientInput }

/// Internal state machine for the voice overlay.
enum _VoiceState { listening, result, timeout, error }

/// Show the full-screen voice input overlay.
///
/// Returns the spoken string on Done/Search, or [null] on Cancel/back/error.
///
/// [mode] controls hint text, accent colour, done button label, and whether
/// real-time ingredient chips are shown below the visualisation.
Future<String?> showVoiceSearchOverlay({
  required BuildContext context,
  required VoiceSearchService service,
  VoiceOverlayMode mode = VoiceOverlayMode.recipeSearch,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) =>
        _VoiceOverlayPage(service: service, mode: mode),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

// ── Overlay page ──────────────────────────────────────────────────────────────

class _VoiceOverlayPage extends StatefulWidget {
  final VoiceSearchService service;
  final VoiceOverlayMode mode;

  const _VoiceOverlayPage({required this.service, required this.mode});

  @override
  State<_VoiceOverlayPage> createState() => _VoiceOverlayPageState();
}

class _VoiceOverlayPageState extends State<_VoiceOverlayPage>
    with TickerProviderStateMixin {
  // Ring ripple controllers (staggered start)
  late final AnimationController _ring1;
  late final AnimationController _ring2;
  late final AnimationController _ring3;

  // Mic "breathe" scale
  late final AnimationController _micPulse;
  late final Animation<double> _micScale;

  // Ring fade-out when entering result/timeout/error
  late final AnimationController _ringFade;
  late final Animation<double> _ringOpacity;

  _VoiceState _voiceState = _VoiceState.listening;
  String _partialWords = '';

  // Ingredient chips (ingredientInput mode only)
  List<String> _chips = [];
  Set<String> _newChips = {}; // chips that should animate this render pass

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startListening();
  }

  void _setupAnimations() {
    _ring1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _ring2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _ring2.repeat();
    });

    _ring3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _ring3.repeat();
    });

    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _micScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _micPulse, curve: Curves.easeInOut),
    );

    _ringFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0, // fully visible initially
    );
    _ringOpacity = _ringFade.drive(
      Tween<double>(begin: 1.0, end: 0.0),
    );
  }

  Future<void> _startListening() async {
    setState(() {
      _voiceState = _VoiceState.listening;
      _partialWords = '';
      _chips = [];
      _newChips = {};
    });

    // Reset ring fade and restart animations.
    _ringFade.value = 1.0;
    if (!_ring1.isAnimating) _ring1.repeat();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && !_ring2.isAnimating) _ring2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && !_ring3.isAnimating) _ring3.repeat();
    });
    if (!_micPulse.isAnimating) _micPulse.repeat(reverse: true);

    await widget.service.startListening(
      onPartialResult: (words) {
        if (!mounted) return;
        setState(() {
          _partialWords = words;
          if (widget.mode == VoiceOverlayMode.ingredientInput) {
            final parsed = IngredientParser.parse(words);
            _newChips = Set<String>.from(parsed).difference(Set<String>.from(_chips));
            _chips = parsed;
          }
        });
      },
      onResult: (words) {
        if (!mounted) return;
        setState(() {
          _partialWords = words;
          _voiceState = _VoiceState.result;
        });
        _stopAnimations();
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _voiceState = _VoiceState.error);
        _stopAnimations();
      },
      onDone: () {
        if (!mounted) return;
        // onResult fires before onDone for a successful capture.
        // If we're still in listening state here, it means silence timeout.
        if (_voiceState == _VoiceState.listening) {
          setState(() {
            _voiceState = _partialWords.isEmpty
                ? _VoiceState.timeout
                : _VoiceState.result;
          });
          _stopAnimations();
        }
      },
    );
  }

  void _stopAnimations() {
    _ring1.stop();
    _ring2.stop();
    _ring3.stop();
    _micPulse.stop();
    _ringFade.forward(); // 400ms fade-out
  }

  Future<void> _confirm() async {
    await widget.service.stopListening();
    if (mounted) Navigator.of(context).pop(_partialWords);
  }

  Future<void> _cancel() async {
    await widget.service.cancel();
    if (mounted) Navigator.of(context).pop(null);
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    _ring3.dispose();
    _micPulse.dispose();
    _ringFade.dispose();
    super.dispose();
  }

  // ── Mode-specific values ────────────────────────────────────────────────────

  Color get _accentColor => widget.mode == VoiceOverlayMode.recipeSearch
      ? AppColors.primaryOrange
      : AppColors.info;

  String get _hintText => widget.mode == VoiceOverlayMode.recipeSearch
      ? 'Say a recipe name…'
      : 'Say your ingredients, e.g. chicken, rice, onions';

  String get _doneLabel => widget.mode == VoiceOverlayMode.recipeSearch
      ? 'Search'
      : 'Use These Ingredients';

  String get _statusTitle {
    switch (_voiceState) {
      case _VoiceState.listening:
        return 'Listening…';
      case _VoiceState.result:
        return 'Got it!';
      case _VoiceState.timeout:
        return "Didn't catch that";
      case _VoiceState.error:
        return 'Mic unavailable';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          color: const Color(0xFF0D0D0D).withValues(alpha: 0.95),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cancel button — always top-right
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: IconButton(
                      onPressed: _cancel,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Centre content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status title
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _statusTitle,
                          key: ValueKey(_voiceState),
                          style: textTheme.headlineSmall?.copyWith(
                            color: _voiceState == _VoiceState.error
                                ? Colors.redAccent
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Hint text — fades out when words arrive
                      AnimatedOpacity(
                        opacity: _partialWords.isEmpty ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _hintText,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: Colors.white54),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Ripple rings + mic button
                      FadeTransition(
                        opacity: _ringOpacity,
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_voiceState == _VoiceState.listening) ...[
                                _WaveRing(
                                  controller: _ring3,
                                  color: _accentColor,
                                  maxRadius: 144,
                                ),
                                _WaveRing(
                                  controller: _ring2,
                                  color: _accentColor,
                                  maxRadius: 112,
                                ),
                                _WaveRing(
                                  controller: _ring1,
                                  color: _accentColor,
                                  maxRadius: 80,
                                ),
                              ],
                              // Mic button
                              ScaleTransition(
                                scale: _voiceState == _VoiceState.listening
                                    ? _micScale
                                    : const AlwaysStoppedAnimation(1.0),
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: _voiceState == _VoiceState.error
                                          ? [Colors.redAccent, Colors.red]
                                          : [
                                              _accentColor,
                                              _accentColor.withValues(alpha: 0.75),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_voiceState == _VoiceState.error
                                                ? Colors.redAccent
                                                : _accentColor)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _voiceState == _VoiceState.error
                                        ? Icons.mic_off_rounded
                                        : _voiceState == _VoiceState.listening
                                            ? Icons.mic_rounded
                                            : Icons.mic_none_rounded,
                                    color: Colors.white,
                                    size: 44,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Partial words
                      if (_partialWords.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              '"$_partialWords"',
                              key: ValueKey(_partialWords),
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Real-time ingredient chips (ingredientInput mode only)
                      if (widget.mode == VoiceOverlayMode.ingredientInput &&
                          _chips.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _chips
                                .map((chip) => _AnimatedChip(
                                      key: ValueKey(chip),
                                      label: chip,
                                      color: _accentColor,
                                      animate: _newChips.contains(chip),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: _buildButtons(textTheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(TextTheme textTheme) {
    switch (_voiceState) {
      case _VoiceState.listening:
        return const SizedBox.shrink();

      case _VoiceState.result:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(_doneLabel),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: _accentColor,
                textStyle: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _startListening,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
              ),
            ),
          ],
        );

      case _VoiceState.timeout:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _startListening,
              icon: const Icon(Icons.mic_rounded, size: 20),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: _accentColor,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _cancel,
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              child: const Text('Cancel'),
            ),
          ],
        );

      case _VoiceState.error:
        return FilledButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.close_rounded, size: 20),
          label: const Text('Cancel'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }
}

// ── Animated chip ─────────────────────────────────────────────────────────────

/// A chip that scales + fades in on first appearance.
///
/// Pass [animate: true] only for newly added chips (diff against previous list).
/// Existing chips should receive [animate: false] — Flutter preserves their
/// [State] via [ValueKey], so their controller stays at 1.0.
class _AnimatedChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool animate;

  const _AnimatedChip({
    super.key,
    required this.label,
    required this.color,
    required this.animate,
  });

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.animate ? 0.0 : 1.0,
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = _ctrl.drive(CurveTween(curve: Curves.easeIn));
    if (widget.animate) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Chip(
          label: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: widget.color.withValues(alpha: 0.8),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}

// ── Wave ring ─────────────────────────────────────────────────────────────────

class _WaveRing extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double maxRadius;

  const _WaveRing({
    required this.controller,
    required this.color,
    required this.maxRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _RingPainter(
          progress: controller.value,
          color: color,
          maxRadius: maxRadius,
        ),
        size: Size(maxRadius * 2, maxRadius * 2),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double maxRadius;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = progress * maxRadius;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
