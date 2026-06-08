import 'dart:convert';
import '../database/database_helper.dart';
import '../models/memory_model.dart';

class MemoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> saveMemory(MemoryModel memory) async {
    final data = {
      'key': memory.key,
      'value': memory.value,
      'category': memory.category,
      'metadata': memory.metadata != null ? jsonEncode(memory.metadata) : null,
      'created_at': memory.createdAt.millisecondsSinceEpoch,
      'updated_at': memory.updatedAt.millisecondsSinceEpoch,
    };

    if (memory.id != null) {
      return await _dbHelper.update(
        'user_memory',
        data,
        'id = ?',
        [memory.id],
      );
    } else {
      return await _dbHelper.insert('user_memory', data);
    }
  }

  Future<MemoryModel?> getMemory(String key) async {
    final results = await _dbHelper.query(
      'user_memory',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return _mapToMemoryModel(results.first);
  }

  Future<List<MemoryModel>> searchMemory(String query) async {
    final results = await _dbHelper.query(
      'user_memory',
      where: 'key LIKE ? OR value LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );

    return results.map(_mapToMemoryModel).toList();
  }

  Future<List<MemoryModel>> getMemoryByCategory(String category) async {
    final results = await _dbHelper.query(
      'user_memory',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'updated_at DESC',
    );

    return results.map(_mapToMemoryModel).toList();
  }

  Future<List<MemoryModel>> getAllMemory({int? limit}) async {
    final results = await _dbHelper.query(
      'user_memory',
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    return results.map(_mapToMemoryModel).toList();
  }

  Future<int> deleteMemory(int id) async {
    return await _dbHelper.delete('user_memory', 'id = ?', [id]);
  }

  Future<int> deleteMemoryByKey(String key) async {
    return await _dbHelper.delete('user_memory', 'key = ?', [key]);
  }

  Future<void> deleteAllMemory() async {
    await _dbHelper.execute('DELETE FROM user_memory');
  }

  Future<List<String>> getAllCategories() async {
    final results = await _dbHelper.rawQuery(
      'SELECT DISTINCT category FROM user_memory WHERE category IS NOT NULL',
    );
    return results.map((r) => r['category'] as String).toList();
  }

  MemoryModel _mapToMemoryModel(Map<String, dynamic> row) {
    return MemoryModel(
      id: row['id'] as int,
      key: row['key'] as String,
      value: row['value'] as String,
      category: row['category'] as String?,
      metadata: row['metadata'] != null
          ? jsonDecode(row['metadata'] as String) as Map<String, dynamic>
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  Future<int> addConversation(ConversationModel conversation) async {
    final data = {
      'session_id': conversation.sessionId,
      'role': conversation.role,
      'content': conversation.content,
      'timestamp': conversation.timestamp.millisecondsSinceEpoch,
      'metadata': conversation.metadata != null
          ? jsonEncode(conversation.metadata)
          : null,
    };

    return await _dbHelper.insert('conversation_history', data);
  }

  Future<List<ConversationModel>> getConversationHistory(
    String sessionId, {
    int limit = 50,
  }) async {
    final results = await _dbHelper.query(
      'conversation_history',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return results.map(_mapToConversationModel).toList();
  }

  Future<List<String>> getConversationSessions() async {
    final results = await _dbHelper.rawQuery(
      'SELECT DISTINCT session_id FROM conversation_history ORDER BY timestamp DESC',
    );
    return results.map((r) => r['session_id'] as String).toList();
  }

  Future<void> clearConversationHistory(String sessionId) async {
    await _dbHelper.delete(
      'conversation_history',
      'session_id = ?',
      [sessionId],
    );
  }

  ConversationModel _mapToConversationModel(Map<String, dynamic> row) {
    return ConversationModel(
      id: row['id'] as int,
      sessionId: row['session_id'] as String,
      role: row['role'] as String,
      content: row['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      metadata: row['metadata'] != null
          ? jsonDecode(row['metadata'] as String) as Map<String, dynamic>
          : null,
    );
  }

  Future<int> addReminder(ReminderModel reminder) async {
    final data = {
      'title': reminder.title,
      'description': reminder.description,
      'trigger_time': reminder.triggerTime?.millisecondsSinceEpoch,
      'recurrence': reminder.recurrence,
      'is_completed': reminder.isCompleted ? 1 : 0,
      'priority': reminder.priority,
      'created_at': reminder.createdAt.millisecondsSinceEpoch,
      'updated_at': reminder.updatedAt.millisecondsSinceEpoch,
    };

    if (reminder.id != null) {
      return await _dbHelper.update(
        'reminders',
        data,
        'id = ?',
        [reminder.id],
      );
    } else {
      return await _dbHelper.insert('reminders', data);
    }
  }

  Future<List<ReminderModel>> getReminders() async {
    final results = await _dbHelper.query(
      'reminders',
      orderBy: 'trigger_time ASC, priority DESC',
    );

    return results.map(_mapToReminderModel).toList();
  }

  Future<List<ReminderModel>> getPendingReminders() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final results = await _dbHelper.query(
      'reminders',
      where: 'is_completed = 0 AND (trigger_time IS NULL OR trigger_time <= ?)',
      whereArgs: [now],
      orderBy: 'priority DESC, trigger_time ASC',
    );

    return results.map(_mapToReminderModel).toList();
  }

  Future<int> completeReminder(int id) async {
    return await _dbHelper.update(
      'reminders',
      {
        'is_completed': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      'id = ?',
      [id],
    );
  }

  ReminderModel _mapToReminderModel(Map<String, dynamic> row) {
    return ReminderModel(
      id: row['id'] as int,
      title: row['title'] as String,
      description: row['description'] as String?,
      triggerTime: row['trigger_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['trigger_time'] as int)
          : null,
      recurrence: row['recurrence'] as String?,
      isCompleted: (row['is_completed'] as int) == 1,
      priority: row['priority'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
