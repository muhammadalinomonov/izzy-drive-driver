import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mechanic/assets/colors/colors.dart';

class VoiceMessageItem extends StatefulWidget {
  const VoiceMessageItem({super.key, required this.audioUrl});

  final String audioUrl;

  @override
  State<VoiceMessageItem> createState() => _VoiceMessageItemState();
}

class _VoiceMessageItemState extends State<VoiceMessageItem> {
  late final PlayerController _waveController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isUserSeeking = false;

  @override
  void initState() {
    super.initState();
    _initAudio();

    _audioPlayer.positionStream.listen((position) {
      if (!_isUserSeeking) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() => _duration = duration);
      }
    });

    // 🔥 Audio tugaganda qayta reset qilish
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero; // boshiga qaytadi
        });
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
  }


  Future<void> _initAudio() async {
    await _audioPlayer.setUrl(widget.audioUrl);
    // await _audioPlayer.play();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlayPause,
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: AlwaysStoppedAnimation(_isPlaying ? 1 : 0),
            ),
          ),
          SizedBox(width: 12),
          Slider(
            value: _position.inMilliseconds.toDouble(),
            max: _duration.inMilliseconds.toDouble() + 10,
            onChangeStart: (_) {
              setState(() => _isUserSeeking = true);
            },
            onChanged: (value) {
              setState(() => _position = Duration(milliseconds: value.toInt()));
            },
            onChangeEnd: (value) {
              _audioPlayer.seek(Duration(milliseconds: value.toInt()));
              setState(() => _isUserSeeking = false);
            },
          ),
          // AudioFileWaveforms(
          //   size: const Size(150, 19),
          //   playerController: _waveController,
          //   waveformType: WaveformType.fitWidth,
          //   waveformData: const [1, .5, 0, .5, 1, .5, 0, .5, 1, .5, 0, 0, .5, 1, .5, 0, .5, 1, .5, 0, .5, 1, .5, 0],
          //   playerWaveStyle: const PlayerWaveStyle(
          //     fixedWaveColor: slateGrey,
          //     liveWaveColor: Colors.blue,
          //     backgroundColor: Colors.red,
          //     showSeekLine: false,
          //     seekLineColor: Colors.black54,
          //     showBottom: true,
          //     showTop: true,
          //   ),
          //   enableSeekGesture: false,
          //   animationCurve: Curves.easeOut,
          // ),
          const SizedBox(width: 6),
          Text(
            _formatTime(_duration - _position),
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }


  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    _isPlaying = !_isPlaying;
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    super.dispose();
  }
}
