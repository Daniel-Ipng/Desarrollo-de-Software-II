import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final _picker = ImagePicker();

  static Future<File?> seleccionarImagen({
    ImageSource fuente = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? calidad, // 0-100
  }) async {
    final XFile? imagen = await _picker.pickImage(
      source: fuente,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: calidad ?? 85,
    );
    return imagen != null ? File(imagen.path) : null;
  }

  static Future<List<File>> seleccionarMultiple({int limite = 5}) async {
    final List<XFile> imagenes =
        await _picker.pickMultiImage(imageQuality: 80, limit: limite);
    return imagenes.map((x) => File(x.path)).toList();
  }

  static Future<File?> grabarVideo({Duration? duracionMaxima}) async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: duracionMaxima,
    );
    return video != null ? File(video.path) : null;
  }
}
