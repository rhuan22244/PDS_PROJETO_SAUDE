import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'editar_documentos.dart';
import 'adicionar_documento_page.dart';

class DocumentosPage extends StatefulWidget {
  const DocumentosPage({super.key});

  @override
  State<DocumentosPage> createState() => _DocumentosPageState();
}

class _DocumentosPageState extends State<DocumentosPage> {
  String categoriaSelecionada = 'Vacinas';
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  // Stream de documentos filtrados por categoria
  Stream<QuerySnapshot<Map<String, dynamic>>> documentosStream() {
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('documentos')
        .where('tipo', isEqualTo: categoriaSelecionada)
        .snapshots();
  }

  Future<void> excluirDocumento(String docId) async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('documentos')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdicionarDocumentoPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(color: Colors.redAccent),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'DOCUMENTOS',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF3EDED),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Veja os seus documentos relacionados à área da saúde abaixo:',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCategoriaBotao(Icons.vaccines, 'Vacinas'),
                      _buildCategoriaBotao(Icons.medication, 'Medicamentos'),
                      _buildCategoriaBotao(Icons.description, 'Outros'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: documentosStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Erro: ${snapshot.error}'));
                        }
                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              'Nenhum documento na categoria "$categoriaSelecionada".',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            return DocumentoCard(
                              docId: doc.id,
                              titulo: data['titulo'] ?? 'Sem título',
                              dose: data['dose'] ?? '',
                              data: data['data'] ?? '',
                              fabricante: data['fabricante'] ?? '',
                              tipo: data['tipo'] ?? categoriaSelecionada,
                              onDeleted: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirmar exclusão'),
                                    content: const Text('Deseja excluir este documento?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await excluirDocumento(doc.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Documento excluído')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao excluir: $e')),
                                    );
                                  }
                                }
                              },
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarDocumentoPage(
                                      docId: doc.id,
                                      dados: data,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaBotao(IconData icon, String label) {
    final bool selecionado = categoriaSelecionada == label;
    return GestureDetector(
      onTap: () => setState(() => categoriaSelecionada = label),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: selecionado ? Colors.redAccent : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: selecionado ? Colors.white : Colors.black, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: selecionado ? Colors.redAccent : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentoCard extends StatelessWidget {
  final String docId;
  final String titulo;
  final String dose;
  final String data;
  final String fabricante;
  final String tipo;
  final VoidCallback onDeleted;
  final VoidCallback onEdit;

  const DocumentoCard({
    super.key,
    required this.docId,
    required this.titulo,
    required this.dose,
    required this.data,
    required this.fabricante,
    required this.tipo,
    required this.onDeleted,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dose.isNotEmpty) Text('Dose: $dose'),
            if (data.isNotEmpty) Text('Data: $data'),
            if (fabricante.isNotEmpty) Text('Fabricante: $fabricante'),
            Text('Tipo: $tipo'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDeleted,
            ),
          ],
        ),
      ),
    );
  }
}



