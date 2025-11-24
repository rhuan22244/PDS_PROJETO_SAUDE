import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Modelo de dados da Vacina
class Vacina {
  final String id;
  final String nome;
  final String local;
  final String faixaEtaria;
  final String data;
  final String cidade;
  final String detalhes;
  bool aplicada;
  DateTime? dataAplicacao;

  Vacina({
    required this.id,
    required this.nome,
    required this.local,
    required this.faixaEtaria,
    required this.data,
    required this.cidade,
    required this.detalhes,
    this.aplicada = false,
    this.dataAplicacao,
  });

  factory Vacina.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Vacina(
      id: snapshot.id,
      nome: data['nome'] ?? '',
      local: data['local'] ?? '',
      faixaEtaria: data['faixaEtaria'] ?? '',
      data: data['data'] ?? '',
      cidade: data['cidade'] ?? '',
      detalhes: data['detalhes'] ?? '',
    );
  }
}

class VacinasPage extends StatefulWidget {
  const VacinasPage({super.key});

  @override
  State<VacinasPage> createState() => _VacinasPageState();
}

class _VacinasPageState extends State<VacinasPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _idadeSelecionada = 'Todas';
  bool _isLoading = true;

  List<Vacina> _todasVacinas = [];
  List<Vacina> _vacinasFiltradas = [];
  final Map<String, DateTime> _vacinasAplicadas = {};

  final List<String> _idades = const [
    'Todas',
    'Bebê (0-2)',
    'Criança (3-9)',
    'Adolescente (10-17)',
    'Adulto (18-59)',
    'Idoso (60+)',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _searchController.addListener(_filtrarVacinas);
  }

  Future<void> _carregarDados() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final registrosSnapshot = await FirebaseFirestore.instance
          .collection('registrosVacinas')
          .where('userId', isEqualTo: user.uid)
          .get();

      _vacinasAplicadas.clear();
      for (var doc in registrosSnapshot.docs) {
        final vacinaNome = doc.data()['vacinaNome'] ?? '';
        final dataAplicacao = (doc.data()['dataAplicacao'] as Timestamp).toDate();
        _vacinasAplicadas[vacinaNome] = dataAplicacao;
      }

      final vacinasSnapshot = await FirebaseFirestore.instance.collection('Vacinas').get();

      final vacinasCarregadas = vacinasSnapshot.docs.map((doc) {
        final vacina = Vacina.fromFirestore(doc);
        if (_vacinasAplicadas.containsKey(vacina.nome)) {
          vacina.aplicada = true;
          vacina.dataAplicacao = _vacinasAplicadas[vacina.nome];
        }
        return vacina;
      }).toList();

      setState(() {
        _todasVacinas = vacinasCarregadas;
        _filtrarVacinas();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  Future<void> _marcarVacinaComoAplicada(Vacina vacina, BuildContext mainContext) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final dataSelecionada = await showDatePicker(
      context: mainContext,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (dataSelecionada == null) return;

    try {
      final docRef = await FirebaseFirestore.instance.collection('registrosVacinas').add({
        'userId': user.uid,
        'vacinaNome': vacina.nome,
        'dataAplicacao': Timestamp.fromDate(dataSelecionada),
      });

      setState(() {
        vacina.aplicada = true;
        vacina.dataAplicacao = dataSelecionada;
        _vacinasAplicadas[vacina.nome] = dataSelecionada;
        _filtrarVacinas();
      });

      final dataFormatada = DateFormat('dd/MM/yyyy').format(dataSelecionada);
      ScaffoldMessenger.of(mainContext).showSnackBar(
        SnackBar(content: Text('${vacina.nome} aplicada em $dataFormatada!')),
      );
    } catch (e) {
      print("Erro ao registrar vacina: $e");
    }
  }

  Future<void> _verOuEditarRegistro(Vacina vacina) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final registroQuery = await FirebaseFirestore.instance
        .collection('registrosVacinas')
        .where('userId', isEqualTo: user.uid)
        .where('vacinaNome', isEqualTo: vacina.nome)
        .limit(1)
        .get();

    if (registroQuery.docs.isEmpty) return;

    final doc = registroQuery.docs.first;
    DateTime dataAplicacao = (doc.data()['dataAplicacao'] as Timestamp).toDate();

    final novaData = await showDatePicker(
      context: context,
      initialDate: dataAplicacao,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (novaData != null) {
      await FirebaseFirestore.instance
          .collection('registrosVacinas')
          .doc(doc.id)
          .update({'dataAplicacao': Timestamp.fromDate(novaData)});

      setState(() {
        vacina.dataAplicacao = novaData;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vacina.nome} atualizada para ${DateFormat('dd/MM/yyyy').format(novaData)}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vacina.nome} aplicada em ${DateFormat('dd/MM/yyyy').format(dataAplicacao)}')),
      );
    }
  }

  void _filtrarVacinas() {
    final termoBusca = _searchController.text.toLowerCase();
    setState(() {
      _vacinasFiltradas = _todasVacinas.where((vacina) {
        final atendeBusca = termoBusca.isEmpty || vacina.nome.toLowerCase().contains(termoBusca);
        final atendeIdade = _idadeSelecionada == 'Todas' || vacina.faixaEtaria == _idadeSelecionada;
        return atendeBusca && atendeIdade;
      }).toList();
    });
  }

  void _mostrarDetalhesVacina(Vacina vacina) {
    final mainContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => VacinaDetalhesSheet(
        vacina: vacina,
        onMarcarAplicada: () => _marcarVacinaComoAplicada(vacina, mainContext),
        onVerOuEditarRegistro: () => _verOuEditarRegistro(vacina),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrarVacinas);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacinas', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        color: const Color(0xFFF2EAEA),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome da vacina',
                prefixIcon: const Icon(Icons.vaccines),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _idadeSelecionada,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _idadeSelecionada = value);
                  _filtrarVacinas();
                }
              },
              decoration: InputDecoration(
                labelText: 'Filtrar por faixa etária',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _idades.map((faixa) => DropdownMenuItem(value: faixa, child: Text(faixa))).toList(),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Vacinas disponíveis:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _vacinasFiltradas.isEmpty
                  ? const Center(child: Text('Nenhuma vacina encontrada.', style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                itemCount: _vacinasFiltradas.length,
                itemBuilder: (context, index) {
                  final vacina = _vacinasFiltradas[index];
                  return VacinaCard(
                    vacina: vacina,
                    onTap: () => _mostrarDetalhesVacina(vacina),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== COMPONENTES ==================

class VacinaCard extends StatelessWidget {
  final Vacina vacina;
  final VoidCallback onTap;

  const VacinaCard({super.key, required this.vacina, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: vacina.aplicada ? Colors.green : Colors.blueAccent,
            child: Icon(
              vacina.aplicada ? Icons.check : Icons.vaccines,
              color: Colors.white,
            ),
          ),
          title: Text(vacina.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Local: ${vacina.local}"),
              Text("Indicação: ${vacina.data}"),
              if (vacina.aplicada && vacina.dataAplicacao != null)
                Text("Aplicada em: ${DateFormat('dd/MM/yyyy').format(vacina.dataAplicacao!)}",
                    style: const TextStyle(color: Colors.green)),
            ],
          ),
          trailing: vacina.aplicada
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

class VacinaDetalhesSheet extends StatelessWidget {
  final Vacina vacina;
  final VoidCallback onMarcarAplicada;
  final Future<void> Function()? onVerOuEditarRegistro;

  const VacinaDetalhesSheet({
    super.key,
    required this.vacina,
    required this.onMarcarAplicada,
    this.onVerOuEditarRegistro,
  });

  @override
  Widget build(BuildContext context) {
    final bool vacinaJaRegistrada = vacina.aplicada;
    final String textoBotao = vacinaJaRegistrada ? 'Ver / Editar Registro' : 'Marcar como aplicada';
    final Color corBotao = vacinaJaRegistrada ? Colors.green : Colors.redAccent;
    final IconData iconeBotao = vacinaJaRegistrada ? Icons.event_note : Icons.check;
    final VoidCallback? acaoBotao = vacinaJaRegistrada ? () => onVerOuEditarRegistro?.call() : onMarcarAplicada;

    return Padding(
      padding: const EdgeInsets.all(24).copyWith(bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vacina.nome,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(height: 12),
          Text('Local: ${vacina.local}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text('Indicação: ${vacina.data}', style: const TextStyle(fontSize: 16)),
          if (vacina.aplicada && vacina.dataAplicacao != null)
            Text('Aplicada em: ${DateFormat('dd/MM/yyyy').format(vacina.dataAplicacao!)}',
                style: const TextStyle(fontSize: 16, color: Colors.green)),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Text(vacina.detalhes, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(iconeBotao, color: Colors.white),
              label: Text(textoBotao, style: const TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: corBotao,
                disabledBackgroundColor: Colors.green.withOpacity(0.7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: acaoBotao,
            ),
          ),
        ],
      ),
    );
  }
}
