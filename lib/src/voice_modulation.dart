import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:popil_clip_editor/src/widgets/app_slider_shape.dart';
import 'widgets/app_toggle_switch.dart';

class VoiceModulationEditor extends StatefulWidget {
  final String videoPath;
  VoiceModulationEditor({super.key, required this.videoPath});

  @override
  State<VoiceModulationEditor> createState() => _VoiceModulationEditorState();
}

class _VoiceModulationEditorState extends State<VoiceModulationEditor> {
  double pitch = 1.0;
  double tempo = 1.0;
  double formant = 1.0;
  bool echo = false;
  bool reverb = false;
  bool distortion = false;
  String? selectedPreset;
  String? extractedAudio;
  String? outputAudio;
  String? outputVideo;
  bool isExtracting = true;
  bool isExporting = false;

  final player = AudioPlayer();

  // final List<String> presets = ['None', 'Robot', 'Alien', 'Monster', 'Radio'];
  // void applyPreset(String preset) {
  //   switch (preset) {
  //     case 'Robot':
  //       pitch = 0.7;
  //       tempo = 0.9;
  //       echo = true;
  //       distortion = true;
  //       break;
  //     case 'Alien':
  //       pitch = 1.5;
  //       tempo = 1.0;
  //       echo = true;
  //       reverb = true;
  //       break;
  //     case 'Monster':
  //       pitch = 0.5;
  //       tempo = 0.8;
  //       reverb = true;
  //       break;
  //     case 'Radio':
  //       pitch = 1.0;
  //       tempo = 1.0;
  //       distortion = true;
  //       break;
  //     case 'None':
  //       pitch = 1.0;
  //       tempo = 1.0;
  //       formant = 1.0;
  //       echo = false;
  //       reverb = false;
  //       distortion = false;
  //       break;
  //   }
  //   setState(() {});
  // }

  @override
  void initState() {
    super.initState();
    extractAudioFromVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2D3036),
      appBar: AppBar(title: const Text('Voice Modulator')),
      body: isExtracting || isExporting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    isExporting ? "Exporting..." : 'Extracting audio...',
                    style: const TextStyle(color: Colors.yellow, fontSize: 16),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // DropdownButtonHideUnderline(
                  //   child: DropdownButtonFormField<String>(
                  //     isExpanded: true,
                  //     decoration: const InputDecoration(
                  //       hintText: 'Select Voice Preset',
                  //       prefixIcon: Icon(Icons.mic),
                  //       border: OutlineInputBorder(),
                  //     ),
                  //     value: selectedPreset ?? 'None',
                  //     items: presets
                  //         .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  //         .toList(),
                  //     onChanged: (value) {
                  //       if (value != null) {
                  //         selectedPreset = value;
                  //         applyPreset(value);
                  //       }
                  //     },
                  //   ),
                  // ),
                  const SizedBox(height: 20),
                  _buildKarokeWidget,
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFEA500),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: processAudio,
                    child: const Text(
                      "Apply Effects",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (outputAudio != null)
                    ListTile(
                      tileColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () => playAudio(outputAudio!),
                      // leading: IconButton(
                      //   icon: Icon(
                      //     player.playing ? Icons.stop : Icons.play_arrow,
                      //     color: Colors.white,
                      //   ),
                      //   onPressed: () => playAudio(outputAudio!),
                      // ),
                      title: Text(
                        outputAudio?.split("/").last ?? '',
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEA500),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          setState(() {
                            isExporting = true;
                          });
                          await mergeAudioWithVideo();
                          setState(() {
                            isExporting = false;
                          });
                          Navigator.pop(context, outputVideo);
                        },
                        child: const Text(
                          "Export",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> playAudio(String path) async {
    if (player.playing) {
      await player.stop();
    } else {
      await player.setFilePath(path);
      await player.play();
    }
  }

  Widget get _buildKarokeWidget => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color(0xFFD9D9D9).withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                spacing: 10,
                children: [
                  Transform(
                    alignment: FractionalOffset.center,
                    transform: new Matrix4.identity()
                      ..rotateZ(270 * 3.1415927 / 180),
                    child: Column(
                      spacing: 5,
                      children: [
                        SliderTheme(
                          data: const SliderThemeData(
                            thumbShape: AppSliderShape(thumbRadius: 10),
                          ),
                          child: Slider(
                            value: pitch,
                            min: 0.5,
                            max: 2.0,
                            activeColor: Colors.black54,
                            inactiveColor: Colors.black54,
                            onChanged: (v) {
                              setState(() => pitch = v);
                            },
                          ),
                        ),
                        SliderTheme(
                          data: const SliderThemeData(
                            thumbShape: AppSliderShape(thumbRadius: 10),
                          ),
                          child: Slider(
                            value: tempo,
                            min: 0.5,
                            max: 2.0,
                            activeColor: Colors.black54,
                            inactiveColor: Colors.black54,
                            onChanged: (v) {
                              setState(() => tempo = v);
                            },
                          ),
                        ),
                        SliderTheme(
                          data: const SliderThemeData(
                            thumbShape: AppSliderShape(thumbRadius: 10),
                          ),
                          child: Slider(
                            value: formant,
                            min: 0.5,
                            max: 2.0,
                            activeColor: Colors.black54,
                            inactiveColor: Colors.black54,
                            onChanged: (v) {
                              setState(() => formant = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      spacing: 8,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: 28,
                          child: Text(
                            "Pitch\n${pitch.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 7.4, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Text(
                            "Tempo\n${tempo.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 7.4, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Text(
                            "Reverb\n${formant.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 7.4, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Column(
                spacing: 8,
                children: [
                  buildSwitch("Echo", echo, (v) => setState(() => echo = v)),
                  buildSwitch(
                      "Reverb", reverb, (v) => setState(() => reverb = v)),
                  buildSwitch(
                    "Distortion",
                    distortion,
                    (v) => setState(() => distortion = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget buildSwitch(String label, bool value, void Function(bool) onChanged) {
    return Row(
      children: [
        Text(
          label,
          textAlign: TextAlign.left,
          style: TextStyle(color: Colors.white),
        ),
        const Spacer(),
        AppToggleSwitch(
          value: value,
          onChanged: onChanged,
          assetPath: 'assets/toggle.png',
          assetPackage: 'popil_clip_editor',
        ),
      ],
    );
  }

  Future<void> extractAudioFromVideo() async {
    setState(() {
      isExtracting = true;
    });

    final dir = await getTemporaryDirectory();
    extractedAudio = '${dir.path}/extracted_audio.mp3';

    final cmd = '-y -i "${widget.videoPath}" -vn -acodec mp3 "$extractedAudio"';
    final session = await FFmpegKit.execute(cmd);

    final returnCode = await session.getReturnCode();
    debugPrint('FFmpeg return code: $returnCode');

    final outputFile = File(extractedAudio!);
    final fileExists = await outputFile.exists();
    debugPrint('Extracted file exists: $fileExists');

    if (fileExists) {
      final fileStat = await outputFile.stat();
      debugPrint('Extracted audio size: ${fileStat.size} bytes');
    }

    if (returnCode?.isValueSuccess() != true || !fileExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to extract audio from video')),
      );
      setState(() {
        isExtracting = false;
      });

      return;
    }

    setState(() {
      isExtracting = false;
    });
  }

  Future<void> processAudio() async {
    if (extractedAudio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio extracted from video')),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    outputAudio = '${dir.path}/modulated_audio.mp3';

    String filters = 'asetrate=44100*${pitch.toStringAsFixed(2)},';
    filters += 'atempo=${tempo.toStringAsFixed(2)}';

    if (echo) {
      filters += ',aecho=0.8:0.88:6:0.4';
    }
    if (reverb) {
      filters += ',aareverb';
    }
    if (distortion) {
      filters += ',acrusher=level_in=1:level_out=1:bits=8:mode=log';
    }

    final cmd =
        '-y -i "$extractedAudio" -af "$filters" -c:a libmp3lame -f mp3 "$outputAudio"';

    var session = await FFmpegKit.execute(cmd);

    final file = File(outputAudio!);
    if (!await file.exists() || await file.length() == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Audio processing failed')));
      return;
    }

    final returnCode = await session.getReturnCode();
    print("Return Code: $returnCode");

    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Processed audio to: $outputAudio')));
  }

  Future<void> mergeAudioWithVideo() async {
    if (outputAudio == null) return;

    final dir = await getTemporaryDirectory();
    final aacPath = '${dir.path}/converted_audio.aac';
    outputVideo = '${dir.path}/modulated_video.mp4';

    // Step 1: Convert MP3 to AAC
    final convertCmd = '-y -i "$outputAudio" -c:a aac -b:a 128k "$aacPath"';
    var convertSession = await FFmpegKit.execute(convertCmd);
    final convertReturnCode = await convertSession.getReturnCode();

    if (convertReturnCode?.isValueSuccess() != true) {
      final log = await convertSession.getAllLogsAsString();
      debugPrint('Audio conversion failed:\n$log');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to convert audio to AAC')),
      );
      return;
    }

    // Step 2: Merge converted AAC with video
    final mergeCmd =
        '-y -i "${widget.videoPath}" -i "$aacPath" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 "$outputVideo"';
    var mergeSession = await FFmpegKit.execute(mergeCmd);
    final mergeReturnCode = await mergeSession.getReturnCode();

    if (mergeReturnCode?.isValueSuccess() != true) {
      final log = await mergeSession.getAllLogsAsString();
      debugPrint('Merging failed:\n$log');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to merge audio with video')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Processed video saved to:\n$outputVideo')),
    );
    setState(() {});
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
