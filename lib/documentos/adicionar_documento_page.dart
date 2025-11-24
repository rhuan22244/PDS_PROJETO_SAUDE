import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AdicionarDocumentoPage extends StatefulWidget {
  const AdicionarDocumentoPage({super.key});

  @override
  State<AdicionarDocumentoPage> createState() => _AdicionarDocumentoPageState();
}

class _AdicionarDocumentoPageState extends State<AdicionarDocumentoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _fabricanteController = TextEditingController();

  String tipoSelecionado = 'Vacinas';
  final User? user = FirebaseAuth.instance.currentUser;

  File? _arquivoSelecionado;
  String? _nomeArquivo;
  bool _isUploading = false;

  // 🔹 Escolher arquivo (PDF, imagem, etc.)
  Future<void> _selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (resultado != null && resultado.files.single.path != null) {
      setState(() {
        _arquivoSelecionado = File(resultado.files.single.path!);
        _nomeArquivo = resultado.files.single.name;
      });
    }
  }

  // 🔹 Salvar no Firestore + upload no Storage
  Future<void> salvarDocumento() async {
    if (!_formKey.currentState!.validate() || user == null) return;

    setState(() => _isUploading = true);

    try {
      String? arquivoUrl;

      // Faz upload do arquivo, se existir
      if (_arquivoSelecionado != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('documentos/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}_$_nomeArquivo');

        await ref.putFile(_arquivoSelecionado!);
        arquivoUrl = await ref.getDownloadURL();
      }

      // Salva dados no Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .collection('documentos')
          .add({
        'titulo': _tituloController.text.trim(),
        'dose': _doseController.text.trim(),
        'data': _dataController.text.trim(),
        'fabricante': _fabricanteController.text.trim(),
        'tipo': tipoSelecionado,
        'arquivoUrl': arquivoUrl, // 🔹 salva o link do arquivo
        'arquivoNome': _nomeArquivo,
        'criadoEm': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento adicionado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text('Novo Documento', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => v!.isEmpty ? 'Informe o título' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _doseController,
                    decoration: const InputDecoration(labelText: 'Dose'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _dataController,
                    decoration: const InputDecoration(labelText: 'Data'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _fabricanteController,
                    decoration: const InputDecoration(labelText: 'Fabricante'),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: tipoSelecionado,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'Vacinas', child: Text('Vacinas')),
                      DropdownMenuItem(value: 'Medicamentos', child: Text('Medicamentos')),
                      DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                    ],
                    onChanged: (val) => setState(() => tipoSelecionado = val!),
                  ),
                  const SizedBox(height: 30),

                  // 🔹 Botão para escolher arquivo
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _selecionarArquivo,
                    icon: const Icon(Icons.attach_file, color: Colors.black),
                    label: Text(
                      _nomeArquivo ?? 'Selecionar arquivo (PDF ou imagem)',
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isUploading ? null : salvarDocumento,
                    child: const Text('Salvar Documento', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),

          if (_isUploading)
            const LinearProgressIndicator(minHeight: 4),
        ],
      ),
    );
  }
}

