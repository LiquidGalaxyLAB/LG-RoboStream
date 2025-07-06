import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';

/// Handles file operations and command execution for Liquid Galaxy
class LGFileManager {
  final SSHClient _client;

  LGFileManager({required SSHClient client}) : _client = client;

  /// Sends a file from local assets to remote path
  Future<bool> sendFile(String localAssetPath, String remotePath) async {
    try {
      final ByteData data = await rootBundle.load(localAssetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      return await sendBytes(bytes, remotePath);
    } catch (e) {
      return false;
    }
  }

  /// Sends raw bytes to remote path
  Future<bool> sendBytes(Uint8List bytes, String remotePath) async {
    try {
      final sftp = await _client.sftp();
      final file = await sftp.open(remotePath, mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await file.writeBytes(bytes);
      await file.close();
      sftp.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Executes a command on the Liquid Galaxy system
  Future<bool> sendLGCommand(String command) async {
    try {
      await _client.run(command);
      return true;
    } catch (e) {
      return false;
    }
  }
}
