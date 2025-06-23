import 'package:flutter/material.dart';
import 'package:popil_clip_editor/popil_clip_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const EditorExample(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EditorExample extends StatefulWidget {
  const EditorExample({super.key});

  @override
  State<EditorExample> createState() => _EditorExampleState();
}

class _EditorExampleState extends State<EditorExample> {
  String? pickedPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('PopilClipEditor')),
        body: VoiceModulationEditor()

        //  pickedPath == null
        //     ? Center(
        //         child: ElevatedButton(
        //           onPressed: () async {
        //             final result = await FilePicker.platform.pickFiles(
        //               type: FileType.video,
        //             );
        //             if (result != null) {
        //               setState(() {
        //                 pickedPath = result.files.single.path!;
        //               });
        //             }
        //           },
        //           child: const Text('Pick a Video'),
        //         ),
        //       )
        //     : PopilClipEditor(videoFilePath: pickedPath!,onExport: (exportedPath) {
        //       print("exportedPath========> $exportedPath");
        //     },),
        );
  }
}
