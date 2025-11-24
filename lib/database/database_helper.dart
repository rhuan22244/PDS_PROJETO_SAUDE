import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer'; // Para um logging mais eficaz

import '../consultas/Consulta.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // 🔹 A versão do banco de dados agora é uma constante para facilitar as migrações.
  static const int _dbVersion = 1;
  static const String _dbName = 'app_consultas.db';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // 🔥 Adicionado handler para migrações
    );
  }

  // Cria a tabela inicial do banco de dados
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE consultas (
        id $idType,
        especialidade $textType,
        local $textType,
        data $textType,
        hora $textType,
        status $textType
      )
    ''');
  }

  // Lida com futuras atualizações de schema (essencial para novas versões do app)
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Exemplo: Se você estiver na versão 1 e quiser ir para a 2,
    // adicione a lógica de migração aqui.
    if (oldVersion < 2) {
      // await db.execute("ALTER TABLE consultas ADD COLUMN novaColuna TEXT;");
    }
  }

  // Insere uma nova consulta
  Future<int> insertConsulta(Consulta consulta) async {
    try {
      final db = await instance.database;
      // Remove o id nulo para garantir que o autoincremento funcione
      final map = consulta.toMap()..remove('id');
      return await db.insert('consultas', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      log('Erro ao inserir consulta: $e');
      return -1; // Retorna -1 para indicar falha
    }
  }

  // ✨ Novo método para inserir múltiplas consultas de forma otimizada
  Future<void> insertConsultasBatch(List<Consulta> consultas) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var consulta in consultas) {
      final map = consulta.toMap()..remove('id');
      batch.insert('consultas', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true); // `noResult: true` é mais rápido
  }

  // Em DatabaseHelper.dart

  Future<List<Consulta>> getConsultas() async {
    try {
      final db = await instance.database;
      // Ordena por ID para consistência
      final result = await db.query('consultas', orderBy: 'id DESC');

      // ▼▼▼ CORREÇÃO AQUI ▼▼▼
      return result.map((json) {
        // Não é mais necessário extrair o 'id' aqui.
        // A chamada agora passa apenas o mapa 'json'.
        return Consulta.fromMap(json);
      }).toList();
      // ▲▲▲ FIM DA CORREÇÃO ▲▲▲

    } catch (e) {
      log('Erro ao buscar consultas: $e');
      return []; // Retorna lista vazia em caso de erro
    }
  }

  // Atualiza uma consulta
  Future<int> updateConsulta(Consulta consulta) async {
    final db = await instance.database;
    return db.update(
      'consultas',
      consulta.toMap(),
      where: 'id = ?',
      whereArgs: [int.tryParse(consulta.id ?? '')], // Converte o ID string para int
    );
  }

  // Deleta uma consulta pelo id (int)
  Future<int> deleteConsulta(int id) async {
    final db = await instance.database;
    return await db.delete(
      'consultas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null; // Garante que será reinicializado na próxima chamada
  }
}







