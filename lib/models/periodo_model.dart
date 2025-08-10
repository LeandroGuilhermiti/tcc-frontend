class Periodo {
  final String diaDaSemana;
  final String inicio;
  final String fim;

  Periodo({
    required this.diaDaSemana,
    required this.inicio,
    required this.fim,
  });

  Map<String, dynamic> toJson() {
    return {
      "dia_da_semana": diaDaSemana,
      "inicio": inicio,
      "fim": fim,
    };
  }
}