import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
// Tambahkan ke pubspec.yaml: audioplayers: ^6.0.0 (atau versi terbaru)
import 'package:audioplayers/audioplayers.dart';

// ============================================================================
// ARSITEKTUR BARU (A2DP untuk speaker + SPP untuk mic/PTT)
// ----------------------------------------------------------------------------
// - Audio KE speaker (HP -> ESP32 -> MAX98357A) SEKARANG LEWAT A2DP, bukan
//   SPP lagi. Setelah HP pairing & terhubung ke "EMI_KOLAKA" (Android akan
//   otomatis mencoba menyambungkan semua profile yang didukung ESP32,
//   termasuk A2DP, begitu proses pairing selesai), ESP32 akan muncul sebagai
//   perangkat output audio Bluetooth biasa di sistem Android — seperti
//   speaker Bluetooth pada umumnya.
// - Karena itu, fungsi `streamWavFromAssets()` dan `streamWavFileToESP32()`
//   yang lama (kirim byte PCM manual lewat SPP) SUDAH TIDAK DIPERLUKAN LAGI
//   untuk audio ke speaker, dan telah dihapus dari versi ini.
// - Untuk memutar audio, kita cukup pakai `AudioPlayer` (audioplayers) dan
//   mainkan filenya secara normal. Routing ke ESP32 ditangani otomatis oleh
//   sistem operasi Android selama ESP32 masih menjadi active audio output
//   device (bisa dicek/dipilih manual di Quick Settings > Bluetooth kalau
//   ada lebih dari satu output audio yang aktif).
// - SPP (`connectToESP32`, `onDataReceived`, dst) TETAP DIPAKAI, tapi
//   sekarang cuma untuk: (1) menerima status tombol PTT dari ESP32, dan
//   (2) menerima audio mic INMP441 dari ESP32 untuk direkam di HP.
// ============================================================================

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const WalkieTalkieScreen(),
      theme: ThemeData.dark(),
    );
  }
}

class WalkieTalkieScreen extends StatefulWidget {
  const WalkieTalkieScreen({Key? key}) : super(key: key);
  @override
  State<WalkieTalkieScreen> createState() => _WalkieTalkieScreenState();
}

class _WalkieTalkieScreenState extends State<WalkieTalkieScreen> {
  BluetoothConnection? connection;
  bool isConnected = false;
  String pttStatus = "Dilepas (Standby)";
  List<int> rxBuffer = [];
  IOSink? wavFileSink;
  String? currentFilePath;
  int audioBytesRecorded = 0;
  bool isCurrentlyRecording = false;

  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlayingAudio = false;

  @override
  void dispose() {
    audioPlayer.dispose();
    connection?.dispose();
    super.dispose();
  }

  Future<void> playAudioViaA2DP() async {
    try {
      setState(() => isPlayingAudio = true);
      await audioPlayer.play(AssetSource('audio/loloia.wav'));
      audioPlayer.onPlayerComplete.listen((_) {
        setState(() => isPlayingAudio = false);
      });
    } catch (e) {
      print("Gagal memutar audio via A2DP: $e");
      setState(() => isPlayingAudio = false);
    }
  }

  Future<void> stopAudioViaA2DP() async {
    await audioPlayer.stop();
    setState(() => isPlayingAudio = false);
  }

  void connectToESP32() async {
    List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
    BluetoothDevice? espDevice;

    try {
      espDevice = bondedDevices.firstWhere((d) => d.name == "EMI_KOLAKA");
    } catch (_) {
      print("Device 'EMI_KOLAKA' tidak ditemukan di daftar pairing HP!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device 'EMI_KOLAKA' belum di-pairing!")),
      );
      return;
    }

    print("Mencoba menyambungkan ke ${espDevice.address}...");
    BluetoothConnection.toAddress(espDevice.address).then((conn) {
      setState(() {
        connection = conn;
        isConnected = true;
      });
      print("Sukses Terhubung ke ESP32!");

      connection!.input!.listen(onDataReceived).onDone(() {
        setState(() {
          isConnected = false;
        });
        print("Koneksi terputus dari sisi ESP32.");
      });
    }).catchError((error) {
      print("Gagal konek: $error");
    });
  }

  void onDataReceived(Uint8List data) {
    rxBuffer.addAll(data);

    while (rxBuffer.length >= 6) {
      if (rxBuffer[0] != 0xAA || rxBuffer[1] != 0x55) {
        rxBuffer.removeAt(0);
        continue;
      }

      int type = rxBuffer[2];
      int length = (rxBuffer[3] << 8) | rxBuffer[4];

      if (length < 0 || length > 1024) {
        rxBuffer.removeRange(0, 2);
        continue;
      }

      if (rxBuffer.length < 5 + length + 1) {
        break;
      }

      int footerIndex = 5 + length;
      if (rxBuffer[footerIndex] != 0xEE) {
        rxBuffer.removeRange(0, 2);
        continue;
      }

      List<int> payload = rxBuffer.sublist(5, 5 + length);
      rxBuffer.removeRange(0, 5 + length + 1);

      if (type == 0x02) {
        if (payload.isNotEmpty) {
          int buttonState = payload[0];

          setState(() {
            if (buttonState == 0x01) {
              if (!isCurrentlyRecording) {
                isCurrentlyRecording = true;
                pttStatus = "DITEKAN (MEREKAM...)";
                startWavRecording();
              }
            } else if (buttonState == 0x00) {
              if (isCurrentlyRecording) {
                isCurrentlyRecording = false;
                pttStatus = "Dilepas (Standby)";
                stopWavRecording();
              }
            }
          });
        }
      } else if (type == 0x01) {
        if (wavFileSink != null) {
          wavFileSink!.add(payload);
          audioBytesRecorded += payload.length;
        }
      }
    }
  }

  void startWavRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    currentFilePath = "${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.wav";
    File file = File(currentFilePath!);
    wavFileSink = file.openWrite();
    audioBytesRecorded = 0;

    Uint8List dummyHeader = Uint8List(44);
    wavFileSink!.add(dummyHeader);
    print("Mulai menulis file rekaman ke: $currentFilePath");
  }

  void stopWavRecording() async {
    if (wavFileSink == null) return;
    await wavFileSink!.close();
    wavFileSink = null;

    if (currentFilePath != null && audioBytesRecorded > 0) {
      try {
        final file = File(currentFilePath!);
        Uint8List wavHeader = createWavHeader(audioBytesRecorded);

        RandomAccessFile raf = await file.open(mode: FileMode.append);
        await raf.setPosition(0);
        await raf.writeFrom(wavHeader);
        await raf.close();

        print("HEADER WAV DI-UPDATE! Total Data Suara: $audioBytesRecorded Byte.");
      } catch (e) {
        print("Gagal memperbarui header WAV: $e");
      }
    }
  }

  Uint8List createWavHeader(int numBytes) {
    int sampleRate = 16000;
    int channels = 1;
    int byteRate = sampleRate * channels * 2;
    int totalDataLen = numBytes + 36;

    var header = ByteData(44);
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalDataLen, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, channels * 2, Endian.little);
    header.setUint16(34, 16, Endian.little);

    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, numBytes, Endian.little);

    return header.buffer.asUint8List();
  }

  // Memutar ulang file rekaman mic (hasil dari ESP32) lewat A2DP —
  // menggantikan streamWavFileToESP32() yang lama (kirim manual lewat SPP).
  Future<void> playRecordedFileViaA2DP() async {
    if (currentFilePath == null) {
      print("Belum ada rekaman tersimpan untuk diputar!");
      return;
    }

    File file = File(currentFilePath!);
    if (!await file.exists()) {
      print("File rekaman tidak ditemukan!");
      return;
    }

    try {
      setState(() => isPlayingAudio = true);
      await audioPlayer.play(DeviceFileSource(currentFilePath!));
      audioPlayer.onPlayerComplete.listen((_) {
        setState(() => isPlayingAudio = false);
      });
    } catch (e) {
      print("Gagal memutar file rekaman via A2DP: $e");
      setState(() => isPlayingAudio = false);
    }
  }

  void sendProtocolPacket(int type, Uint8List payload) {
    if (connection == null) return;
    int length = payload.length;

    BytesBuilder packet = BytesBuilder();
    packet.add([0xAA, 0x55]);
    packet.addByte(type);
    packet.addByte((length >> 8) & 0xFF);
    packet.addByte(length & 0xFF);
    packet.add(payload);
    packet.addByte(0xEE);

    connection!.output.add(packet.toBytes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EMI Mekongga Walkie-Talkie")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              size: 80,
              color: isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isConnected ? null : connectToESP32,
              child: Text(isConnected ? "Connected" : "Connect ke ESP32"),
            ),
            const SizedBox(height: 15),
            // ✅ PHASE 10: Tombol ini TIDAK digantung ke status SPP (isConnected),
            // karena playback audio sekarang lewat A2DP — jalur koneksi terpisah
            // dari SPP. Selama ESP32 sudah jadi output audio aktif di Android,
            // tombol ini akan langsung berbunyi lewat speaker MAX98357A.
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: isPlayingAudio ? stopAudioViaA2DP : playRecordedFileViaA2DP,
              child: Text(isPlayingAudio ? "Stop Audio" : "Putar Rekaman Terakhir (A2DP)"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: isPlayingAudio ? stopAudioViaA2DP : playAudioViaA2DP,
              child: Text(isPlayingAudio ? "Stop Audio" : "Putar Audio dari Assets (A2DP)"),
            ),
            const SizedBox(height: 40),
            const Text("Status Tombol PTT ESP32:", style: TextStyle(fontSize: 16)),
            Text(
              pttStatus,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: pttStatus.contains("DITEKAN") ? Colors.orange : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}