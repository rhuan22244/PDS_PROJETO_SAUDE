import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicoCadastroPage extends StatefulWidget {
  const MedicoCadastroPage({super.key});

  @override
  _MedicoCadastroPageState createState() => _MedicoCadastroPageState();
}

class _MedicoCadastroPageState extends State<MedicoCadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _crmController = TextEditingController();
  final TextEditingController _especialidadeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController(); // 🔹 NOVO

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _registerMedico() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'crm': _crmController.text.trim(),
        'especialidade': _especialidadeController.text.trim(),
        'telefone': _telefoneController.text.trim(), // 🔹 NOVO: Salva o telefone
        'tipoUsuario': 'medico',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro de médico realizado com sucesso!')),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(traduzirErroFirebase(e.code))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String traduzirErroFirebase(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Este e-mail já está em uso.';
      case 'invalid-email': return 'E-mail inválido.';
      case 'weak-password': return 'A senha deve ter pelo menos 6 caracteres.';
      default: return 'Ocorreu um erro inesperado.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro Médico'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 10),
                const Text(
                  "Preencha todos os campos para se cadastrar como médico.",
                  style: TextStyle(fontSize: 16),
                ),
                const Divider(),
                TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Insira seu nome' : null),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) ? 'Insira um e-mail válido' : null),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _senhaController,
                    decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? 'A senha deve ter ao menos 6 caracteres' : null),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _crmController,
                    decoration: const InputDecoration(labelText: 'CRM', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Insira seu CRM' : null),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _especialidadeController,
                    decoration: const InputDecoration(labelText: 'Especialidade', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Insira sua especialidade' : null),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _telefoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Insira seu telefone' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerMedico,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Cadastrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}