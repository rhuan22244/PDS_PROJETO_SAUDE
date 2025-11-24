import 'package:flutter/material.dart';

class PerfilMedicoPage extends StatefulWidget {
  final String nome;
  final String crm;
  final String especialidade;
  final String email;
  final String telefone;

  const PerfilMedicoPage({
    super.key,
    required this.nome,
    required this.crm,
    required this.especialidade,
    required this.email,
    required this.telefone,
  });

  @override
  State<PerfilMedicoPage> createState() => _PerfilMedicoPageState();
}

class _PerfilMedicoPageState extends State<PerfilMedicoPage> {
  late TextEditingController _nomeController;
  late TextEditingController _crmController;
  late TextEditingController _especialidadeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nome);
    _crmController = TextEditingController(text: widget.crm);
    _especialidadeController = TextEditingController(text: widget.especialidade);
    _emailController = TextEditingController(text: widget.email);
    _telefoneController = TextEditingController(text: widget.telefone);
  }

  void _salvarPerfil() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Dados salvos com sucesso!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil do Médico"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: "Nome"),
            ),
            TextField(
              controller: _crmController,
              decoration: InputDecoration(labelText: "CRM"),
            ),
            TextField(
              controller: _especialidadeController,
              decoration: InputDecoration(labelText: "Especialidade"),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _telefoneController,
              decoration: InputDecoration(labelText: "Telefone"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarPerfil,
              child: Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}
