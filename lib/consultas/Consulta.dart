import 'package:cloud_firestore/cloud_firestore.dart';

class Consulta {
  final String id;
  final String especialidade;
  final String local;
  final String data;
  final String hora;
  final String status;
  final String? pacienteId;
  final String? medicoId;
  final String? medicoNome;
  final Timestamp? dataHoraCompleta; // Nulo para dados do SQLite

  Consulta({
    required this.id,
    required this.especialidade,
    required this.local,
    required this.data,
    required this.hora,
    required this.status,
    this.pacienteId,
    this.medicoId,
    this.medicoNome,
    this.dataHoraCompleta,
  });

  /// Construtor para criar uma Consulta a partir de um documento do Firestore.
  factory Consulta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Consulta(
      id: doc.id,
      especialidade: data['especialidade'] ?? '',
      local: data['local'] ?? '',
      data: data['data'] ?? '',
      hora: data['hora'] ?? '',
      status: data['status'] ?? '',
      pacienteId: data['pacienteId'],
      medicoId: data['medicoId'],
      medicoNome: data['medicoNome'],
      dataHoraCompleta: data['dataHoraCompleta'],
    );
  }

  /// 🔥 NOVO: Construtor para criar uma Consulta a partir de um mapa do SQLite.
  factory Consulta.fromMap(Map<String, dynamic> map) {
    return Consulta(
      // O SQLite retorna o 'id' como um int, então convertemos para String.
      id: map['id'].toString(),
      especialidade: map['especialidade'] ?? '',
      local: map['local'] ?? '',
      data: map['data'] ?? '',
      hora: map['hora'] ?? '',
      status: map['status'] ?? '',
      // Campos que não existem no SQLite serão nulos.
      pacienteId: map['pacienteId'],
      medicoId: map['medicoId'],
      medicoNome: map['medicoNome'],
      dataHoraCompleta: null, // O SQLite não armazena o Timestamp do Firestore.
    );
  }

  /// Converte o objeto para um mapa, usado tanto pelo Firestore quanto pelo SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'especialidade': especialidade,
      'local': local,
      'data': data,
      'hora': hora,
      'status': status,
      'pacienteId': pacienteId,
      'medicoId': medicoId,
      'medicoNome': medicoNome,
      'dataHoraCompleta': dataHoraCompleta,
    };
  }
}





