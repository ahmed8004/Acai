import 'package:freezed_annotation/freezed_annotation.dart';

part 'memory_model.freezed.dart';
part 'memory_model.g.dart';

@freezed
class MemoryModel with _$MemoryModel {
  const factory MemoryModel({
    required int? id,
    required String key,
    required String value,
    String? category,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MemoryModel;

  factory MemoryModel.fromJson(Map<String, dynamic> json) =>
      _$MemoryModelFromJson(json);

  factory MemoryModel.create({
    String? id,
    required String key,
    required String value,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return MemoryModel(
      id: null,
      key: key,
      value: value,
      category: category,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }
}

@freezed
class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required int? id,
    required String sessionId,
    required String role,
    required String content,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  factory ConversationModel.create({
    String? sessionId,
    required String role,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return ConversationModel(
      id: null,
      sessionId: sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: role,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }
}

@freezed
class ReminderModel with _$ReminderModel {
  const factory ReminderModel({
    required int? id,
    required String title,
    String? description,
    DateTime? triggerTime,
    String? recurrence,
    @Default(false) bool isCompleted,
    @Default(1) int priority,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReminderModel;

  factory ReminderModel.fromJson(Map<String, dynamic> json) =>
      _$ReminderModelFromJson(json);

  factory ReminderModel.create({
    required String title,
    String? description,
    DateTime? triggerTime,
    String? recurrence,
    int priority = 1,
  }) {
    final now = DateTime.now();
    return ReminderModel(
      id: null,
      title: title,
      description: description,
      triggerTime: triggerTime,
      recurrence: recurrence,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
  }
}

@freezed
class FileIndexModel with _$FileIndexModel {
  const factory FileIndexModel({
    required int? id,
    required String path,
    required String filename,
    String? extension,
    int? size,
    DateTime? modifiedTime,
    @Default(false) bool isDirectory,
    String? mimeType,
    Map<String, dynamic>? metadata,
    required DateTime indexedAt,
  }) = _FileIndexModel;

  factory FileIndexModel.fromJson(Map<String, dynamic> json) =>
      _$FileIndexModelFromJson(json);

  factory FileIndexModel.create({
    required String path,
    required String filename,
    String? extension,
    int? size,
    DateTime? modifiedTime,
    bool isDirectory = false,
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) {
    return FileIndexModel(
      id: null,
      path: path,
      filename: filename,
      extension: extension,
      size: size,
      modifiedTime: modifiedTime,
      isDirectory: isDirectory,
      mimeType: mimeType,
      metadata: metadata,
      indexedAt: DateTime.now(),
    );
  }
}

@freezed
class DownloadTaskModel with _$DownloadTaskModel {
  const factory DownloadTaskModel({
    required int? id,
    required String url,
    required String filePath,
    required String filename,
    required DownloadStatus status,
    @Default(0) int progress,
    int? totalBytes,
    @Default(0) int downloadedBytes,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _DownloadTaskModel;

  factory DownloadTaskModel.fromJson(Map<String, dynamic> json) =>
      _$DownloadTaskModelFromJson(json);

  factory DownloadTaskModel.create({
    required String url,
    required String filePath,
    required String filename,
  }) {
    return DownloadTaskModel(
      id: null,
      url: url,
      filePath: filePath,
      filename: filename,
      status: DownloadStatus.pending,
      createdAt: DateTime.now(),
    );
  }
}

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

@freezed
class AppContextModel with _$AppContextModel {
  const factory AppContextModel({
    required String key,
    required String value,
    required DateTime updatedAt,
  }) = _AppContextModel;

  factory AppContextModel.fromJson(Map<String, dynamic> json) =>
      _$AppContextModelFromJson(json);

  factory AppContextModel.create({
    required String key,
    required String value,
  }) {
    return AppContextModel(
      key: key,
      value: value,
      updatedAt: DateTime.now(),
    );
  }
}

@freezed
class AutomationModel with _$AutomationModel {
  const factory AutomationModel({
    required int? id,
    required String name,
    required String triggerType,
    Map<String, dynamic>? triggerData,
    required String actionType,
    Map<String, dynamic>? actionData,
    @Default(true) bool isEnabled,
    required DateTime createdAt,
  }) = _AutomationModel;

  factory AutomationModel.fromJson(Map<String, dynamic> json) =>
      _$AutomationModelFromJson(json);

  factory AutomationModel.create({
    required String name,
    required String triggerType,
    Map<String, dynamic>? triggerData,
    required String actionType,
    Map<String, dynamic>? actionData,
  }) {
    return AutomationModel(
      id: null,
      name: name,
      triggerType: triggerType,
      triggerData: triggerData,
      actionType: actionType,
      actionData: actionData,
      createdAt: DateTime.now(),
    );
  }
}

@freezed
class TermuxScriptModel with _$TermuxScriptModel {
  const factory TermuxScriptModel({
    required int? id,
    required String name,
    required String content,
    String? description,
    String? category,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TermuxScriptModel;

  factory TermuxScriptModel.fromJson(Map<String, dynamic> json) =>
      _$TermuxScriptModelFromJson(json);

  factory TermuxScriptModel.create({
    required String name,
    required String content,
    String? description,
    String? category,
  }) {
    final now = DateTime.now();
    return TermuxScriptModel(
      id: null,
      name: name,
      content: content,
      description: description,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
  }
}
