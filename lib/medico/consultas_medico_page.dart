import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer'; // Usado para logs de erro mais detalhados

class ConsultasMedicoPage extends StatelessWidget {
  final String medicoId;

  const ConsultasMedicoPage({super.key, required this.medicoId});

  Future<void> _excluirConsulta(String consultaId) async {
    try {
      await FirebaseFirestore.instance.collection('Consultas').doc(consultaId).delete();
    } catch (e, s) {
      log('Erro ao excluir consulta', error: e, stackTrace: s);
    }
  }

  Future<void> _atualizarStatusConsulta(String consultaId, String novoStatus) async {
    try {
      await FirebaseFirestore.instance.collection('Consultas').doc(consultaId).update({'status': novoStatus});
    } catch (e, s) {
      log('Erro ao atualizar status', error: e, stackTrace: s);
    }
  }

  Future<bool?> _mostrarDialogoDeConfirmacao(BuildContext context, String acao) {
    String verbo = acao;
    if (acao.endsWith('ar')) {
      verbo = acao.substring(0, acao.length - 2) + 'ar';
    }

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmar Ação'),
          content: Text('Você tem certeza que deseja $verbo esta consulta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoje = Timestamp.fromDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Consultas"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Consultas')
            .where('medicoId', isEqualTo: medicoId)
            .where('dataHoraCompleta', isGreaterThanOrEqualTo: hoje)
            .orderBy('dataHoraCompleta')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            log('Erro ao carregar consultas do médico', error: snapshot.error, stackTrace: snapshot.stackTrace);
            return const Center(child: Text("Ocorreu um erro ao carregar as consultas."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final consultas = snapshot.data?.docs ?? [];

          if (consultas.isEmpty) {
            return const Center(child: Text("Nenhuma consulta futura encontrada."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: consultas.length,
            itemBuilder: (context, index) {
              final doc = consultas[index];
              final consulta = doc.data() as Map<String, dynamic>;

              final status = consulta['status'] ?? 'Desconhecido';
              final especialidade = consulta['especialidade'] ?? 'Especialidade';
              final data = consulta['data'] ?? 'Data';
              final hora = consulta['hora'] ?? 'Hora';
              final pacienteNome = consulta['pacienteNome'] ?? 'Paciente não identificado';

              Color statusColor;
              switch (status) {
                case 'Agendada': statusColor = Colors.green; break;
                case 'Finalizada': statusColor = Colors.blue; break;
                case 'Cancelada': statusColor = Colors.red; break;
                default: statusColor = Colors.grey;
              }

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  final confirmado = await _mostrarDialogoDeConfirmacao(context, 'excluir');
                  if (confirmado ?? false) {
                    await _excluirConsulta(doc.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Consulta com $pacienteNome excluída')),
                      );
                    }
                  }
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(especialidade, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Paciente: $pacienteNome\nData: $data às $hora',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        final confirmado = await _mostrarDialogoDeConfirmacao(context, value.toLowerCase());
                        if (confirmado ?? false) {
                          await _atualizarStatusConsulta(doc.id, value); // 'Finalizada' ou 'Cancelada'
                        }
                      },
                      itemBuilder: (context) => [
                        if (status == 'Agendada')
                          const PopupMenuItem(value: 'Finalizada', child: Text('Finalizar')),
                        if (status == 'Agendada')
                          const PopupMenuItem(value: 'Cancelada', child: Text('Cancelar')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}







