import 'package:flutter/material.dart';

import 'exames.dart';
import 'exames_detalhes_page.dart';

class ExamesPage extends StatefulWidget {
  const ExamesPage({super.key});

  @override
  State<ExamesPage> createState() => _ExamesPageState();
}

class _ExamesPageState extends State<ExamesPage> {
  final List<Exame> todosExames = [
    Exame(
      nome: 'Hemograma completo',
      local: 'Laboratório Vida',
      data: '15/05/2025',
      disponivel: true,
    ),
    Exame(
      nome: 'Raio-X de Tórax',
      local: 'Clínica Diagnóstica Sul',
      data: '18/05/2025',
      disponivel: false,
    ),
    Exame(
      nome: 'Ultrassom abdominal',
      local: 'Hospital Municipal',
      data: '20/05/2025',
      disponivel: true,
    ),
  ];

  List<Exame> examesFiltrados = [];
  String termoBusca = '';

  @override
  void initState() {
    super.initState();
    examesFiltrados = todosExames;
  }

  void filtrarExames(String busca) {
    setState(() {
      termoBusca = busca;
      examesFiltrados = todosExames
          .where((exame) =>
      exame.nome.toLowerCase().contains(busca.toLowerCase()) ||
          exame.local.toLowerCase().contains(busca.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Exames', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF2EAEA),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: filtrarExames,
              decoration: InputDecoration(
                hintText: 'Pesquise por exame ou local',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Exames disponíveis na sua cidade:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: examesFiltrados.isEmpty
                  ? const Center(
                child: Text(
                  'Nenhum exame encontrado.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
                  : ListView.builder(
                itemCount: examesFiltrados.length,
                itemBuilder: (context, index) {
                  final exame = examesFiltrados[index];
                  return ExameCard(exame: exame);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExameCard extends StatelessWidget {
  final Exame exame;

  const ExameCard({super.key, required this.exame});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.redAccent,
          child: Icon(Icons.biotech, color: Colors.white),
        ),
        title: Text(
          exame.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Local: ${exame.local}"),
            Text("Data: ${exame.data}"),
            Text(
              "Disponível: ${exame.disponivel ? 'SIM' : 'NÃO'}",
              style: TextStyle(
                color: exame.disponivel ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExameDetalhesPage(exame: exame),
            ),
          );
        },
      ),
    );
  }
}

