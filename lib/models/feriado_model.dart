class FeriadoModel {
  final DateTime date;
  final String name;
  final String type;

  FeriadoModel({
    required this.date,
    required this.name,
    required this.type,
  });

  factory FeriadoModel.fromJson(Map<String, dynamic> json) {
    return FeriadoModel(
      date: DateTime.parse(json['date']),
      name: json['name'],
      type: json['type'],
    );
  }
}