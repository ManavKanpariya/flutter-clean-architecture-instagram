import 'package:flutter/material.dart';
import 'package:instagram/core/resources/color_manager.dart';
import 'package:video_player/video_player.dart';

class PlayThisVideo extends StatefulWidget {
  final String videoUrl;
  final bool play;
  final bool withoutSound;

  const PlayThisVideo({
    Key? key,
    required this.videoUrl,
    this.withoutSound = false,
    required this.play,
  }) : super(key: key);
  @override
  PlayThisVideoState createState() => PlayThisVideoState();
}

class PlayThisVideoState extends State<PlayThisVideo> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {});
    });

    if (widget.play) {
      _controller.play();
      _controller.setLooping(true);

      if (widget.withoutSound) {
        _controller.setVolume(0);
      } else {
        _controller.setVolume(1);
      }
    }
    super.initState();
  }

  @override
  void didUpdateWidget(PlayThisVideo oldWidget) {
    if (oldWidget.play != widget.play) {
      if (widget.play) {
        _controller.play();
        _controller.setLooping(true);
        setState(() {
          if (widget.withoutSound) {
            _controller.setVolume(0);
          }
        });
      } else {
        _controller.pause();
      }
    }
    if (widget.withoutSound) {
      _controller.setVolume(0);
    } else {
      _controller.setVolume(1);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: 0.65,
            child: VideoPlayer(_controller),
          );
        } else {
          return AspectRatio(
              aspectRatio: 0.65,
              child: Container(color: ColorManager.lowOpacityGrey));
        }
      },
    );
  }
}
