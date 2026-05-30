import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/safety_model.dart';

class SafetyStorageService {
  static const String _contactsKey = 'trusted_contacts';
  static const String _checklistKey = 'safety_checklist';

  // --- Trusted Contacts ---
  
  Future<List<TrustedContact>> getTrustedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString(_contactsKey);
    if (contactsJson == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(contactsJson);
      return decoded.map((e) => TrustedContact.fromMap(e)).toList();
    } catch (e) {
      print('Error parsing contacts: $e');
      return [];
    }
  }

  Future<void> saveTrustedContacts(List<TrustedContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(contacts.map((e) => e.toMap()).toList());
    await prefs.setString(_contactsKey, encoded);
  }

  Future<void> addContact(TrustedContact contact) async {
    final contacts = await getTrustedContacts();
    if (contacts.length >= 5) {
      throw Exception('Maximum 5 trusted contacts allowed');
    }
    contacts.add(contact);
    await saveTrustedContacts(contacts);
  }

  Future<void> deleteContact(String id) async {
    final contacts = await getTrustedContacts();
    contacts.removeWhere((c) => c.id == id);
    await saveTrustedContacts(contacts);
  }

  // --- Safety Checklist ---

  Future<List<ChecklistItem>> getChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final String? checklistJson = prefs.getString(_checklistKey);
    
    if (checklistJson == null) {
      return _getDefaultChecklist();
    }
    
    try {
      final List<dynamic> decoded = json.decode(checklistJson);
      return decoded.map((e) => ChecklistItem.fromMap(e)).toList();
    } catch (e) {
      print('Error parsing checklist: $e');
      return _getDefaultChecklist();
    }
  }

  Future<void> saveChecklist(List<ChecklistItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(items.map((e) => e.toMap()).toList());
    await prefs.setString(_checklistKey, encoded);
  }

  Future<void> toggleChecklistItem(String id, bool isCompleted) async {
    final items = await getChecklist();
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      items[index] = items[index].copyWith(isCompleted: isCompleted);
      await saveChecklist(items);
    }
  }
  
  Future<void> resetChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checklistKey);
  }

  List<ChecklistItem> _getDefaultChecklist() {
    return [
      ChecklistItem(id: '1', title: 'Share flight details with trusted contacts'),
      ChecklistItem(id: '2', title: 'Save destination country emergency number'),
      ChecklistItem(id: '3', title: 'Download offline maps for destination'),
      ChecklistItem(id: '4', title: 'Note hotel/accommodation address'),
      ChecklistItem(id: '5', title: 'Charge phone to 100% before boarding'),
      ChecklistItem(id: '6', title: 'Enable location sharing with trusted contact'),
      ChecklistItem(id: '7', title: 'Research local customs and dress code'),
      ChecklistItem(id: '8', title: 'Have local currency ready'),
      ChecklistItem(id: '9', title: 'Know nearest hospital/clinic at destination'),
      ChecklistItem(id: '10', title: 'Screenshot your boarding pass'),
    ];
  }
}
