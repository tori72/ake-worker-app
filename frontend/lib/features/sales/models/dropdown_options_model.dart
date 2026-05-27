// lib/features/sales/models/dropdown_options_model.dart
// Data models for the dropdown option lists returned by GET /api/items/all

class LookupOption {
  final int id;
  final String label;

  const LookupOption({required this.id, required this.label});

  factory LookupOption.fromJson(Map<String, dynamic> json,
      {String labelKey = 'name'}) {
    return LookupOption(
      id: json['id'] as int,
      label: json[labelKey] as String,
    );
  }

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DropdownOptionsModel {
  final List<LookupOption> items;
  final List<LookupOption> threads;
  final List<LookupOption> lengths;
  final List<LookupOption> heads;
  final List<LookupOption> colours;

  const DropdownOptionsModel({
    required this.items,
    required this.threads,
    required this.lengths,
    required this.heads,
    required this.colours,
  });

  factory DropdownOptionsModel.fromJson(Map<String, dynamic> json) {
    List<LookupOption> parse(dynamic list, {String labelKey = 'name'}) {
      return (list as List<dynamic>)
          .map((e) =>
              LookupOption.fromJson(e as Map<String, dynamic>, labelKey: labelKey))
          .toList();
    }

    return DropdownOptionsModel(
      items:   parse(json['items']),
      threads: parse(json['threads']),
      lengths: parse(json['lengths'], labelKey: 'value'),
      heads:   parse(json['heads']),
      colours: parse(json['colours']),
    );
  }

  static DropdownOptionsModel empty() => const DropdownOptionsModel(
        items:   [],
        threads: [],
        lengths: [],
        heads:   [],
        colours: [],
      );
}
