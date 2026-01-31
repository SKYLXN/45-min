import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';
import 'tables.dart';

/// SQLite database helper - Singleton pattern
class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  /// Get database instance (create if not exists)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database (enable foreign keys)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create all tables
    for (final statement in DatabaseTables.allTableCreationStatements) {
      await db.execute(statement);
    }

    // Create indexes
    for (final index in DatabaseTables.createIndexes) {
      await db.execute(index);
    }
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from v1 to v2: Add Firebase fields
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableExercises} 
        ADD COLUMN ${DatabaseConstants.colFirebaseId} TEXT
      ''');
      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableExercises} 
        ADD COLUMN ${DatabaseConstants.colFirebaseName} TEXT
      ''');
    }
    
    // Migration from v2 to v3: Add new BodyMetrics columns
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableBodyMetrics} 
        ADD COLUMN ${DatabaseConstants.colLeanBodyMass} REAL
      ''');
      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableBodyMetrics} 
        ADD COLUMN ${DatabaseConstants.colHeight} REAL
      ''');
      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableBodyMetrics} 
        ADD COLUMN ${DatabaseConstants.colWaistCircumference} REAL
      ''');
    }
    
    print('✅ Database migrated from v$oldVersion to v$newVersion');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing/reset)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // ============================================================================
  // Generic CRUD operations
  // ============================================================================

  /// Insert a record
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update a record
  Future<int> update(
    String table,
    Map<String, dynamic> data,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  /// Delete a record
  Future<int> delete(
    String table,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.delete(
      table,
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  /// Query records
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Raw query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Execute raw SQL
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// Batch operations
  Future<void> batch(Function(Batch batch) operations) async {
    final db = await database;
    final batch = db.batch();
    operations(batch);
    await batch.commit(noResult: true);
  }

  /// Transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // ============================================================================
  // Utility methods
  // ============================================================================

  /// Get record count for a table
  Future<int?> getCount(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.query(
      table,
      columns: ['COUNT(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );
    return Sqflite.firstIntValue(result);
  }

  /// Check if record exists
  Future<bool> exists(
    String table,
    String whereClause,
    List<dynamic> whereArgs,
  ) async {
    final count = await getCount(table, where: whereClause, whereArgs: whereArgs);
    return count != null && count > 0;
  }

  /// Get single record by ID
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final results = await db.query(
      table,
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Delete record by ID
  Future<int> deleteById(String table, String id) async {
    return await delete(
      table,
      '${DatabaseConstants.colId} = ?',
      [id],
    );
  }

  /// Clear all data from a table
  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  /// Get all records from a table
  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String? orderBy,
    int? limit,
  }) async {
    return await query(table, orderBy: orderBy, limit: limit);
  }

  /// Insert multiple records
  Future<void> insertBatch(String table, List<Map<String, dynamic>> records) async {
    await batch((batch) {
      for (final record in records) {
        batch.insert(table, record, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);
    final file = await databaseFactory.openDatabase(path);
    await file.close();
    // Note: Actual file size would require platform-specific code
    return 0; // Placeholder
  }

  /// Vacuum database (optimize storage)
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  // ============================================================================
  // Exercise-specific methods (for seeding)
  // ============================================================================

  /// Get total exercise count
  Future<int> getExerciseCount() async {
    final count = await getCount(DatabaseConstants.tableExercises);
    return count ?? 0;
  }

  /// Insert an exercise from Exercise model
  Future<int> insertExercise(dynamic exercise) async {
    // Note: This is just a simple wrapper - actual insertion should use ExerciseRepository
    // which properly encodes arrays as JSON
    final data = {
      DatabaseConstants.colId: exercise.id,
      DatabaseConstants.colName: exercise.name,
      DatabaseConstants.colMuscleGroup: exercise.muscleGroup,
      DatabaseConstants.colSecondaryMuscles: exercise.secondaryMuscles.join(','),
      DatabaseConstants.colEquipmentRequired: exercise.equipmentRequired.join(','),
      DatabaseConstants.colDifficulty: exercise.difficulty,
      DatabaseConstants.colVideoUrl: exercise.videoUrl,
      DatabaseConstants.colGifUrl: exercise.gifUrl,
      DatabaseConstants.colInstructions: exercise.instructions.join('|||'),
      DatabaseConstants.colTempo: exercise.tempo,
      DatabaseConstants.colIsCompound: exercise.isCompound ? 1 : 0,
      DatabaseConstants.colAlternatives: exercise.alternatives.join(','),
    };
    return await insert(DatabaseConstants.tableExercises, data);
  }

  /// Get exercise by ID
  Future<Map<String, dynamic>?> getExerciseById(String id) async {
    return await getById(DatabaseConstants.tableExercises, id);
  }

  /// Update an exercise
  Future<int> updateExercise(dynamic exercise) async {
    final data = {
      DatabaseConstants.colName: exercise.name,
      DatabaseConstants.colMuscleGroup: exercise.muscleGroup,
      DatabaseConstants.colSecondaryMuscles: exercise.secondaryMuscles.join(','),
      DatabaseConstants.colEquipmentRequired: exercise.equipmentRequired.join(','),
      DatabaseConstants.colDifficulty: exercise.difficulty,
      DatabaseConstants.colVideoUrl: exercise.videoUrl,
      DatabaseConstants.colGifUrl: exercise.gifUrl,
      DatabaseConstants.colInstructions: exercise.instructions.join('|||'),
      DatabaseConstants.colTempo: exercise.tempo,
      DatabaseConstants.colIsCompound: exercise.isCompound ? 1 : 0,
      DatabaseConstants.colAlternatives: exercise.alternatives.join(','),
    };
    return await update(
      DatabaseConstants.tableExercises,
      data,
      '${DatabaseConstants.colId} = ?',
      [exercise.id],
    );
  }

  /// Delete all exercises
  Future<void> deleteAllExercises() async {
    await clearTable(DatabaseConstants.tableExercises);
  }
}

