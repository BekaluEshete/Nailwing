import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../model/safety_model.dart';
import 'safety_storage_service.dart';

class SafetyActionService {
  final SafetyStorageService _storageService = SafetyStorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- SOS & SMS Actions ---

  Future<void> sendSOSToTrustedContacts(String userName, String airportCode, String flightNumber) async {
    final contacts = await _storageService.getTrustedContacts();
    if (contacts.isEmpty) return;

    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final message = "$userName needs help. She was last at $airportCode at $timeStr. Flight: $flightNumber";

    await _sendBulkSms(contacts, message);
  }

  Future<void> shareFlightDetails(String userName, String flightNumber, String destination) async {
    final contacts = await _storageService.getTrustedContacts();
    if (contacts.isEmpty) return;

    final message = "Flight Update from $userName: I'm boarding flight $flightNumber to $destination.";
    await _sendBulkSms(contacts, message);
  }

  Future<void> sendArrivalMessage(String userName, String destination) async {
    final contacts = await _storageService.getTrustedContacts();
    if (contacts.isEmpty) return;

    final message = "Update from $userName: I've arrived safely in $destination!";
    await _sendBulkSms(contacts, message);
  }

  Future<void> _sendBulkSms(List<TrustedContact> contacts, String message) async {
    final phoneNumbers = contacts.map((c) => c.phoneNumber).join(',');
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumbers,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch SMS');
    }
  }
  
  Future<void> callEmergencyNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // --- Fake Call Actions ---

  void playRingtone() async {
    // Attempt to play a default system ringtone or a bundled asset.
    // If you add a ringtone to assets, use: await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
    // Since we don't have a specific asset yet, we might use a generic sound or just rely on vibration if no asset.
    try {
       // We will try to play a generic ringtone if available
       // await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
    } catch(e) {
      print("Audio player error: $e");
    }
  }

  void stopRingtone() async {
    try {
      await _audioPlayer.stop();
    } catch(e) {
      print("Audio player stop error: $e");
    }
  }
}
