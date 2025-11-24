import 'package:flutter/material.dart';

class DocumentosMedicoPage extends StatefulWidget {
  const DocumentosMedicoPage({super.key});

  @override
  State<DocumentosMedicoPage> createState() => _DocumentosMedicoPageState();
}

class _DocumentosMedicoPageState extends State<DocumentosMedicoPage> {
  final List<String> _documentos = ["Exame de sangue.pdf", "Receita - João.png"];

  void _adicionarDocumento() {
    setState(() {
      _documentos.add("Novo documento.pdf");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meus Documentos"),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        itemCount: _documentos.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.description, color: Colors.red),
            title: Text(_documentos[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarDocumento,
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }
}
