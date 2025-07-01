import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> mergeVideosSideBySide(
    String video1Path, String video2Path) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final outputPath =
        '${dir.path}/side_by_side_${DateTime.now().millisecondsSinceEpoch}.mp4';

   final command = '-i "$video1Path" -i "$video2Path" '
        '-filter_complex "[0:v]scale=-1:720[vid1];[1:v]scale=-1:720[vid2];[vid1][vid2]hstack=inputs=2[v]" '
        '-map "[v]" -map "0:a?" -c:v libx264 -crf 23 -preset ultrafast "$outputPath"';

    final session = await FFmpegKit.execute(command);

    final outputFile = File(outputPath);
    if (outputFile.existsSync()) {
      return outputPath;
    } else {
      return null;
    }
  } catch (e) {
    print("Merge failed: $e");
    return null;
  }
}

