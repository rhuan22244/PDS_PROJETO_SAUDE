import 'package:flutter/material.dart';
import 'medico_home_page.dart';

class LoginMedicoPage extends StatefulWidget {
  const LoginMedicoPage({Key? key}) : super(key: key);

  @override
  _LoginMedicoPageState createState() => _LoginMedicoPageState();
}

class _LoginMedicoPageState extends State<LoginMedicoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _crmController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  // Simulação de login (aqui poderia vir de banco/Firestore)
  final String crmValido = "123456";
  final String senhaValida = "medico123";
  final String nomeMedico = "Dr. Carlos Andrade";

  void _login() {
    if (_formKey.currentState!.validate()) {
      if (_crmController.text == crmValido &&
          _senhaController.text == senhaValida) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MedicoHomePage(
              nomeMedico: nomeMedico,
              medicoId: crmValido, // aqui pode ser o CRM como id
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("CRM ou senha inválidos!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login Médico"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medical_services,
                  size: 80, color: Colors.red),
              const SizedBox(height: 20),

              // Campo CRM
              TextFormField(
                controller: _crmController,
                decoration: InputDecoration(
                  labelText: "CRM",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Informe seu CRM";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Campo Senha
              TextFormField(
                controller: _senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Senha",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Informe sua senha";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Botão Login
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.red,
                ),
                child: Text("Entrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
