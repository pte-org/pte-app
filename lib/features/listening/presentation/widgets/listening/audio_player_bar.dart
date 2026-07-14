import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerBar extends StatefulWidget {
  final String? audioUrl;
  final int maxPlayCount;

  const AudioPlayerBar({
    super.key,
    this.audioUrl,
    this.maxPlayCount = 2, // Defaulting to 2 as per standard Aptis test
  });

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  late final AudioPlayer _player;
  int _playCount = 0;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  bool _isHandlingCompletion = false;

  Future<void> _initAudio() async {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) return;
    
    try {
      await _player.setUrl(widget.audioUrl!);
      if (mounted) {
        setState(() {
          _isPlayerReady = true;
        });
      }
      
      _player.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed && !_isHandlingCompletion) {
          _isHandlingCompletion = true;
          
          await _player.pause();
          await _player.seek(Duration.zero);
          
          if (mounted) {
            setState(() {
              _playCount++;
            });
          }
          
          // Release guard after a short delay to prevent double-firing from stream
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _isHandlingCompletion = false;
          });
        }
      });
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_isPlayerReady || _playCount >= widget.maxPlayCount) return;

    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLocked = _playCount >= widget.maxPlayCount;

    return Container(
      height: AppDimensions.audioPlayerHeight,
      color: AppColors.accentRed,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.examPagePaddingHorizontal,
      ),
      child: Row(
        children: [
          IconButton(
            icon: StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;
                
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return const SizedBox(
                    width: AppDimensions.audioPlayerIconSize,
                    height: AppDimensions.audioPlayerIconSize,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  );
                } else if (playing != true) {
                  return Icon(
                    Icons.play_arrow,
                    color: isLocked ? Colors.white54 : Colors.white,
                    size: AppDimensions.audioPlayerIconSize,
                  );
                } else {
                  return const Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: AppDimensions.audioPlayerIconSize,
                  );
                }
              },
            ),
            onPressed: isLocked ? null : _togglePlay,
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _player.duration ?? Duration.zero;
                
                double progress = 0.0;
                if (duration.inMilliseconds > 0) {
                  progress = position.inMilliseconds / duration.inMilliseconds;
                }
                
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                );
              },
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          Text(
            '$_playCount / ${widget.maxPlayCount}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
