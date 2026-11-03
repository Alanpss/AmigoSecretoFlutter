import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Abre o banco em arquivo nas plataformas com sistema de arquivos.
Future<Database> openAppDatabase() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final appDirectory = Directory(
    '${supportDirectory.path}${Platform.pathSeparator}amigo_secreto',
  );
  await appDirectory.create(recursive: true);

  final databasePath =
      '${appDirectory.path}${Platform.pathSeparator}amigo_secreto.db';
  return databaseFactoryIo.openDatabase(databasePath);
}
