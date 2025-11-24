class Medico {
  final String id;
  final String nome;
  final String especialidade;

  Medico({required this.id, required this.nome, required this.especialidade});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'especialidade': especialidade,
    };
  }

  factory Medico.fromMap(Map<String, dynamic> map) {
    return Medico(
      id: map['id'],
      nome: map['nome'],
      especialidade: map['especialidade'],
    );
  }
}
