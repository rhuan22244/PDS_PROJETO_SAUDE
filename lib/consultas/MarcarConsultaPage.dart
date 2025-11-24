import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'Consulta.dart' as consulta_model;

const Map<String, int> diasSemana = {
  'Domingo': 7,
  'Segunda': 1,
  'Terça': 2,
  'Quarta': 3,
  'Quinta': 4,
  'Sexta': 5,
  'Sábado': 6,
};

class MarcarConsultaPage extends StatefulWidget {
  final void Function(consulta_model.Consulta) onConsultaMarcada;

  const MarcarConsultaPage({super.key, required this.onConsultaMarcada});

  @override
  _MarcarConsultaPageState createState() => _MarcarConsultaPageState();
}

class _MarcarConsultaPageState extends State<MarcarConsultaPage> {
  final _formKey = GlobalKey<FormState>();
  final _horaController = TextEditingController();

  String? _especialidadeSelecionada;
  String? _localSelecionado;
  String? _diaSelecionado;

  // Novos campos para armazenar o ID e o nome do médico
  String? _medicoIdSelecionado;
  String? _medicoNomeSelecionado;

  List<String> especialidades = [];
  List<String> locais = [];
  List<String> diasDisponiveis = [];
  List<String> horariosDisponiveis = [];

  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchEspecialidades();
  }

  Future<void> _fetchEspecialidades() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('Especialidades').get();
      final nomes = snapshot.docs.map((doc) => doc.id).toList();

      if (!mounted) return;
      setState(() {
        especialidades = nomes..sort();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar especialidades: $e')),
      );
    }
  }

  Future<void> _buscarLocaisEDias() async {
    if (_especialidadeSelecionada == null) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Especialidades')
          .doc(_especialidadeSelecionada)
          .get();

      if (!docSnapshot.exists) return;
      final data = docSnapshot.data()!;

      List<String> locaisCarregados = [];
      final local = data['Local'];
      if (local is String) locaisCarregados = [local];
      if (local is List) locaisCarregados = local.cast<String>();

      final diasPermitidos = data['Dias_Permitidos'] ?? [];
      List<int> diasSemanaPermitidos = [];

      if (diasPermitidos is List) {
        diasSemanaPermitidos = diasPermitidos
            .map((dia) => diasSemana[dia] ?? -1)
            .where((num) => num != -1)
            .toList();
      }

      List<String> datasDisponiveis = [];
      DateTime hoje = DateTime.now();
      for (int i = 0; i < 60; i++) {
        final data = hoje.add(Duration(days: i));
        if (diasSemanaPermitidos.contains(data.weekday)) {
          datasDisponiveis.add(DateFormat('yyyy-MM-dd').format(data));
        }
      }

      // Adicionei estas duas linhas para pegar os dados do médico
      final medicoId = data['medicoId'] as String?;
      final medicoNome = data['medicoNome'] as String?;

      if (!mounted) return;
      setState(() {
        locais = locaisCarregados;
        _localSelecionado = locais.isNotEmpty ? locais.first : null;
        diasDisponiveis = datasDisponiveis;
        _diaSelecionado = null;
        _horaController.clear();
        horariosDisponiveis = [];

        // Armazena os dados do médico nas variáveis de estado
        _medicoIdSelecionado = medicoId;
        _medicoNomeSelecionado = medicoNome;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar locais e dias: $e')),
      );
    }
  }

  Future<void> _carregarHorariosDisponiveis() async {
    if (_especialidadeSelecionada == null ||
        _diaSelecionado == null ||
        _localSelecionado == null) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Especialidades')
          .doc(_especialidadeSelecionada)
          .get();

      List<String> todosHorarios = [];
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final rawHorarios = data['Horarios'];

        if (rawHorarios is String) {
          todosHorarios = rawHorarios.split(',').map((h) => h.trim()).toList();
        } else if (rawHorarios is List) {
          todosHorarios = rawHorarios.cast<String>();
        }
      }

      final consultasDoDia = await FirebaseFirestore.instance
          .collection('Consultas')
          .where('especialidade', isEqualTo: _especialidadeSelecionada)
          .where('data', isEqualTo: _diaSelecionado)
          .where('local', isEqualTo: _localSelecionado)
          .get();

      final horariosOcupados = consultasDoDia.docs
          .where((doc) => doc['status'] == 'Agendada')
          .map((doc) => (doc['hora'] as String).trim())
          .toList();

      if (!mounted) return;
      setState(() {
        horariosDisponiveis = todosHorarios
            .where((hora) => !horariosOcupados.contains(hora))
            .toList();
        _horaController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar horários disponíveis: $e')),
      );
    }
  }

  Future<void> _selecionarHora() async {
    if (horariosDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum horário disponível.')),
      );
      return;
    }

    final horaSelecionada = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        children: horariosDisponiveis.map((hora) {
          return ListTile(
            title: Text(hora),
            onTap: () => Navigator.pop(context, hora),
          );
        }).toList(),
      ),
    );

    if (horaSelecionada != null && mounted) {
      setState(() {
        _horaController.text = horaSelecionada;
      });
    }
  }

  Future<void> _marcarConsulta() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    // Criando a data completa e o Timestamp
    final dataHoraString = '${_diaSelecionado!} ${_horaController.text}';
    final dataHoraCompleta = DateFormat('yyyy-MM-dd HH:mm').parse(dataHoraString);

    final novaConsulta = consulta_model.Consulta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      especialidade: _especialidadeSelecionada!,
      local: _localSelecionado!,
      data: _diaSelecionado!,
      hora: _horaController.text,
      status: 'Agendada',
      dataHoraCompleta: Timestamp.fromDate(dataHoraCompleta),
      medicoId: _medicoIdSelecionado,
      medicoNome: _medicoNomeSelecionado,
      pacienteId: user.uid, // <--- Adicionei esta linha crucial
    );

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('Consultas')
          .add(novaConsulta.toMap());
      widget.onConsultaMarcada(novaConsulta);

      // Notificação imediata confirmando o agendamento
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: docRef.id.hashCode,
          channelKey: 'basic_channel',
          title: 'Consulta Agendada!',
          body:
          'Sua consulta de ${novaConsulta.especialidade} foi agendada para ${novaConsulta.data} às ${novaConsulta.hora} no ${novaConsulta.local}.',
        ),
      );

      // Agendar lembrete para 2 dias antes da consulta
      final consultaDateTime = DateFormat('yyyy-MM-dd HH:mm')
          .parse('${novaConsulta.data} ${novaConsulta.hora}');

      // Calcula 2 dias antes
      final notificationTime = consultaDateTime.subtract(const Duration(days: 2));

      // Só agenda se ainda for futuro
      if (notificationTime.isAfter(DateTime.now())) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: docRef.id.hashCode + 1, // usa outro ID para não sobrescrever
            channelKey: 'basic_channel',
            title: 'Lembrete de Consulta',
            body:
            'Você tem uma consulta de ${novaConsulta.especialidade} em ${novaConsulta.local}, no dia ${novaConsulta.data} às ${novaConsulta.hora}.',
          ),
          schedule: NotificationCalendar.fromDate(date: notificationTime),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar consulta: $e')),
      );
    }
  }

  @override
  void dispose() {
    _horaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcar Nova Consulta'),
        backgroundColor: Colors.redAccent,
      ),
      body: especialidades.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Especialidade'),
                items: especialidades
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                value: _especialidadeSelecionada,
                onChanged: (val) async {
                  setState(() {
                    _especialidadeSelecionada = val;
                    _horaController.clear();
                    locais = [];
                    diasDisponiveis = [];
                    _localSelecionado = null;
                    _diaSelecionado = null;
                    horariosDisponiveis = [];
                  });
                  if (val != null) await _buscarLocaisEDias();
                },
                validator: (val) => val == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              // Adicionei este widget para exibir o nome do médico
              if (_medicoNomeSelecionado != null)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Médico'),
                  subtitle: Text(_medicoNomeSelecionado!),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Local'),
                items: locais
                    .map((local) =>
                    DropdownMenuItem(value: local, child: Text(local)))
                    .toList(),
                value: _localSelecionado,
                onChanged: (val) async {
                  setState(() {
                    _localSelecionado = val;
                    _horaController.clear();
                    horariosDisponiveis = [];
                  });
                  if (val != null && _diaSelecionado != null) {
                    await _carregarHorariosDisponiveis();
                  }
                },
                validator: (val) => val == null ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              if (diasDisponiveis.isNotEmpty) ...[
                const Text("Selecione o Dia:", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 60)),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) =>
                  _diaSelecionado != null &&
                      DateFormat('yyyy-MM-dd').format(day) == _diaSelecionado,
                  onDaySelected: (selectedDay, _) async {
                    final selecionado =
                    DateFormat('yyyy-MM-dd').format(selectedDay);
                    if (diasDisponiveis.contains(selecionado)) {
                      setState(() {
                        _diaSelecionado = selecionado;
                        _focusedDay = selectedDay;
                      });
                      await _carregarHorariosDisponiveis();
                    }
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) {
                      final dataStr =
                      DateFormat('yyyy-MM-dd').format(day);
                      final isDisponivel =
                      diasDisponiveis.contains(dataStr);
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color:
                            isDisponivel ? Colors.black : Colors.grey,
                          ),
                        ),
                      );
                    },
                    markerBuilder: (context, day, events) {
                      final dataStr =
                      DateFormat('yyyy-MM-dd').format(day);
                      final isDisponivel =
                      diasDisponiveis.contains(dataStr);
                      if (isDisponivel) {
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _horaController,
                decoration: const InputDecoration(
                  labelText: 'Hora (HH:mm)',
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: _selecionarHora,
                validator: (val) =>
                val == null || val.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _marcarConsulta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Marcar Consulta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}