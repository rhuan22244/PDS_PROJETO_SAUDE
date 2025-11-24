import 'package:cloud_firestore/cloud_firestore.dart';

class EspecialidadeService {
  final CollectionReference especialidadesCollection =
  FirebaseFirestore.instance.collection('Especialidades');

  Future<List<String>> getEspecialidades() async {
    final snapshot = await especialidadesCollection.get();
    return snapshot.docs.map((doc) => doc['nome'] as String).toList();
  }
}
