import 'dart:async';
import 'dart:io' as io;
import 'package:audioplayers/audioplayers.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_wave.dart';

class JCAudioWave extends StatefulWidget {
  final String audioLocalPath;
  final GestureLongPressCallback onLongPress;
  final GestureLongPressEndCallback onLongPressEnd;

  JCAudioWave({
    @required this.audioLocalPath,
    @required this.onLongPress,
    @required this.onLongPressEnd,
  });

  @override
  State<StatefulWidget> createState() => new JCAudioWaveState();
}

class JCAudioWaveState extends State<JCAudioWave> {
  Recording _current;
  FlutterAudioRecorder _recorder;
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  ValueNotifier<List<AudioWaveBar>> _audioWaveBarNotifier;
  LocalFileSystem localFileSystem;

  @override
  void initState() {
    super.initState();
    localFileSystem = localFileSystem ?? LocalFileSystem();
    _initialRecord();
    _audioWaveBarNotifier = ValueNotifier([]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _startRecord();
      },
      onLongPressEnd: (_) {
        _audioWaveBarNotifier.value.clear();
        _stopRecord();
      },
      child: Container(
        child: ValueListenableBuilder(
          valueListenable: _audioWaveBarNotifier,
          builder: (_, List<AudioWaveBar> audioWaveBar, __) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.3,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: AudioWave(
                      height: 50,
                      width: 300,
                      spacing: 2.5,
                      animationLoop: 100,
                      bars: audioWaveBar,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_current?.duration?.toString()?.substring(0, _current?.duration?.toString()?.lastIndexOf('.'))}',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _initialRecord() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/flutter_audio_recorder_';
        io.Directory appDirectory;

        if (io.Platform.isIOS) {
          appDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDirectory.path + customPath + DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        _recorder = FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          _currentStatus = current.status;
        });
      } else {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text("You must accept permissions")));
      }
    } catch (e) {
      print('JC Audio Wave Error: $e');
    }
  }

  _startRecord() async {
    try {
      await _recorder.start();
      var _currentRecordingStatus = await _recorder.current(channel: 0);
      setState(() {
        _current = _currentRecordingStatus;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer timer) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          timer.cancel();
        }

        var current = await _recorder.current(channel: 0);

        setState(() {
          _current = current;
          _currentStatus = _current.status;
          _audioWaveBarNotifier.value.add(
            AudioWaveBar(
              height: _current?.metering?.averagePower?.toDouble()?.abs() ?? 0,
              color: Colors.white,
            ),
          );
        });
      });
    } catch (e) {
      print('JC Audio Wave Error: $e');
    }
  }

  _resumeRecord() async {
    await _recorder.resume();
    setState(() {});
  }

  _pauseRecord() async {
    await _recorder.pause();
    setState(() {});
  }

  _stopRecord() async {
    var result = await _recorder.stop();
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration}");
    File file = localFileSystem.file(result.path);
    print("File length: ${await file.length()}");
    print("File length: ${result.path}");
    setState(() {
      _current = result;
      _currentStatus = _current.status;
    });
  }

  void onPlayAudio() async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(_current.path, isLocal: true);
  }
}
