import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../app.dart';

const kAudioExt = {'.mp3', '.m4a', '.aac', '.wav', '.ogg', '.oga', '.opus', '.flac', '.amr'};
const kVideoExt = {'.mp4', '.mov', '.webm', '.mkv', '.avi', '.3gp', '.m4v'};
const kMediaExt = {...kAudioExt, ...kVideoExt};

class MediaViewerPage extends StatefulWidget {
  const MediaViewerPage({super.key, required this.state, required this.path});
  final AppState state;
  final String path;
  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  late final bool _isVideo = kVideoExt.contains(_ext(widget.path));
  final _audio = AudioPlayer();
  VideoPlayerController? _video;
  bool _initFailed = false;
  String? _error;

  static String _ext(String p) =>
      p.contains('.') ? p.substring(p.lastIndexOf('.')).toLowerCase() : '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = File(widget.path);
    try {
      if (_isVideo) {
        _video = VideoPlayerController.file(file);
        await _video!.initialize();
        _video!.setLooping(true);
        await _video!.play();
        setState(() {});
      } else {
        await _audio.setAudioSource(
          AudioSource.file(widget.path),
          preload: true,
        );
      }
    } catch (e) {
      setState(() {
        _initFailed = true;
        _error = '$e';
      });
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.path.split(Platform.pathSeparator).last;
    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: _initFailed ? _errorView(name) : (_isVideo ? _videoView() : _audioView(name)),
    );
  }

  Widget _errorView(String name) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_disabled_rounded, size: 64),
              const SizedBox(height: 12),
              Text(tr(widget.state, 'Не удалось открыть', 'Cannot open') + ' $name',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Text(tr(widget.state,
                  'Кодек может поддерживаться только системным плеером.',
                  'This codec may only be supported by the system player.')),
            ],
          ),
        ),
      );

  Widget _videoView() {
    final v = _video!;
    return Center(
      child: AspectRatio(
        aspectRatio: v.value.aspectRatio == 0 ? 16 / 9 : v.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(v),
            if (!v.value.isPlaying)
              const Positioned(
                child: Icon(Icons.play_circle_fill_rounded, size: 72, color: Colors.white70),
              ),
            if (v.value.isInitialized)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: v,
                  builder: (_, val, __) {
                    final pos = val.position;
                    final total = val.duration;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(v, allowScrubbing: true),
                        Row(
                          children: [
                            IconButton(
                              color: Colors.white,
                              icon: Icon(val.isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded),
                              onPressed: () => val.isPlaying ? v.pause() : v.play(),
                            ),
                            Text(_fmt(pos)),
                            const Spacer(),
                            Text(_fmt(total), style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _audioView(String name) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.6),
            scheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _albumArt(name),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: _audio.positionStream,
                builder: (_, posSnap) => StreamBuilder<Duration?>(
                  stream: _audio.durationStream,
                  builder: (_, durSnap) {
                    final dur = durSnap.data ?? Duration.zero;
                    final pos = posSnap.data ?? Duration.zero;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Slider(
                          value: dur.inMilliseconds == 0
                              ? 0
                              : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0),
                          onChanged: dur.inMilliseconds == 0
                              ? null
                              : (v) => _audio.seek(Duration(milliseconds: (v * dur.inMilliseconds).round())),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text(_fmt(pos)), Text(_fmt(dur))],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 36,
                              onPressed: () => _audio.seek(_audio.position - const Duration(seconds: 10)),
                              icon: const Icon(Icons.replay_10_rounded),
                            ),
                            const SizedBox(width: 24),
                            StreamBuilder<PlayerState>(
                              stream: _audio.playerStateStream,
                              builder: (_, snap) {
                                final playing = snap.data?.playing ?? false;
                                return AnimatedScale(
                                  scale: playing ? 1.05 : 1.0,
                                  duration: const Duration(milliseconds: 220),
                                  child: Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [scheme.primary, scheme.tertiary],
                                      ),
                                      boxShadow: [
                                        BoxShadow(color: scheme.primary.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 2)
                                      ],
                                    ),
                                    child: IconButton(
                                      iconSize: 44,
                                      color: Colors.white,
                                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                      onPressed: () => playing ? _audio.pause() : _audio.play(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              iconSize: 36,
                              onPressed: () => _audio.seek(_audio.position + const Duration(seconds: 10)),
                              icon: const Icon(Icons.forward_10_rounded),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _albumArt(String name) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<bool>(
      stream: _audio.playerStateStream.map((s) => s.playing),
      builder: (_, snap) {
        final playing = snap.data ?? false;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: playing ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          builder: (_, v, child) => Transform.scale(
            scale: 1 + 0.04 * v,
            child: child,
          ),
          child: AnimatedRotation(
            turns: playing ? 1 : 0,
            duration: const Duration(seconds: 20),
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary.withValues(alpha: .85), const Color(0xff0d1020)],
                ),
                boxShadow: [
                  BoxShadow(color: scheme.primary.withValues(alpha: .35), blurRadius: 40, spreadRadius: 6)
                ],
              ),
              child: Center(
                child: Icon(Icons.audiotrack_rounded, size: 72, color: Colors.white.withValues(alpha: .85)),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
