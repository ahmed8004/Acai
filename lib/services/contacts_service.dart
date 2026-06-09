import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contactsServiceProvider = Provider<ContactsService>((ref) {
  return ContactsService();
});

class ContactsService {
  static const MethodChannel _channel = MethodChannel('com.ac.ai/contacts');

  Future<List<Contact>> getContacts({String? query}) async {
    try {
      final result = await _channel.invokeMethod<String>('getContacts', {
        'query': query,
      });
      if (result != null) {
        final List<dynamic> decoded = jsonDecode(result);
        return decoded.map((c) => Contact.fromJson(Map<String, dynamic>.from(c))).toList();
      }
      return [];
    } catch (e) {
      print('Get contacts error: $e');
      return [];
    }
  }

  Future<Contact?> getContactByPhone(String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod<String>('getContactByPhone', {
        'phoneNumber': phoneNumber,
      });
      if (result != null) {
        return Contact.fromJson(jsonDecode(result) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get contact by phone error: $e');
      return null;
    }
  }

  Future<bool> addContact(String name, String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod<bool>('addContact', {
        'name': name,
        'phoneNumber': phoneNumber,
      });
      return result ?? false;
    } catch (e) {
      print('Add contact error: $e');
      return false;
    }
  }
}

class Contact {
  final String id;
  final String displayName;
  final List<Phone> phones;

  Contact({
    required this.id,
    required this.displayName,
    required this.phones,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      phones: (json['phones'] as List<dynamic>)
          .map((p) => Phone.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'phones': phones.map((p) => p.toJson()).toList(),
    };
  }

  String? get primaryPhone => phones.isNotEmpty ? phones.first.number : null;
}

class Phone {
  final String number;
  final String type;

  Phone({
    required this.number,
    required this.type,
  });

  factory Phone.fromJson(Map<String, dynamic> json) {
    return Phone(
      number: json['number'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'type': type,
    };
  }
}
