import 'package:flutter/material.dart';

// Converte uma string no formato "HH:mm:ss" para um objeto TimeOfDay.
TimeOfDay _timeOfDayFromString(String timeString) {
  final parts = timeString.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return TimeOfDay(hour: hour, minute: minute);
}

// Formata um objeto TimeOfDay para uma string no formato "HH:mm:ss".
String _stringFromTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

class Periodo {
  final String? id; // ID único do período (pode ser nulo ao criar)
  final String idAgenda; // ID da agenda/profissional a que este período pertence
  final int diaDaSemana; // Dia da semana (ex: 1 para Segunda, 7 para Domingo)
  final TimeOfDay inicio; // Horário de início do período
  final TimeOfDay fim; // Horário de fim do período

  Periodo({
    this.id,
    required this.idAgenda,
    required this.diaDaSemana,
    required this.inicio,
    required this.fim,
  });

  // Cria um Periodo a partir de um JSON vindo da API.
  factory Periodo.fromJson(Map<String, dynamic> json) {
    return Periodo(
      id: json['id']?.toString(), // Converte para String por segurança
      idAgenda: json['id_agenda'].toString(),
      diaDaSemana: json['dia_da_semana'],
      // Usa a função auxiliar para converter a string de tempo em TimeOfDay
      inicio: _timeOfDayFromString(json['inicio']),
      fim: _timeOfDayFromString(json['fim']),
    );
  }

  // Converte um Periodo para um JSON para enviar à API.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_agenda': idAgenda,
      'dia_da_semana': diaDaSemana,
      // Usa a função auxiliar para formatar o TimeOfDay de volta para string
      'inicio': _stringFromTimeOfDay(inicio),
      'fim': _stringFromTimeOfDay(fim),
    };
  }
}