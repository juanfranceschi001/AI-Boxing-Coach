import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/angle_mode.dart';
import '../../models/form_issue.dart';
import '../../models/session_result.dart';
import '../../models/workout_mode.dart';

/// Local-only (on-device) persistence for past session summaries. No
/// backend/cloud sync, per the app's zero-cost requirement.
class SessionRepository {
  Database? _db;

  Future<Database> _database() async {
    final existing = _db;
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/sessions.db';
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startedAt TEXT NOT NULL,
            durationMs INTEGER NOT NULL,
            mode TEXT NOT NULL,
            angle TEXT NOT NULL,
            roundsCompleted INTEGER,
            punchCount INTEGER,
            issueCountsJson TEXT NOT NULL
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  Future<int> save(SessionResult result) async {
    final db = await _database();
    final issueJson = <String, int>{
      for (final entry in result.issueCounts.entries)
        entry.key.name: entry.value,
    };
    return db.insert('sessions', {
      'startedAt': result.startedAt.toIso8601String(),
      'durationMs': result.duration.inMilliseconds,
      'mode': result.mode.name,
      'angle': result.angle.name,
      'roundsCompleted': result.roundsCompleted,
      'punchCount': result.punchCount,
      'issueCountsJson': jsonEncode(issueJson),
    });
  }

  Future<List<SessionResult>> loadAll() async {
    final db = await _database();
    final rows = await db.query('sessions', orderBy: 'startedAt DESC');
    return rows.map(_fromRow).toList();
  }

  SessionResult _fromRow(Map<String, Object?> row) {
    final issueJson =
        jsonDecode(row['issueCountsJson'] as String) as Map<String, dynamic>;
    final issueCounts = <FormIssueType, int>{};
    for (final entry in issueJson.entries) {
      for (final type in FormIssueType.values) {
        if (type.name == entry.key) {
          issueCounts[type] = entry.value as int;
          break;
        }
      }
    }

    return SessionResult(
      id: row['id'] as int,
      startedAt: DateTime.parse(row['startedAt'] as String),
      duration: Duration(milliseconds: row['durationMs'] as int),
      mode: WorkoutMode.values.firstWhere((m) => m.name == row['mode']),
      angle: AngleMode.values.firstWhere((a) => a.name == row['angle']),
      roundsCompleted: row['roundsCompleted'] as int?,
      punchCount: row['punchCount'] as int?,
      issueCounts: issueCounts,
    );
  }
}
