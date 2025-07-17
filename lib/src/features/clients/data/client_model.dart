import 'package:client_connect/src/core/models/database.dart';
import 'package:drift/drift.dart';

class ClientModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? company;
  final String? jobTitle;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.company,
    this.jobTitle,
    this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get full name
  String get fullName => '$firstName $lastName'.trim();

  // Create from database Client
  factory ClientModel.fromDatabase(Client client) {
    return ClientModel(
      id: client.id,
      firstName: client.firstName,
      lastName: client.lastName,
      email: client.email,
      phone: client.phone,
      company: client.company,
      jobTitle: client.jobTitle,
      address: client.address,
      notes: client.notes,
      createdAt: client.createdAt,
      updatedAt: client.updatedAt,
    );
  }

  // Convert to database Client for insertion
  ClientsCompanion toCompanion() {
    return ClientsCompanion.insert(
      firstName: firstName,
      lastName: lastName,
      email: Value(email),
      phone: Value(phone),
      company: Value(company),
      jobTitle: Value(jobTitle),
      address: Value(address),
      notes: Value(notes),
    );
  }

  // Convert to database Client for update
  ClientsCompanion toUpdateCompanion() {
    return ClientsCompanion(
      id: Value(id),
      firstName: Value(firstName),
      lastName: Value(lastName),
      email: Value(email),
      phone: Value(phone),
      company: Value(company),
      jobTitle: Value(jobTitle),
      address: Value(address),
      notes: Value(notes),
      updatedAt: Value(DateTime.now()),
    );
  }

  // Create a copy with updated fields
  ClientModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ClientModel(id: $id, name: $fullName, email: $email, company: $company)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientModel &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.phone == phone &&
        other.company == company &&
        other.jobTitle == jobTitle &&
        other.address == address &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      firstName,
      lastName,
      email,
      phone,
      company,
      jobTitle,
      address,
      notes,
    );
  }
}