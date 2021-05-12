import 'dart:async';
import 'dart:io' as io;
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_audio_recorder_example/audio_wave.dart';

void main() {
  SystemChrome.setEnabledSystemUIOverlays([]);
  return runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: RecorderExample(),
        ),
      ),
    );
  }
}

class RecorderExample extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  RecorderExample({
    localFileSystem,
  }) : this.localFileSystem = localFileSystem ?? LocalFileSystem();

  @override
  State<StatefulWidget> createState() => new RecorderExampleState();
}

class RecorderExampleState extends State<RecorderExample> {
  Recording _current;
  FlutterAudioRecorder _recorder;
  RecordingStatus _currentStatus = RecordingStatus.Unset;
  ValueNotifier<List<AudioWaveBar>> _audioWaveBarNotifier;

  @override
  void initState() {
    super.initState();
    _initial();
    _audioWaveBarNotifier = ValueNotifier([]);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FlatButton(
                    onPressed: () {
                      switch (_currentStatus) {
                        case RecordingStatus.Initialized:
                          _startRecord();
                          break;
                        case RecordingStatus.Recording:
                          _pauseRecord();
                          break;
                        case RecordingStatus.Paused:
                          _resumeRecord();
                          break;
                        case RecordingStatus.Stopped:
                          _initial();
                          break;
                        default:
                          break;
                      }
                    },
                    child: _buildText(_currentStatus),
                    color: Colors.lightBlue,
                  ),
                ),
                FlatButton(
                  onPressed: _currentStatus != RecordingStatus.Unset ? _stopRecord : null,
                  child: new Text(
                    "Stop",
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blueAccent.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                FlatButton(
                  onPressed: onPlayAudio,
                  child: new Text("Play", style: TextStyle(color: Colors.white)),
                  color: Colors.blueAccent.withOpacity(0.5),
                ),
              ],
            ),
            ValueListenableBuilder(
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
                        '${_current?.duration?.toString().substring(0, _current?.duration?.toString()?.lastIndexOf('.'))}',
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
          ],
        ),
      ),
    );
  }

  _initial() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/flutter_audio_recorder_';
        io.Directory appDocDirectory;
        // io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDocDirectory.path + customPath + DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        _recorder = FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          _currentStatus = current.status;
          print(_currentStatus);
        });
      } else {
        Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  //Start recording status
  _startRecord() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer timer) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          timer.cancel();
        }
        var current = await _recorder.current(channel: 0);
        setState(() {
          Color _randomColor = Colors.primaries[Random().nextInt(Colors.primaries.length)];
          _current = current;
          _currentStatus = _current.status;
          _audioWaveBarNotifier.value.add(
            AudioWaveBar(height: _current?.metering?.averagePower?.toDouble()?.abs(), color: _randomColor),
          );
        });
      });
    } catch (e) {
      print(e);
    }
  }

  _resumeRecord() async {
    await _recorder.resume();
    setState(() {});
  }

  //Pause recording status
  _pauseRecord() async {
    await _recorder.pause();
    setState(() {});
  }

  //Stop recording status
  _stopRecord() async {
    var result = await _recorder.stop();
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration}");
    File file = widget.localFileSystem.file(result.path);
    print("File length: ${await file.length()}");
    setState(() {
      _current = result;
      _currentStatus = _current.status;
    });
  }

  Widget _buildText(RecordingStatus status) {
    var text = "";
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        text = 'Start';
        break;
      case RecordingStatus.Recording:
        text = 'Pause';
        break;
      case RecordingStatus.Paused:
        text = 'Resume';
        break;
      case RecordingStatus.Stopped:
        text = 'Init';
        break;
      default:
        break;
    }
    return Text(
      text,
      style: TextStyle(color: Colors.white),
    );
  }

  void onPlayAudio() async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(_current.path, isLocal: true);
  }
}
