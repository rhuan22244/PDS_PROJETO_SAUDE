import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../cadastro_e_login/login_page.dart';
import 'consultas_medico_page.dart';
import 'documentos_medico_page.dart';
import 'perfil_medico_page.dart';

class MedicoHomePage extends StatefulWidget {
  const MedicoHomePage({super.key, required String nomeMedico, required String medicoId});

  @override
  State<MedicoHomePage> createState() => _MedicoHomePageState();
}

class _MedicoHomePageState extends State<MedicoHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _nomeMedico = 'Carregando...';
  String _medicoId = '';
  Map<String, dynamic> _medicoData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosMedico();
  }

  Future<void> _carregarDadosMedico() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _medicoData = doc.data() ?? {};
          _nomeMedico = _medicoData['nome'] ?? 'Dr(a). Sem Nome';
          _medicoId = user.uid;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      _handleLogout();
    }
  }

  Future<void> _handleLogout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Médico'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo, $_nomeMedico!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text("Minhas Consultas"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConsultasMedicoPage(medicoId: _medicoId),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.description),
              label: const Text("Meus Documentos"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentosMedicoPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text("Perfil do Médico"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PerfilMedicoPage(
                      // 🔹 Passando os dados reais do Firestore
                      nome: _medicoData['nome'] ?? 'Dr(a). Sem Nome',
                      crm: _medicoData['crm'] ?? '',
                      especialidade: _medicoData['especialidade'] ?? 'Não informado',
                      email: _medicoData['email'] ?? 'Não informado',
                      telefone: _medicoData['telefone'] ?? 'Não informado',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

