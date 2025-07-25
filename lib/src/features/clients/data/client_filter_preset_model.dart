import 'package:fluent_ui/fluent_ui.dart';

class ClientFilterPreset {
  final int id;
  final String name;
  final String? searchTerm;
  final List<String> tags;
  final String? company;
  final DateTimeRange? dateRange;
  final String sortBy;
  final bool sortAscending;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientFilterPreset({
    required this.id,
    required this.name,
    this.searchTerm,
    this.tags = const [],
    this.company,
    this.dateRange,
    this.sortBy = 'name',
    this.sortAscending = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientFilterPreset.fromJson(Map<String, dynamic> json) {
    return ClientFilterPreset(
      id: json['id'] as int,
      name: json['name'] as String,
      searchTerm: json['searchTerm'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      company: json['company'] as String?,
      dateRange: json['dateRange'] != null
          ? DateTimeRange(
              start: DateTime.parse(json['dateRange']['start']),
              end: DateTime.parse(json['dateRange']['end']),
            )
          : null,
      sortBy: json['sortBy'] as String? ?? 'name',
      sortAscending: json['sortAscending'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'searchTerm': searchTerm,
      'tags': tags,
      'company': company,
      'dateRange': dateRange != null
          ? {
              'start': dateRange!.start.toIso8601String(),
              'end': dateRange!.end.toIso8601String(),
            }
          : null,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ClientFilterPreset copyWith({
    int? id,
    String? name,
    String? searchTerm,
    List<String>? tags,
    String? company,
    DateTimeRange? dateRange,
    String? sortBy,
    bool? sortAscending,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientFilterPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      searchTerm: searchTerm ?? this.searchTerm,
      tags: tags ?? this.tags,
      company: company ?? this.company,
      dateRange: dateRange ?? this.dateRange,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
