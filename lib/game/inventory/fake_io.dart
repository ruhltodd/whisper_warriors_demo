// lib/game/inventory/fake_io.dart

class File {
  File(String path); // Dummy constructor
  bool existsSync() {
    return false;
  } // Dummy method

  Future<String> readAsString() async {
    return '';
  } // Dummy method

  Future<File> writeAsString(String contents) async {
    return this;
  } // Dummy method
}
