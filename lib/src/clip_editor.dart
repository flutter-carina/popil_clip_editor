import 'dart:async';
import 'dart:io';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:popil_clip_editor/src/widgets/filter_card.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';

import 'voice_modulation.dart';

class PopilClipEditor extends StatefulWidget {
  final String videoFilePath;

  final Function(String exportedPath)? onExport;

  const PopilClipEditor(
      {super.key, required this.videoFilePath, this.onExport});

  @override
  State<PopilClipEditor> createState() => _PopilClipEditorState();
}

class _PopilClipEditorState extends State<PopilClipEditor> {
  late String _videoPath;
  String _status = '';
  double _exportProgress = 0.0;
  VideoPlayerController? _controller;
  bool filterVisible = false;
  bool isTrimming = false;
  bool isLoading = true;
  final List<String> _tempFiles = [];
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoPath = widget.videoFilePath;

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final File videoFile = File(_videoPath);
    await _trimmer.loadVideo(videoFile: videoFile);
    _controller = _trimmer.videoPlayerController;
    // _controller = VideoPlayerController.file(videoFile);
    // await _controller!.initialize();
    isLoading = false;
    setState(() {});
    // _controller!.play();
  }

  Future<void> _performEdit(Function(VideoEditorBuilder editor) edit) async {
    isLoading = true;
    setState(() {});
    try {
      final builder = VideoEditorBuilder(videoPath: _videoPath);
      final result = await edit(builder).export();
      if (result != null) {
        _updateVideo(result);
        _status = 'Video processed: $result';
      }
    } catch (e) {
      _status = 'Error: $e';
    }
    isLoading = false;
    setState(() {});
  }

  Future<void> _updateVideo(String newPath) async {
    // Delete previous temp video if not original and exists
    if (_videoPath != widget.videoFilePath &&
        _videoPath != newPath &&
        File(_videoPath).existsSync()) {
      try {
        File(_videoPath).deleteSync();
      } catch (e) {
        print("Failed to delete temp file: $_videoPath");
      }
    }

    _tempFiles.add(newPath); // Track new temp video

    _controller?.dispose();
    await _trimmer.loadVideo(videoFile: File(newPath));
    _controller = _trimmer.videoPlayerController;
    _videoPath = newPath;
    setState(() {});
  }

  Future<String?> applyFilter(String inputPath, String filterType) async {
    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.mp4';

    String filterCommand;

    switch (filterType) {
      case 'grayscale':
        filterCommand = 'hue=s=0';
        break;
      case 'sepia':
        filterCommand =
            'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131';
        break;
      case 'invert':
        filterCommand = 'negate';
        break;

      case 'normal':
        return widget.videoFilePath;

      default:
        return null;
    }

    final command =
        '-i "$inputPath" -vf $filterCommand -preset ultrafast -y "$outputPath"';

    await FFmpegKit.execute(command);
    return outputPath;
  }

  Future<void> _handleFilter(String filterName) async {
    isLoading = true;
    _status = 'Applying $filterName filter...';
    setState(() {});

    final result = await applyFilter(_videoPath, filterName);
    if (result != null) {
      _status = 'Filter applied: $filterName';
      await _updateVideo(result);
    } else {
      _status = 'Filter application failed.';
    }
    isLoading = false;

    setState(() {});
  }

  Future<void> _exportWithProgress() async {
    final builder = VideoEditorBuilder(videoPath: _videoPath)
        .trim(
          startTimeMs: (_startValue).toInt(),
          endTimeMs: (_endValue).toInt(),
        )
        .compress(resolution: VideoResolution.p720);

    final result = await builder.export(
      onProgress: (progress) {
        setState(() {
          _exportProgress = progress;
          _status = 'Export progress: ${(progress * 100).toStringAsFixed(1)}%';
        });
      },
    );

    if (result != null) {
      _status = 'Export completed: $result';
      await _updateVideo(result);
      for (var path in _tempFiles) {
        if (path != result && File(path).existsSync()) {
          try {
            File(path).deleteSync();
          } catch (e) {
            print("Failed to delete: $path");
          }
        }
      }
      _tempFiles.clear();
      _tempFiles.add(result);
      if (widget.onExport != null) {
        widget.onExport!(result);
      }
    } else {
      _status = 'Export failed.';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          const SizedBox(height: 16),
          Text(_status, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          if (_exportProgress > 0)
            Column(
              children: [
                LinearProgressIndicator(value: _exportProgress),
                const SizedBox(height: 4),
                Text('${(_exportProgress * 100).toStringAsFixed(1)}%'),
              ],
            ),
          if (_controller != null && _controller!.value.isInitialized)
            Align(
              alignment: Alignment.center,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : FloatingActionButton(
                      backgroundColor: Colors.black12,
                      onPressed: () {
                        setState(() {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        });
                      },
                      child: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TrimViewer(
                trimmer: _trimmer,
                viewerHeight: 50.0,
                viewerWidth: MediaQuery.of(context).size.width,
                // maxVideoLength: const Duration(seconds: _trimmer.),
                onChangeStart: (value) => _startValue = value,
                onChangeEnd: (value) => _endValue = value,
                onChangePlaybackState: (value) {
                  print("onChangePlaybackState==> $value");
                  setState(() => _isPlaying = value);
                },
              ),
            ),
          ),
          Positioned(bottom: 75, child: _filters)
        ],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.movie_filter_outlined),
              tooltip: 'Filter',
              onPressed: () {
                setState(() {
                  filterVisible = !filterVisible;
                });
              },
            ),
            // IconButton(
            //   icon: const Icon(Icons.cut),
            //   tooltip: 'Trim',
            //   onPressed: () {
            //     setState(() {
            //       isTrimming = !isTrimming;
            //     });
            //     //   _performEdit(
            //     //   (e) =>
            //     //       e.trim(startTimeMs: 0, endTimeMs: 5000).speed(speed: 1.5),
            //     // );
            //   },
            // ),
            // IconButton(
            //   icon: const Icon(Icons.volume_off),
            //   tooltip: 'Remove Audio',
            //   onPressed: () => _performEdit((e) => e.removeAudio()),
            // ),
            // IconButton(
            //   icon: const Icon(Icons.crop_rotate),
            //   tooltip: 'Crop & Rotate',
            //   onPressed: () => _performEdit(
            //     (e) => e
            //         .crop(aspectRatio: VideoAspectRatio.ratio16x9)
            //         .rotate(degree: RotationDegree.degree90),
            //   ),
            // ),
            IconButton(
              icon: const Icon(Icons.music_note_rounded),
              tooltip: 'Voice Modulation',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoiceModulationEditor(),
                    ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.flip),
              tooltip: 'Flip Horizontal',
              onPressed: () => _performEdit(
                (e) => e.flip(flipDirection: FlipDirection.horizontal),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.upload),
              tooltip: 'Export with Progress',
              onPressed: _exportWithProgress,
            ),
          ],
        ),
      ),
    );
  }

  Widget get _filters => Visibility(
        visible: filterVisible,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filters",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                // scrollDirection: Axis.horizontal,
                children: [
                  FilterCardWidget(
                    label: 'Normal',
                    onTap: () => _handleFilter('normal'),
                  ),
                  FilterCardWidget(
                    label: 'Grayscale',
                    onTap: () => _handleFilter('grayscale'),
                  ),
                  FilterCardWidget(
                    label: 'Sepia',
                    onTap: () => _handleFilter('sepia'),
                  ),
                  FilterCardWidget(
                    label: 'Invert',
                    onTap: () => _handleFilter('invert'),
                  ),
                  // Add more FilterCards as needed
                ],
              ),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
