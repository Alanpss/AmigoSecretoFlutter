import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver para executar os testes de integração no Chrome.
Future<void> main() async {
  try {
    await integrationDriver(
      onScreenshot: (String? name, List<int> bytes, [dynamic args]) =>
          Future.value(true),
    );
  } on driver.DriverError {
    rethrow;
  }
}
