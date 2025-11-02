import 'package:flutter/material.dart';

// --- Função auxiliar para converter String para TimeOfDay ---
TimeOfDay _timeOfDayFromString(String? timeString) { 
  if (timeString == null || timeString.isEmpty) {
    debugPrint("Erro: timeString nula ou vazia. Usando 00:00.");
    return const TimeOfDay(hour: 0, minute: 0);
  }
  try {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  } catch (e) {
    debugPrint("Erro ao converter string para TimeOfDay: '$timeString'. Usando 00:00.");
    return const TimeOfDay(hour: 0, minute: 0); // Retorno seguro
  }
}
// --- FIM DA FUNÇÃO ---

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

  /// Construtor de fábrica: Cria um Periodo a partir de um JSON vindo da API.
  /// AGORA ESPERA chaves em camelCase (ex: 'idAgenda', 'diaDaSemana').
  factory Periodo.fromJson(Map<String, dynamic> json) {
    return Periodo(
      id: json['id']?.toString(), 
      
      // --- ALTERAÇÃO AQUI ---
      // Lê a chave 'idAgenda' diretamente.
      idAgenda: json['idAgenda']?.toString() ?? '', 
      
      // --- ALTERAÇÃO AQUI ---
      // Lê a chave 'diaDaSemana' diretamente.
      diaDaSemana: json['diaDaSemana'] ?? 0,
      // --- FIM DA ALTERAÇÃO ---
      
      inicio: _timeOfDayFromString(json['inicio']),
      fim: _timeOfDayFromString(json['fim']),
    );
  }

  /// Converte um Periodo para um JSON para enviar à API.
  /// AGORA GERA chaves em camelCase (ex: 'idAgenda', 'diaDaSemana').
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      
      // --- ALTERAÇÃO AQUI ---
      'idAgenda': idAgenda,
      
      // --- ALTERAÇÃO AQUI ---
      'diaDaSemana': diaDaSemana,
      // --- FIM DA ALTERAÇÃO ---

      'inicio': _stringFromTimeOfDay(inicio),
      'fim': _stringFromTimeOfDay(fim),
    };
  }
}

