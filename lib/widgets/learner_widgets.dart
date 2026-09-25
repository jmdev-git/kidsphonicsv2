import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/difficulty.dart';
import '../models/learning_progress.dart';
import '../providers/app_provider.dart';
import '../services/word_image_service.dart';
import '../theme/kids_ui.dart';
import 'learning_progress_widgets.dart';
import 'adventure_background.dart';
import 'mascot_guide.dart';

// ── Card blob painter ─────────────────────────────────────────────────────
// Renders a single soft organic blob clipped inside a card corner.
class _CardBlobPainter extends CustomPainter {
  const _CardBlobPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    // Blob anchored to top-right corner
    final path = Path();
    path.moveTo(w * 0.55, 0);
    path.cubicTo(w * 0.80, 0, w * 1.05, h * 0.18, w * 1.02, h * 0.45);
    path.cubicTo(w * 0.99, h * 0.72, w * 0.78, h * 0.85, w * 0.58, h * 0.72);
    path.cubicTo(w * 0.38, h * 0.59, w * 0.32, h * 0.32, w * 0.42, h * 0.18);
    path.cubicTo(w * 0.46, h * 0.08, w * 0.42, 0, w * 0.55, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CardBlobPainter old) => old.color != color;
}

// ── Activity card ──────────────────────────────────────────────────────────

class LearnerActivityCard extends StatelessWidget {
  const LearnerActivityCard(
      {super.key,
      required this.title,
      required this.description,
      required this.icon,
      required this.onPressed,
      this.detail,
      this.status,
      this.progress,
      this.mascot,
      this.accent = const Color(0xFF7052CA),
      this.actionLabel = 'Play'});
  final Color accent;
  final LearningMascot? mascot;
  final String actionLabel;
  final String title, description;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? detail, status;
  final double? progress;

  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Color.lerp(Colors.white, accent, .10),
      elevation: 5,
      shadowColor: accent.withValues(alpha: .25),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KidsUi.radius),
          side: BorderSide(color: accent.withValues(alpha: .28), width: 2)),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        // ── Blob accent — top-right corner ─────────────────────────────
        Positioned(
          top: 0,
          right: 0,
          width: 120,
          height: 100,
          child: CustomPaint(
            painter: _CardBlobPainter(
                color: accent.withValues(alpha: .14)),
          ),
        ),
        // ── Card content ───────────────────────────────────────────────
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(KidsUi.radius),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      if (mascot != null)
                        MascotPortrait(mascot: mascot!, size: 80)
                      else
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .85),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                      color: accent.withValues(alpha: .18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]),
                            child: Icon(icon,
                                color: onPressed == null ? KidsUi.muted : accent,
                                size: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)))
                    ]),
                    const SizedBox(height: 8),
                    Text(description),
                    if (detail != null) ...[
                      const SizedBox(height: 12),
                      Text(detail!)
                    ],
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                          value: progress!.clamp(0, 1),
                          minHeight: 8,
                          color: accent,
                          borderRadius: BorderRadius.circular(8))
                    ],
                    if (status != null)
                      Text(status!,
                          style: const TextStyle(
                              fontSize: 18, color: KidsUi.muted)),
                    Align(
                        alignment: Alignment.centerRight,
                        child: _GradientButton(
                          onPressed: onPressed,
                          accent: accent,
                          label: actionLabel,
                          icon: Icons.play_arrow,
                        )),
                  ])),
        ),
      ]));
}

// ── Gradient action button ─────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final lighter = Color.lerp(accent, Colors.white, 0.35)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed == null
              ? [KidsUi.muted, KidsUi.muted]
              : [accent, lighter],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                    color: accent.withValues(alpha: .35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Difficulty chooser ─────────────────────────────────────────────────────

Future<Difficulty?> chooseGameDifficulty(
    BuildContext context, String title, String Function(Difficulty) detail,
    {LearningMascot mascot = LearningMascot.boopli}) {
  var chosen = false;
  return showDialog<Difficulty>(
      context: context,
      builder: (ctx) => Theme(
          data: KidsUi.theme,
          child: AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    MascotGuide(
                        mascot: mascot, message: 'Choose your difficulty'),
                    const SizedBox(height: 16),
                    for (final d in Difficulty.values)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OutlinedButton(
                              onPressed: () {
                                if (chosen) return;
                                chosen = true;
                                Navigator.pop(ctx, d);
                              },
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(children: [
                                    Text(d.label,
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                    Text(detail(d),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 18)),
                                  ])))),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'))
              ])));
}

// ── Navigation guard ───────────────────────────────────────────────────────

class LearnerNavigation {
  static final Set<Object> _opening = {};
  static Future<void> open(BuildContext context, Widget page,
      {bool replace = false}) async {
    final navigator = Navigator.of(context);
    final Object source = context;
    if (!_opening.add(source)) return;
    try {
      final route = MaterialPageRoute<void>(builder: (_) => page);
      if (replace) {
        await navigator.pushReplacement(route);
      } else {
        await navigator.push(route);
      }
    } finally {
      _opening.remove(source);
    }
  }
}

// ── LearnerPage scaffold ───────────────────────────────────────────────────

class LearnerPage extends StatelessWidget {
  const LearnerPage(
      {super.key,
      required this.title,
      required this.child,
      this.onBack,
      this.showBack = true,
      this.bottom,
      this.scrollController});
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? bottom;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) => Theme(
      data: KidsUi.theme,
      child: Builder(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFFEEE9FF),
          appBar: AppBar(
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE6DCFF), Color(0xFFEEE9FF)],
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              foregroundColor: KidsUi.ink,
              title: Text(title,
                  style: const TextStyle(
                      fontSize: KidsUi.titleSize, fontWeight: FontWeight.bold)),
              automaticallyImplyLeading: false,
              leading: !showBack
                  ? null
                  : IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: onBack ?? () => Navigator.maybePop(ctx))),
          body: AdventureBackground(
              child: SafeArea(
                  top: false,
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(KidsUi.padding),
                              child: child))))),
          bottomNavigationBar:
              bottom == null ? null : SafeArea(top: false, child: bottom!),
        ),
      ));
}

// ── Progress header ────────────────────────────────────────────────────────

class GameProgressHeader extends StatelessWidget {
  const GameProgressHeader(
      {super.key,
      required this.current,
      required this.total,
      this.label = 'Question'});
  final int current, total;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const Text('Content unavailable.');
    final value = current.clamp(0, total);
    return Semantics(
        label: '$label $value of $total',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('$label $value of $total',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: value / total,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 16),
        ]));
  }
}

// ── Answer button (gradient when unanswered) ──────────────────────────────

class GameAnswerButton extends StatelessWidget {
  const GameAnswerButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.result,
      this.visual,
      this.selected = false,
      this.buttonKey});
  final String label;
  final VoidCallback? onPressed;
  final bool? result;
  final Widget? visual;
  final bool selected;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF7052CA);
    final color = result == true
        ? KidsUi.correct
        : result == false
            ? KidsUi.incorrect
            : accentColor;

    // Unanswered buttons get a subtle gradient; answered get colour tint
    final isUnanswered = result == null;
    final lighter = Color.lerp(accentColor, Colors.white, 0.72)!;

    return Padding(
        padding: const EdgeInsets.only(bottom: KidsUi.gap),
        child: Semantics(
          selected: selected,
          label: result == null
              ? label
              : '$label, ${result! ? 'Correct' : 'Nice try'}',
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: isUnanswered
                  ? LinearGradient(
                      colors: [Colors.white, lighter],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUnanswered ? null : color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: color.withValues(alpha: isUnanswered ? .25 : .50),
                  width: 2),
              boxShadow: isUnanswered
                  ? [
                      BoxShadow(
                          color: accentColor.withValues(alpha: .12),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: buttonKey,
                onTap: onPressed,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (visual != null) ...[
                      SizedBox(width: 64, child: visual!),
                      const SizedBox(height: 8)
                    ],
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Expanded(
                          child: Text(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: KidsUi.answerSize,
                                  fontWeight: FontWeight.bold,
                                  color: color))),
                      if (result != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                            result! ? Icons.check_circle : Icons.cancel_outlined,
                            color: color)
                      ],
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ));
  }
}

// ── Feedback row ───────────────────────────────────────────────────────────

class GameFeedback extends StatelessWidget {
  const GameFeedback({super.key, required this.correct, this.detail});
  final bool correct;
  final String? detail;

  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(correct ? Icons.check_circle : Icons.favorite_outline,
              color: correct ? KidsUi.correct : KidsUi.incorrect),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  '${correct ? 'Correct!' : 'Nice try! Keep practicing.'}${detail == null ? '' : '\n$detail'}',
                  style: TextStyle(
                      fontSize: 20,
                      color: correct ? KidsUi.correct : KidsUi.incorrect))),
        ]),
      ));
}

// ── Image card — PNG only, no emoji ──────────────────────────────────────

class GameImageCard extends StatelessWidget {
  const GameImageCard({
    super.key,
    @Deprecated('Ignored — images are resolved from word via WordImageService')
    this.emoji,
    this.assetPath,
    this.label,
    this.word,
    this.size = 160,
  });
  // emoji is kept for compile-compatibility but is never rendered
  final String? emoji;
  final String? assetPath, label, word;
  final double size;

  // Last-resort placeholder — shown only when WordImageService has no mapping
  Widget _placeholder() => Center(
        child: Icon(
          Icons.image_outlined,
          size: size * 0.45,
          color: const Color(0xFF9A71DD).withValues(alpha: .45),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Resolve: explicit path wins, then WordImageService lookup by word
    final resolvedPath =
        assetPath ?? (word != null ? WordImageService().imageFor(word!) : null);

    const blobColor = Color(0xFF9A71DD);

    final imageContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: resolvedPath == null
          ? KeyedSubtree(
              key: const ValueKey('placeholder'),
              child: _placeholder(),
            )
          : KeyedSubtree(
              key: ValueKey(resolvedPath),
              child: Image.asset(
                resolvedPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
            ),
    );

    return Semantics(
      label: label ?? word,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(children: [
          // Card shell with gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF3EEFF), Color(0xFFE6F9F5)],
                ),
                borderRadius: BorderRadius.circular(KidsUi.radius),
                boxShadow: [
                  BoxShadow(
                    color: blobColor.withValues(alpha: .18),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: blobColor.withValues(alpha: .22),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Decorative blob — bottom-right corner
          Positioned(
            bottom: 0,
            right: 0,
            width: size * 0.42,
            height: size * 0.42,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KidsUi.radius),
              child: CustomPaint(
                painter: _CardBlobPainter(
                  color: blobColor.withValues(alpha: .13),
                ),
              ),
            ),
          ),
          // Image fills card with padding
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * 0.09),
              child: imageContent,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────

class LearningStatusBadge extends StatelessWidget {
  const LearningStatusBadge({super.key, required this.status});
  final LearningStatus status;

  @override
  Widget build(BuildContext context) => Chip(
      avatar: Icon(status.icon,
          color:
              status == LearningStatus.mastered ? KidsUi.correct : KidsUi.ink),
      label: Text(status.label, style: const TextStyle(fontSize: 18)),
      backgroundColor: status.color.withValues(alpha: .15));
}

// ── Audio button (TTS — always available when voice is on) ─────────────────

class AudioButton extends StatefulWidget {
  const AudioButton(
      {super.key,
      required this.phrase,
      this.label = 'Hear Word',
      this.enabled = true});
  final String phrase, label;
  final bool enabled;

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> {
  bool _playing = false;
  int _attempt = 0;
  AppProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<AppProvider>();
  }

  @override
  void dispose() {
    if (_playing) unawaited(_provider?.phonicsAudio.stop());
    super.dispose();
  }

  @override
  void didUpdateWidget(AudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phrase != widget.phrase) {
      _attempt++;
      if (_playing) unawaited(_provider?.phonicsAudio.stop());
      _playing = false;
    }
  }

  Future<void> _play() async {
    if (_playing) return;
    final attempt = ++_attempt;
    final p = context.read<AppProvider>();
    setState(() => _playing = true);
    await p.voiceFeedback.stop();
    await p.audio.stop();
    if (!mounted || attempt != _attempt) return;
    await p.phonicsAudio.playInstruction(widget.phrase);
    if (!mounted || attempt != _attempt) return;
    setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final voiceOn = context.watch<AppProvider>().voiceEnabled;
    final enabled = widget.enabled && voiceOn;
    const accent = Color(0xFF7052CA);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Semantics(
          label: '${widget.label}: ${widget.phrase}',
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: enabled && !_playing
                  ? const LinearGradient(
                      colors: [Color(0xFF7052CA), Color(0xFF9A80E0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: enabled && !_playing ? null : KidsUi.muted.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(24),
              boxShadow: enabled && !_playing
                  ? [
                      BoxShadow(
                          color: accent.withValues(alpha: .30),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ]
                  : null,
              border: Border.all(
                  color: enabled
                      ? accent.withValues(alpha: .40)
                      : KidsUi.muted.withValues(alpha: .25),
                  width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: !enabled || _playing ? null : _play,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        _playing ? Icons.graphic_eq : Icons.volume_up,
                        color: enabled ? Colors.white : KidsUi.muted,
                        size: 22),
                    const SizedBox(width: 8),
                    Text(
                        _playing ? 'Playing…' : widget.label,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: enabled ? Colors.white : KidsUi.muted)),
                  ]),
                ),
              ),
            ),
          )),
      if (!voiceOn)
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Audio is turned off.', style: TextStyle(fontSize: 16)),
        ),
    ]);
  }
}

// ── Result dialog ──────────────────────────────────────────────────────────

class GameResultDialog extends StatefulWidget {
  const GameResultDialog(
      {super.key,
      required this.correct,
      required this.attempts,
      required this.earnedXp,
      required this.earnedStars,
      required this.onAgain,
      required this.onBack,
      this.backLabel = 'Back to Games'});
  final int correct, attempts, earnedXp, earnedStars;
  final VoidCallback onAgain, onBack;
  final String backLabel;

  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog> {
  bool _used = false;
  void _act(VoidCallback action) {
    if (_used) return;
    setState(() => _used = true);
    action();
  }

  @override
  Widget build(BuildContext context) => Theme(
      data: KidsUi.theme,
      child: PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Great Work!'),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.emoji_events_outlined,
                size: 56, color: KidsUi.correct),
            Text('Score: ${widget.correct} / ${widget.attempts}',
                style: const TextStyle(fontSize: 24)),
            Text(
                'Activity Accuracy: ${widget.attempts == 0 ? 'No attempts yet' : '${(widget.correct / widget.attempts * 100).round()}%'}'),
            const Text('Scored attempts, including retries.',
                style: TextStyle(fontSize: 16)),
            Text('XP Earned: +${widget.earnedXp}'),
            if (widget.earnedStars > 0)
              Text('Stars Earned: +${widget.earnedStars}'),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _used ? null : () => _act(widget.onAgain),
                    child: const Text('Play Again'))),
            SizedBox(
                width: double.infinity,
                child: TextButton(
                    onPressed: _used ? null : () => _act(widget.onBack),
                    child: Text(widget.backLabel))),
          ])),
        ),
      ));
}

// ── Game scaffold ──────────────────────────────────────────────────────────

class GameScaffold extends StatefulWidget {
  const GameScaffold(
      {super.key,
      required this.title,
      required this.instructions,
      required this.child,
      required this.hasProgress,
      this.current,
      this.total,
      this.progressLabel = 'Question',
      this.difficulty,
      this.mascot = LearningMascot.boopli,
      this.onLeave});
  final LearningMascot mascot;
  final String title, instructions, progressLabel;
  final Widget child;
  final bool hasProgress;
  final int? current, total;
  final Difficulty? difficulty;
  final VoidCallback? onLeave;

  @override
  State<GameScaffold> createState() => _GameScaffoldState();
}

class _GameScaffoldState extends State<GameScaffold> {
  bool _leaving = false, _allowPop = false;

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final leave = !widget.hasProgress ||
        await showDialog<bool>(
                context: context,
                builder: (ctx) => Theme(
                    data: KidsUi.theme,
                    child: AlertDialog(
                        title: const Text('Leave this game?'),
                        content: const Text('Your current round will end.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Leave')),
                        ]))) ==
            true;
    if (!mounted) return;
    if (leave) {
      widget.onLeave?.call();
      final p = context.read<AppProvider>();
      await p.phonicsAudio.stop();
      await p.voiceFeedback.stop();
      if (!mounted) return;
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _leaving = false;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: LearnerPage(
            title: widget.title,
            onBack: _leave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.current != null && widget.total != null)
                  GameProgressHeader(
                      current: widget.current!,
                      total: widget.total!,
                      label: widget.progressLabel),
                if (widget.difficulty != null)
                  Text(widget.difficulty!.label,
                      style:
                          const TextStyle(fontSize: 18, color: KidsUi.muted)),
                ExpansionTile(
                    initiallyExpanded: !widget.hasProgress,
                    tilePadding: EdgeInsets.zero,
                    title: const Text('How to Play',
                        style: TextStyle(fontSize: 18)),
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: MascotGuide(
                              mascot: widget.mascot,
                              message: widget.instructions))
                    ]),
                const SizedBox(height: 12),
                widget.child,
              ],
            )),
      );
}

// ── Game session mixin ─────────────────────────────────────────────────────

/// A per-play display ledger mirrors existing reward/answer writes unchanged.
/// No progress, streak, time-limit or reward formula is calculated here.
mixin GameSessionUi<T extends StatefulWidget> on State<T> {
  AppProvider? _audioProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioProvider = context.read<AppProvider>();
  }

  @override
  void dispose() {
    unawaited(_audioProvider?.phonicsAudio.stop());
    unawaited(_audioProvider?.audio.stop());
    super.dispose();
  }

  int earnedXp = 0, earnedStars = 0, scoredAttempts = 0, correctAttempts = 0;
  bool resultOpen = false;
  Future<void> _saved = Future.value();

  Future<void> get rewardsSaved => _saved;

  void awardGameXp(int value) {
    earnedXp += value;
    final p = context.read<AppProvider>();
    _saved = _saved.then((_) => p.addXP(value, announce: false));
  }

  void awardGameStar() {
    earnedStars++;
    final p = context.read<AppProvider>();
    _saved = _saved.then((_) => p.addStar());
  }

  void recordGameAnswer({required bool correct}) {
    scoredAttempts++;
    if (correct) correctAttempts++;
    context.read<AppProvider>().recordDailyAnswer(correct: correct);
  }

  void clearGameLedger() {
    earnedXp = 0;
    earnedStars = 0;
    scoredAttempts = 0;
    correctAttempts = 0;
    resultOpen = false;
  }

  Future<void> showGameResult(VoidCallback restart,
      {String backLabel = 'Back to Games'}) async {
    final navigator = Navigator.of(context);
    await _saved;
    if (!mounted) return;
    await context.read<AppProvider>().phonicsAudio.stop();
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => GameResultDialog(
            correct: correctAttempts,
            attempts: scoredAttempts,
            earnedXp: earnedXp,
            earnedStars: earnedStars,
            backLabel: backLabel,
            onAgain: () {
              navigator.pop();
              clearGameLedger();
              restart();
            },
            onBack: () {
              navigator.pop();
              navigator.pop();
            }));
  }
}

// end of file
