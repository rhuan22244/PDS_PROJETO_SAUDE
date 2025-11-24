import 'package:flutter/material.dart';

class FarmaciasPage extends StatefulWidget {
  const FarmaciasPage({super.key});

  @override
  State<FarmaciasPage> createState() => _FarmaciasPageState();
}

class _FarmaciasPageState extends State<FarmaciasPage> {
  String filtroSelecionado = 'Rede Panvel';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'Farmácias',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF3EDED),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCampoLocalizacao(),
                  const SizedBox(height: 12),
                  _buildFiltros(),
                  const SizedBox(height: 20),
                  Image.asset('assets/panvelLogo.png', height: 50),
                  const SizedBox(height: 16),
                  Expanded(child: _buildListaFarmacias()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoLocalizacao() {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.location_on_outlined),
        hintText: 'Informe sua localização',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFiltros() {
    final filtros = ['Municipais', 'Rede Panvel', 'Rede São João'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: filtros.map((filtro) {
        final ativo = filtroSelecionado == filtro;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ativo ? Colors.redAccent : Colors.white,
                foregroundColor: ativo ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: ativo ? 2 : 0,
              ),
              onPressed: () {
                setState(() {
                  filtroSelecionado = filtro;
                });
              },
              child: Text(filtro),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListaFarmacias() {
    return ListView(
      children: const [
        _FarmaciaCard(
          imagem: 'assets/farmacia2.png',
          nome: 'Panvel Santa Luzia - 50km',
          endereco: 'Rua Dom Luiz Guanella, 2864\nGirassol - Lajeado RS',
          telefone: '(51) 3412-8900',
        ),
      ],
    );
  }
}

class _FarmaciaCard extends StatelessWidget {
  final String imagem;
  final String nome;
  final String endereco;
  final String telefone;

  const _FarmaciaCard({
    required this.imagem,
    required this.nome,
    required this.endereco,
    required this.telefone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.redAccent.shade100,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.asset(imagem, height: 100, width: 100, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(endereco, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14),
                      const SizedBox(width: 4),
                      Text(telefone, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
