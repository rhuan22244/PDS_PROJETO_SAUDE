import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditarDocumentoPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> dados;

  const EditarDocumentoPage({super.key, required this.docId, required this.dados});

  @override
  State<EditarDocumentoPage> createState() => _EditarDocumentoPageState();
}

class _EditarDocumentoPageState extends State<EditarDocumentoPage> {
  late String tipo;
  late TextEditingController tituloController;
  late TextEditingController doseController;
  late TextEditingController dataController;
  late TextEditingController fabricanteController;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    tipo = widget.dados['tipo'] ?? 'Vacinas';
    tituloController = TextEditingController(text: widget.dados['titulo']);
    doseController = TextEditingController(text: widget.dados['dose']);
    dataController = TextEditingController(text: widget.dados['data']);
    fabricanteController = TextEditingController(text: widget.dados['fabricante']);
  }

  Future<void> salvarEdicao() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('documentos')
        .doc(widget.docId);

    await docRef.update({
      'tipo': tipo,
      'titulo': tituloController.text,
      'dose': doseController.text,
      'data': dataController.text,
      'fabricante': fabricanteController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Documento'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: tipo,
              items: ['Vacinas', 'Medicamentos', 'Outros']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => tipo = val ?? tipo),
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: doseController,
              decoration: const InputDecoration(
                labelText: 'Dose',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dataController,
              decoration: const InputDecoration(
                labelText: 'Data',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fabricanteController,
              decoration: const InputDecoration(
                labelText: 'Fabricante',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: loading
                  ? null
                  : () async {
                setState(() => loading = true);
                try {
                  await salvarEdicao();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Documento atualizado!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                } finally {
                  setState(() => loading = false);
                }
              },
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
