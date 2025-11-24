import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../HomePage.dart';
import '../medico/medico_home_page.dart';
import 'CadastroPage.dart';
import '../medico/MedicoCadastroPage.dart';

enum UserType { paciente, medico }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserType _selectedUserType = UserType.paciente;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("Usuário não encontrado após o login.");
      }

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        final String tipoNoBanco = doc.data()?['tipoUsuario'] ?? '';
        final String tipoSelecionado = _selectedUserType.name;

        if (tipoNoBanco == tipoSelecionado) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('nomeUsuario', doc.data()?['nome'] ?? 'Usuário');
          if (mounted) _navigateToHomePage(doc.data()!, user.uid);

        } else {
          await _auth.signOut();
          setState(() {
            _errorMessage = "Usuário encontrado, mas não neste perfil. Tente o outro.";
          });
        }
      } else {
        await _auth.signOut();
        setState(() {
          _errorMessage = "Dados do usuário não encontrados no banco de dados.";
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _traduzirErroFirebase(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Ocorreu um erro inesperado: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRegisterOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Criar Nova Conta"),
          content: const Text("Selecione o tipo de perfil que deseja criar."),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Sou Paciente"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CadastroPage()));
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("Sou Médico"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicoCadastroPage()));
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToHomePage(Map<String, dynamic> userData, String userId) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_selectedUserType == UserType.paciente) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        final String nomeMedico = userData['nome'] ?? 'Médico';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MedicoHomePage(
              nomeMedico: nomeMedico,
              medicoId: userId,
            ),
          ),
        );
      }
    });
  }

  String _traduzirErroFirebase(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha inválidos.';
      default:
        return 'Ocorreu um erro. Tente novamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset("assets/logo.png", height: 250),
                  const SizedBox(height: 20),
                  const Text(
                    "Selecione seu perfil para entrar",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<UserType>(
                    segments: const <ButtonSegment<UserType>>[
                      ButtonSegment<UserType>(
                          value: UserType.paciente,
                          label: Text('Paciente'),
                          icon: Icon(Icons.person)),
                      ButtonSegment<UserType>(
                          value: UserType.medico,
                          label: Text('Médico'),
                          icon: Icon(Icons.medical_services)),
                    ],
                    selected: <UserType>{_selectedUserType},
                    onSelectionChanged: (Set<UserType> newSelection) {
                      setState(() {
                        _selectedUserType = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.red,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Informe o email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: senhaController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Senha",
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Informe a senha';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Login"),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Não tem uma conta? "),
                      TextButton(
                        onPressed: () => _showRegisterOptions(context),
                        child: const Text("Criar uma", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

