import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:instagram/core/resources/color_manager.dart';
import 'package:instagram/core/resources/strings_manager.dart';
import 'package:instagram/core/resources/styles_manager.dart';
import 'package:instagram/core/utility/constant.dart';

class RecordView extends StatefulWidget {
  final String urlRecord;
  final bool isThatMine;
  const RecordView(
      {Key? key, required this.urlRecord, required this.isThatMine})
      : super(key: key);

  @override
  RecordViewState createState() => RecordViewState();
}

class RecordViewState extends State<RecordView> {
  int? _totalDuration;
  int? _currentDuration;
  int _reverseDuration = 0;

  double _completedPercentage = 0.0;

  bool _isPlaying = false;
  AudioPlayer audioPlayer = AudioPlayer();
  @override
  Widget build(BuildContext context) {
    Color theColor = widget.isThatMine
        ? (isThatMobile ? ColorManager.white : Theme.of(context).focusColor)
        : Theme.of(context).focusColor;
    return widget.urlRecord.isEmpty
        ? Center(
            child: Text(
            StringsManager.noRecordsYet,
            style: Theme.of(context).textTheme.bodyText1,
          ))
        : Row(
            children: [
              GestureDetector(
                child: _isPlaying
                    ? buildIcon(Icons.pause_sharp,theColor)
                    : buildIcon(Icons.play_arrow_rounded,theColor),
                onTap: () => _onPlay(urlRecord: widget.urlRecord),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProgressBar(
                  timeLabelLocation: TimeLabelLocation.none,
                  thumbColor: theColor,
                  total: Duration(microseconds: _totalDuration ?? 0),
                  barHeight: 3,
                  thumbRadius: 6.0,
                  baseBarColor: widget.isThatMine
                      ? (isThatMobile?ColorManager.darkWhite:ColorManager.veryLowOpacityGrey)
                      : ColorManager.veryLowOpacityGrey,
                  progressBarColor: theColor,
                  progress: Duration(microseconds: _currentDuration ?? 0),
                ),
              ),
              const SizedBox(width: 15),
              if (_totalDuration != null && _currentDuration != null)
                Text(getReformatDate(), style: getNormalStyle(color: theColor)),
            ],
          );
  }

  String getReformatDate() {
    List<String> datesSeparated;
    if (_completedPercentage < 0.9) {
      datesSeparated = (((_reverseDuration * 0.000001) / 60).toStringAsFixed(2))
          .toString()
          .split(".");
    } else {
      datesSeparated = ((_totalDuration! * 0.000001) / 60)
          .toStringAsFixed(2)
          .toString()
          .split(".");
    }
    return "${datesSeparated[0]}:${datesSeparated[1]}";
  }

  Icon buildIcon(IconData icon,Color theColor) => Icon(icon,
      color:theColor,
      size: 30);

  Future<void> _onPlay({required String urlRecord}) async {
    if (!_isPlaying) {
      audioPlayer.play(UrlSource(urlRecord));
      setState(() {
        _isPlaying = true;
      });

      audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
        });
      });
      audioPlayer.onDurationChanged.listen((duration) {
        setState(() {
          _totalDuration = duration.inMicroseconds;
          _currentDuration = duration.inMicroseconds;
        });
      });

      audioPlayer.onPositionChanged.listen((duration) {
        setState(() {
          _currentDuration = duration.inMicroseconds;
          _completedPercentage =
              _currentDuration!.toDouble() / _totalDuration!.toDouble();
          _reverseDuration = _totalDuration! - _currentDuration!;
        });
      });
    } else {
      audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }
}
