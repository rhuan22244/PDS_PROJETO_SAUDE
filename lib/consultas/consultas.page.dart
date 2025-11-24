import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Consulta.dart' as consulta_model;
import 'MarcarConsultaPage.dart';
import 'editarConsultasPage.dart';

class ConsultasPage extends StatefulWidget {
  const ConsultasPage({super.key});

  @override
  _ConsultasPageState createState() => _ConsultasPageState();
}

class _ConsultasPageState extends State<ConsultasPage> {
  final TextEditingController _searchController = TextEditingController();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  Stream<QuerySnapshot> _getConsultasStream(String status) {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('Consultas')
        .where('pacienteId', isEqualTo: currentUserId)
        .where('status', isEqualTo: status)
        .orderBy('dataHoraCompleta')
        .snapshots();
  }

  Future<bool?> _confirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
      ),
    );
  }

  Future<void> _handleUpdateStatus(String docId, String newStatus) async {
    final acao = newStatus == 'Cancelada' ? 'cancelar' : 'finalizar';
    final confirmado = await _confirmDialog(
      'Confirmar Ação',
      'Você tem certeza que deseja $acao esta consulta?',
    );
    if (confirmado ?? false) {
      try {
        await FirebaseFirestore.instance.collection('Consultas').doc(docId).update({'status': newStatus});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar status: $e')));
        }
      }
    }
  }

  Future<void> _handleDeleteConsulta(String docId) async {
    final confirmado = await _confirmDialog(
      'Excluir Consulta',
      'Esta ação não pode ser desfeita. Deseja continuar?',
    );
    if (confirmado ?? false) {
      try {
        await FirebaseFirestore.instance.collection('Consultas').doc(docId).delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir consulta: $e')));
        }
      }
    }
  }

  void _handleEditarConsulta(consulta_model.Consulta consulta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarConsultaPage(
          // Passando cada dado requerido a partir do objeto 'consulta'
          id: consulta.id,
          especialidade: consulta.especialidade,
          local: consulta.local,
          data: consulta.data,
          hora: consulta.hora,
          status: consulta.status,
          // Se a página de edição também precisar do objeto completo,
          // você pode mantê-lo aqui, dependendo de como o construtor dela foi definido.
          consulta: consulta,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Center(child: Text('Por favor, faça login para ver suas consultas.'));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          title: const Text('Consultas', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'AGENDADAS'),
              Tab(text: 'FINALIZADAS'),
              Tab(text: 'CANCELADAS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ConsultasTab(
              status: 'Agendada',
              stream: _getConsultasStream('Agendada'),
              searchController: _searchController,
              onUpdateStatus: _handleUpdateStatus,
              onDelete: _handleDeleteConsulta,
              onEdit: _handleEditarConsulta, // Passando a função de editar
              mostrarBusca: true,
            ),
            _ConsultasTab(
              status: 'Finalizada',
              stream: _getConsultasStream('Finalizada'),
              onDelete: _handleDeleteConsulta,
              mostrarBusca: false,
            ),
            _ConsultasTab(
              status: 'Cancelada',
              stream: _getConsultasStream('Cancelada'),
              onDelete: _handleDeleteConsulta,
              mostrarBusca: false,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarcarConsultaPage(
                  onConsultaMarcada: (consulta) {},
                ),
              ),
            );
          },
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// =========================================================================

class _ConsultasTab extends StatelessWidget {
  final String status;
  final Stream<QuerySnapshot> stream;
  final TextEditingController? searchController;
  final Future<void> Function(String, String)? onUpdateStatus;
  final Future<void> Function(String)? onDelete;
  final void Function(consulta_model.Consulta)? onEdit; // 🔥 CORREÇÃO: Recebe a função de editar
  final bool mostrarBusca;

  const _ConsultasTab({
    super.key,
    required this.status,
    required this.stream,
    this.searchController,
    this.onUpdateStatus,
    this.onDelete,
    this.onEdit,
    required this.mostrarBusca,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (mostrarBusca)
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por especialidade ou local...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Ocorreu um erro.'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('Nenhuma consulta encontrada.'));

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final query = searchController?.text.toLowerCase() ?? '';
                  if (query.isEmpty) return true;
                  return (data['especialidade']?.toLowerCase().contains(query) ?? false) ||
                      (data['local']?.toLowerCase().contains(query) ?? false);
                }).toList();

                if (filteredDocs.isEmpty) return const Center(child: Text('Nenhum resultado para a busca.'));

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    // 🔥 CORREÇÃO: Usando o modelo para criar um objeto Consulta
                    final consulta = consulta_model.Consulta.fromFirestore(doc);

                    return _ConsultaCard(
                      consulta: consulta, // Passa o objeto completo
                      onCancelar: status == 'Agendada' ? () => onUpdateStatus?.call(doc.id, 'Cancelada') : null,
                      onFinalizar: status == 'Agendada' ? () => onUpdateStatus?.call(doc.id, 'Finalizada') : null,
                      onExcluir: (status != 'Agendada') ? () => onDelete?.call(doc.id) : null,
                      onEditar: (status == 'Agendada') ? () => onEdit?.call(consulta) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================

class _ConsultaCard extends StatelessWidget {
  final consulta_model.Consulta consulta; // Recebe o objeto completo
  final VoidCallback? onCancelar;
  final VoidCallback? onFinalizar;
  final VoidCallback? onExcluir;
  final VoidCallback? onEditar; // Recebe a função de editar

  const _ConsultaCard({
    super.key,
    required this.consulta,
    this.onCancelar,
    this.onFinalizar,
    this.onExcluir,
    this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    consulta.especialidade,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // 🔥 CORREÇÃO: Substituído o ícone estático por um botão funcional
                if (consulta.status == 'Agendada')
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'editar') {
                        onEditar?.call();
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(consulta.local),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 4),
                Text(consulta.data),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 4),
                Text(consulta.hora),
                const Spacer(),
                if (onCancelar != null)
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: onCancelar,
                    color: Colors.orange,
                    tooltip: 'Cancelar Consulta',
                  ),
                if (onFinalizar != null)
                  IconButton(
                    icon: const Icon(Icons.check_circle),
                    onPressed: onFinalizar,
                    color: Colors.green,
                    tooltip: 'Finalizar Consulta',
                  ),
                if (onExcluir != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onExcluir,
                    color: Colors.red,
                    tooltip: 'Excluir Consulta',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}