import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Certifique-se de que o caminho para seus arquivos está correto
import '../database/database_helper.dart';
import 'Consulta.dart' as consulta_model;

class EditarConsultaPage extends StatefulWidget {
  // ATUALIZAÇÃO 1: O ID agora é uma String para ser consistente com o modelo.
  final String id;
  final String especialidade;
  final String local;
  final String data;
  final String hora;
  final String status;

  const EditarConsultaPage({
    super.key,
    required this.id,
    required this.especialidade,
    required this.local,
    required this.data,
    required this.hora,
    required this.status,
    required consulta_model.Consulta consulta,
  });

  @override
  _EditarConsultaPageState createState() => _EditarConsultaPageState();
}

class _EditarConsultaPageState extends State<EditarConsultaPage> {
  List<String> _especialidades = [];
  String? _especialidadeSelecionada;
  bool _carregandoEspecialidades = true;

  late TextEditingController _localController;
  late TextEditingController _dataController;
  late TextEditingController _horaController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _carregarEspecialidades();

    _localController = TextEditingController(text: widget.local);
    _dataController = TextEditingController(text: widget.data);
    _horaController = TextEditingController(text: widget.hora);
    _status = widget.status;
  }

  // Função auxiliar para normalizar strings (1ª letra maiúscula)
  String _formatar(String valor) {
    if (valor.isEmpty) return valor;
    return valor[0].toUpperCase() + valor.substring(1).toLowerCase();
  }

  Future<void> _carregarEspecialidades() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('Especialidades').get();

      final especialidadesLidas = snapshot.docs
          .map((doc) => doc['Nome'].toString().trim())
          .map(_formatar)
          .toSet() // Usa um Set para remover duplicados automaticamente
          .toList();

      final especialidadeFormatada = _formatar(widget.especialidade);

      // Garante que o widget ainda está na árvore antes de chamar setState
      if (mounted) {
        setState(() {
          _especialidades = especialidadesLidas;
          _especialidadeSelecionada = _especialidades.contains(especialidadeFormatada)
              ? especialidadeFormatada
              : null;
          _carregandoEspecialidades = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregandoEspecialidades = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar especialidades: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _localController.dispose();
    _dataController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  // Função auxiliar para converter data e hora (String) para Timestamp
  Timestamp? _converterParaTimestamp(String dataStr, String horaStr) {
    try {
      // Divide a data "dd/mm/aaaa"
      final partesData = dataStr.split('/');
      if (partesData.length != 3) return null;

      // Divide a hora "hh:mm"
      final partesHora = horaStr.split(':');
      if (partesHora.length != 2) return null;

      final dia = int.parse(partesData[0]);
      final mes = int.parse(partesData[1]);
      final ano = int.parse(partesData[2]);
      final hora = int.parse(partesHora[0]);
      final minuto = int.parse(partesHora[1]);

      final dataHora = DateTime(ano, mes, dia, hora, minuto);
      return Timestamp.fromDate(dataHora);
    } catch (e) {
      // Retorna null se o formato da data/hora for inválido
      print('Erro ao converter data/hora: $e');
      return null;
    }
  }

  Future<void> _salvar() async {
    // Validação dos campos
    if (_especialidadeSelecionada == null ||
        _localController.text.isEmpty ||
        _dataController.text.isEmpty ||
        _horaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    final dataHoraCompleta = _converterParaTimestamp(
      _dataController.text,
      _horaController.text,
    );

    if (dataHoraCompleta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato de data ou hora inválido. Use dd/mm/aaaa e hh:mm.')),
      );
      return;
    }

    // ATUALIZAÇÃO 2: Criação correta do objeto usando o construtor da classe.
    final consultaAtualizada = consulta_model.Consulta(
      id: widget.id,
      especialidade: _especialidadeSelecionada!,
      local: _localController.text,
      data: _dataController.text,
      hora: _horaController.text,
      status: _status,
      // Adiciona o campo obrigatório que estava faltando
      dataHoraCompleta: dataHoraCompleta,
      // Se houver outros campos como medicoId, medicoNome, adicione-os aqui
      // Ex: medicoId: widget.medicoId (se você passar esse parâmetro para a página)
    );

    // O objeto 'consultaAtualizada' já é do tipo correto.
    await DatabaseHelper.instance.updateConsulta(consultaAtualizada);

    // Boa prática: Verificar se o widget ainda está montado antes de chamar Navigator.pop
    if (mounted) {
      Navigator.pop(context, true); // Retorna 'true' para indicar que houve atualização
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Consulta'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _carregandoEspecialidades
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
              value: _especialidadeSelecionada,
              decoration: const InputDecoration(labelText: 'Especialidade', border: OutlineInputBorder()),
              items: _especialidades
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _especialidadeSelecionada = val;
                });
              },
              validator: (val) => val == null || val.isEmpty
                  ? 'Selecione uma especialidade'
                  : null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _localController,
              decoration: const InputDecoration(labelText: 'Local', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dataController,
              decoration: const InputDecoration(labelText: 'Data (dd/mm/aaaa)', border: OutlineInputBorder()),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _horaController,
              decoration: const InputDecoration(labelText: 'Hora (hh:mm)', border: OutlineInputBorder()),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: ['Agendada', 'Finalizada', 'Cancelada']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _status = val;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}



















