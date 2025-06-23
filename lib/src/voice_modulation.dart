import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:popil_clip_editor/src/widgets/app_slider_shape.dart';
import '../popil_clip_editor.dart';

class VoiceModulationEditor extends StatefulWidget {
  const VoiceModulationEditor({super.key});

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
  String? inputAudio;
  String? outputAudio;

  final List<String> presets = ['None', 'Robot', 'Alien', 'Monster', 'Radio'];

  final player = AudioPlayer();

  void applyPreset(String preset) {
    switch (preset) {
      case 'Robot':
        pitch = 0.7;
        tempo = 0.9;
        echo = true;
        distortion = true;
        break;
      case 'Alien':
        pitch = 1.5;
        tempo = 1.0;
        echo = true;
        reverb = true;
        break;
      case 'Monster':
        pitch = 0.5;
        tempo = 0.8;
        reverb = true;
        break;
      case 'Radio':
        pitch = 1.0;
        tempo = 1.0;
        distortion = true;
        break;
      case 'None':
        pitch = 1.0;
        tempo = 1.0;
        formant = 1.0;
        echo = false;
        reverb = false;
        distortion = false;
        break;
    }
    setState(() {});
  }

  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      inputAudio = result.files.single.path!;
      setState(() {});
    }
  }

  Future<void> processAudio() async {
    if (inputAudio == null) return;

    print("InputPath $inputAudio");

    final dir = await getApplicationDocumentsDirectory();
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

     final cmd = '-y -i "$inputAudio" -af "$filters" -c:a libmp3lame -f mp3 "$outputAudio"';

    var session = await FFmpegKit.execute(cmd);

    final returnCode = await session.getReturnCode();
    print("Return Code: $returnCode");

    print("session $session");
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Processed to: $outputAudio')));
  }

  Widget buildSwitch(String label, bool value, void Function(bool) onChanged) {
    return Row(
      children: [
        Text(
          label,
          textAlign: TextAlign.left,
        ),
        const Spacer(),
        customSwitch(value, onChanged)
      ],
    );
  }

  Widget customSwitch(bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: SizedBox(
        height: 40,
        width: 65,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: value ? Colors.black26 : Colors.grey.shade400,
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: value ? 0 : null,
              right: value ? null : 0,
              child: Image.asset(
                'assets/toggle.png',
                package: 'popil_clip_editor',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Modulator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: pickAudio,
              child: const Text("🎙️ Pick Voice Recording"),
            ),
            if (inputAudio != null)
              Text("Selected: ${inputAudio?.split("/").last}",
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedPreset ?? 'None',
                items: presets
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedPreset = value;
                    applyPreset(value);
                  }
                },
              ),
            ),
            // Divider(),
            _buildKarokeWidget,
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: processAudio,
              icon: const Icon(Icons.tune),
              label: const Text("Apply Effects"),
            ),
            if (outputAudio != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text("▶️ Preview"),
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => playAudio(outputAudio!),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      outputAudio?.split("/").last ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> playAudio(String path) async {
    print("playerpath $path");
    await player.setFilePath(path);
    await player.play();
  }

  Widget get _buildKarokeWidget => Container(
        padding: const EdgeInsets.all(10),
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
                            style: const TextStyle(fontSize: 7.4),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Text(
                            "Tempo\n${tempo.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 7.4),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Text(
                            "Reverb\n${formant.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 7.4),
                            textAlign: TextAlign.center,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            // Container(
            //     padding: const EdgeInsets.only(
            //         top: 3, bottom: 3, left: 10, right: 10),
            //     decoration: BoxDecoration(
            //         // gradient: AppColors.primaryBgGradient(),
            //         borderRadius: BorderRadius.circular(8)),
            //     child: Column(
            //       mainAxisSize: MainAxisSize.min,
            //       children: List.generate(
            //         5,
            //         (index) => Padding(
            //           padding: EdgeInsets.symmetric(vertical: 2.px),
            //           child: SizedBox(
            //             width: 30.px,
            //             height: 30.px,
            //             child: NeumorphicButton(
            //               style: NeumorphicStyle(
            //                 shape: NeumorphicShape.convex,
            //                 color: const Color.fromARGB(137, 0, 0, 0),
            //                 border: NeumorphicBorder(
            //                     color: Colors.black, width: 2.px),
            //                 boxShape: const NeumorphicBoxShape.circle(),
            //               ),
            //               padding: EdgeInsets.zero,
            //               child: Center(
            //                 child: Text(
            //                   (index - 2).toString(),
            //                   style: TextStyle(
            //                     fontSize: 11.px, // Fixed font size
            //                     color: Colors.white,
            //                   ),
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     )),
            Flexible(
              child: Column(
                spacing: 8,
                children: [
                  buildSwitch(
                    "Echo",
                    echo,
                    (v) => setState(() => echo = v),
                  ),
                  buildSwitch(
                    "Reverb",
                    reverb,
                    (v) => setState(() => reverb = v),
                  ),
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
}
