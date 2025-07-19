// Web stubs for dart:io functionality in logger
// This file provides empty implementations for web compatibility

class File extends FileSystemEntity {
  @override
  final String path;
  
  File(this.path);
  
  Future<bool> exists() async => false;
  @override
  Future<int> length() async => 0;
  Future<void> writeAsBytes(List<int> bytes) async {}
  Future<void> writeAsString(String contents) async {}
  Future<List<int>> readAsBytes() async => [];
  Future<String> readAsString() async => '';
  Future<void> delete() async {}
  Future<File> rename(String newPath) async => File(newPath);
  IOSink openWrite({FileMode mode = FileMode.write}) => const IOSink();
  @override
  DateTime lastModifiedSync() => DateTime.now();
}

class Directory extends FileSystemEntity {
  @override
  final String path;
  
  const Directory(this.path);
  
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Future<void> delete({bool recursive = false}) async {}
  Stream<FileSystemEntity> list() => const Stream.empty();
  @override
  Future<int> length() async => 0;
  @override
  DateTime lastModifiedSync() => DateTime.now();
}

abstract class FileSystemEntity {
  const FileSystemEntity();
  String get path;
  Future<int> length();
  DateTime lastModifiedSync();
}

enum FileMode { append, write }

class IOSink {
  const IOSink();
  void writeln(String line) {}
  Future<void> close() async {}
}

// Stub for path_provider
Future<Directory> getApplicationDocumentsDirectory() async {
  return const Directory('/tmp/docs');
} 