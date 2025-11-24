import 'package:flutter/material.dart';

class ConsultaCardWidget extends StatelessWidget {
  final String paciente;
  final String data;
  final String hora;
  final String status;

  final VoidCallback? onFinalizar;
  final VoidCallback? onCancelar;

  const ConsultaCardWidget({
    Key? key,
    required this.paciente,
    required this.data,
    required this.hora,
    required this.status,
    this.onFinalizar,
    this.onCancelar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.blue),
        title: Text("Paciente: $paciente"),
        subtitle: Text("Data: $data\nHora: $hora\nStatus: $status"),
        trailing: status == 'Agendada'
            ? PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'Finalizar' && onFinalizar != null) {
              onFinalizar!();
            } else if (value == 'Cancelar' && onCancelar != null) {
              onCancelar!();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'Finalizar',
              child: Text("Finalizar"),
            ),
            const PopupMenuItem(
              value: 'Cancelar',
              child: Text("Cancelar"),
            ),
          ],
        )
            : Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: status == 'Finalizada'
                ? Colors.blue
                : status == 'Cancelada'
                ? Colors.red
                : Colors.black,
          ),
        ),
      ),
    );
  }
}

