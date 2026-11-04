import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/backup_document.dart';
import 'backup_service.dart';

class FilePickerBackupFileService implements BackupFileService {
  const FilePickerBackupFileService();

  @override
  Future<Uri?> save({required String fileName, required Uint8List bytes}) {
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/json',
    );
  }

  @override
  Future<Uint8List?> pick({required int maxBytes}) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    final fileLength = file.lengthSync() ?? await file.length();
    if (fileLength != null && fileLength > maxBytes) {
      throw const BackupFormatException(
        'O arquivo excede o limite de 10 MB. Escolha um backup menor.',
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw const BackupFormatException(
        'O arquivo excede o limite de 10 MB. Escolha um backup menor.',
      );
    }
    return bytes;
  }
}
