import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:projeto_pds_final/vacinas/VacinasPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'cadastro_e_login/login_page.dart';
import 'consultas/consultas.page.dart';
import 'documentos/documentos_screen.dart';
import 'exames/exames_screen.dart';
import 'farmacias/farmacias_screen.dart';
import 'hospitais/hospitais_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nomeUsuario = 'Usuário';
  File? _imagemPerfil;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _carregarNomeUsuario();
    _carregarImagemPerfil();
  }

  Future<void> _carregarNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeUsuario = prefs.getString('nomeUsuario') ?? 'Usuário';
    });
  }

  Future<void> _carregarImagemPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final caminhoImagem = prefs.getString('caminhoImagemPerfil');
    if (caminhoImagem != null && caminhoImagem.isNotEmpty) {
      final arquivo = File(caminhoImagem);
      if (await arquivo.exists()) {
        setState(() {
          _imagemPerfil = arquivo;
        });
      } else {
        prefs.remove('caminhoImagemPerfil');
      }
    }
  }

  Future<void> _escolherImagem() async {
    final XFile? imagemSelecionada =
    await _picker.pickImage(source: ImageSource.gallery);
    if (imagemSelecionada != null) {
      setState(() {
        _imagemPerfil = File(imagemSelecionada.path);
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('caminhoImagemPerfil', imagemSelecionada.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
        title: Row(
          children: [
            GestureDetector(
              onTap: _escolherImagem,
              child: CircleAvatar(
                radius: 20,
                backgroundImage: _imagemPerfil != null
                    ? FileImage(_imagemPerfil!)
                    : AssetImage('assets/user.png') as ImageProvider,
              ),
            ),
            SizedBox(width: 10),
            Text('Olá $nomeUsuario!',
            style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCarouselBanners(context),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Encontre tudo aqui com o aplicativo Saúde+',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Serviços:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildServiceItem(Icons.vaccines, 'Vacinas', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VacinasPage())
                    );
                  }),
                  _buildServiceItem(Icons.biotech, 'Exames', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExamesPage())
                    );
                  }),
                  _buildServiceItem(Icons.description, 'Documentos', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DocumentosPage())
                    );
                  }),
                  _buildServiceItem(Icons.local_hospital, 'Hospitais', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HospitaisPage())
                    );
                  }),
                  _buildServiceItem(Icons.medical_services, 'Consultas', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ConsultasPage())
                    );
                  }),
                  _buildServiceItem(Icons.local_pharmacy, 'Farmácias', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FarmaciasPage())
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Mais serviços'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselBanners(BuildContext context) {
    final banners = [
      {
        'img': 'assets/doctors.png',
        'text': 'Os melhores médicos estão aqui',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HospitaisPage()),
          );
        },
      },
      {
        'img': 'assets/banner2.jpeg',
        'text': 'Vacinação perto de você',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VacinasPage()),
          );
        },
      },
      {
        'img': 'assets/banner3.jpeg',
        'text': 'Agende sua consulta sem sair de casa',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ConsultasPage()),
          );
        },
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        enableInfiniteScroll: false,
        pageSnapping: true,
        autoPlay: true,
        autoPlayInterval: Duration(seconds: 4),
        scrollPhysics: BouncingScrollPhysics(),
      ),
      items: banners.map((banner) {
        return GestureDetector(
          onTap: banner['action'] as VoidCallback,
          child: _buildBanner(banner['img'] as String, banner['text'] as String),
        );
      }).toList(),
    );
  }

  Widget _buildBanner(String imagePath, String caption) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.all(16),
      child: Text(
        caption,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(16),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}









