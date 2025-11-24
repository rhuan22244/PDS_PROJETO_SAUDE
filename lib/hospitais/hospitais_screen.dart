import 'package:flutter/material.dart';

class HospitaisPage extends StatelessWidget {
  const HospitaisPage({super.key});

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
                  'Hospitais',
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
                  const SizedBox(height: 20),
                  Expanded(child: _buildListaHospitais()),
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

  Widget _buildListaHospitais() {
    return ListView(
      children: const [
        _HospitalCard(
          imagem: 'assets/hospital4.png',
          nome: 'Hospital Santa Casa - 5km',
          endereco: 'Rua Professor Annes Dias, 295\nCentro Histórico - Porto Alegre',
          telefone: '(51) 3416-9000',
        ),
        _HospitalCard(
          imagem: 'assets/hospital2.png',
          nome: 'Hospital Moinhos Vento - 2km',
          endereco: 'Rua Ramiro Barcelos, 289\nMoinhos de Vento, POA - RS',
          telefone: '(51) 3422-8900',
        ),
        _HospitalCard(
          imagem: 'assets/hospital1.png',
          nome: 'Hospital Tramandaí - 10km',
          endereco: 'Av Emancipação, 1255\nTramandaí - RS',
          telefone: '(51) 3241-8900',
        ),
      ],
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final String imagem;
  final String nome;
  final String endereco;
  final String telefone;

  const _HospitalCard({
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
