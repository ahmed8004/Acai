class MemoryModel {
  final int? id;
  final String key;
  final String value;
  final String? category;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemoryModel({
    this.id,
    required this.key,
    required this.value,
    this.category,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'] as int?,
      key: json['key'] as String,
      value: json['value'] as String,
      category: json['category'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'category': category,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MemoryModel.create({
    int? id,
    required String key,
    required String value,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return MemoryModel(
      id: id,
      key: key,
      value: value,
      category: category,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  MemoryModel copyWith({
    int? id,
    String? key,
    String? value,
    String? category,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ConversationModel {
  final int? id;
  final String sessionId;
  final String role;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ConversationModel({
    this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as int?,
      sessionId: json['sessionId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

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

  ConversationModel copyWith({
    int? id,
    String? sessionId,
    String? role,
    String? content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ReminderModel {
  final int? id;
  final String title;
  final String? description;
  final DateTime? triggerTime;
  final String? recurrence;
  final bool isCompleted;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderModel({
    this.id,
    required this.title,
    this.description,
    this.triggerTime,
    this.recurrence,
    this.isCompleted = false,
    this.priority = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      triggerTime: json['triggerTime'] != null 
          ? DateTime.parse(json['triggerTime'] as String)
          : null,
      recurrence: json['recurrence'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: json['priority'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'triggerTime': triggerTime?.toIso8601String(),
      'recurrence': recurrence,
      'isCompleted': isCompleted,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReminderModel.create({
    int? id,
    required String title,
    String? description,
    DateTime? triggerTime,
    String? recurrence,
    int priority = 1,
  }) {
    final now = DateTime.now();
    return ReminderModel(
      id: id,
      title: title,
      description: description,
      triggerTime: triggerTime,
      recurrence: recurrence,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
  }

  ReminderModel copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? triggerTime,
    String? recurrence,
    bool? isCompleted,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      triggerTime: triggerTime ?? this.triggerTime,
      recurrence: recurrence ?? this.recurrence,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FileIndexModel {
  final int? id;
  final String path;
  final String filename;
  final String? extension;
  final int? size;
  final DateTime? modifiedTime;
  final bool isDirectory;
  final String? mimeType;
  final Map<String, dynamic>? metadata;
  final DateTime indexedAt;

  FileIndexModel({
    this.id,
    required this.path,
    required this.filename,
    this.extension,
    this.size,
    this.modifiedTime,
    this.isDirectory = false,
    this.mimeType,
    this.metadata,
    required this.indexedAt,
  });

  factory FileIndexModel.fromJson(Map<String, dynamic> json) {
    return FileIndexModel(
      id: json['id'] as int?,
      path: json['path'] as String,
      filename: json['filename'] as String,
      extension: json['extension'] as String?,
      size: json['size'] as int?,
      modifiedTime: json['modifiedTime'] != null
          ? DateTime.parse(json['modifiedTime'] as String)
          : null,
      isDirectory: json['isDirectory'] as bool? ?? false,
      mimeType: json['mimeType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      indexedAt: DateTime.parse(json['indexedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'filename': filename,
      'extension': extension,
      'size': size,
      'modifiedTime': modifiedTime?.toIso8601String(),
      'isDirectory': isDirectory,
      'mimeType': mimeType,
      'metadata': metadata,
      'indexedAt': indexedAt.toIso8601String(),
    };
  }

  factory FileIndexModel.create({
    int? id,
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
      id: id,
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

  FileIndexModel copyWith({
    int? id,
    String? path,
    String? filename,
    String? extension,
    int? size,
    DateTime? modifiedTime,
    bool? isDirectory,
    String? mimeType,
    Map<String, dynamic>? metadata,
    DateTime? indexedAt,
  }) {
    return FileIndexModel(
      id: id ?? this.id,
      path: path ?? this.path,
      filename: filename ?? this.filename,
      extension: extension ?? this.extension,
      size: size ?? this.size,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      isDirectory: isDirectory ?? this.isDirectory,
      mimeType: mimeType ?? this.mimeType,
      metadata: metadata ?? this.metadata,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }
}

class DownloadTaskModel {
  final int? id;
  final String url;
  final String filePath;
  final String filename;
  final DownloadStatus status;
  final int progress;
  final int? totalBytes;
  final int downloadedBytes;
  final DateTime createdAt;
  final DateTime? completedAt;

  DownloadTaskModel({
    this.id,
    required this.url,
    required this.filePath,
    required this.filename,
    required this.status,
    this.progress = 0,
    this.totalBytes,
    this.downloadedBytes = 0,
    required this.createdAt,
    this.completedAt,
  });

  factory DownloadTaskModel.fromJson(Map<String, dynamic> json) {
    return DownloadTaskModel(
      id: json['id'] as int?,
      url: json['url'] as String,
      filePath: json['filePath'] as String,
      filename: json['filename'] as String,
      status: DownloadStatus.values.byName(json['status'] as String),
      progress: json['progress'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int?,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filePath': filePath,
      'filename': filename,
      'status': status.name,
      'progress': progress,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DownloadTaskModel.create({
    int? id,
    required String url,
    required String filePath,
    required String filename,
  }) {
    return DownloadTaskModel(
      id: id,
      url: url,
      filePath: filePath,
      filename: filename,
      status: DownloadStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  DownloadTaskModel copyWith({
    int? id,
    String? url,
    String? filePath,
    String? filename,
    DownloadStatus? status,
    int? progress,
    int? totalBytes,
    int? downloadedBytes,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadTaskModel(
      id: id ?? this.id,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      filename: filename ?? this.filename,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
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

class AppContextModel {
  final String key;
  final String value;
  final DateTime updatedAt;

  AppContextModel({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  factory AppContextModel.fromJson(Map<String, dynamic> json) {
    return AppContextModel(
      key: json['key'] as String,
      value: json['value'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

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

  AppContextModel copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) {
    return AppContextModel(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AutomationModel {
  final int? id;
  final String name;
  final String triggerType;
  final Map<String, dynamic>? triggerData;
  final String actionType;
  final Map<String, dynamic>? actionData;
  final bool isEnabled;
  final DateTime createdAt;

  AutomationModel({
    this.id,
    required this.name,
    required this.triggerType,
    this.triggerData,
    required this.actionType,
    this.actionData,
    this.isEnabled = true,
    required this.createdAt,
  });

  factory AutomationModel.fromJson(Map<String, dynamic> json) {
    return AutomationModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      triggerType: json['triggerType'] as String,
      triggerData: json['triggerData'] as Map<String, dynamic>?,
      actionType: json['actionType'] as String,
      actionData: json['actionData'] as Map<String, dynamic>?,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'triggerType': triggerType,
      'triggerData': triggerData,
      'actionType': actionType,
      'actionData': actionData,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AutomationModel.create({
    int? id,
    required String name,
    required String triggerType,
    Map<String, dynamic>? triggerData,
    required String actionType,
    Map<String, dynamic>? actionData,
  }) {
    return AutomationModel(
      id: id,
      name: name,
      triggerType: triggerType,
      triggerData: triggerData,
      actionType: actionType,
      actionData: actionData,
      createdAt: DateTime.now(),
    );
  }

  AutomationModel copyWith({
    int? id,
    String? name,
    String? triggerType,
    Map<String, dynamic>? triggerData,
    String? actionType,
    Map<String, dynamic>? actionData,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return AutomationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      triggerType: triggerType ?? this.triggerType,
      triggerData: triggerData ?? this.triggerData,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TermuxScriptModel {
  final int? id;
  final String name;
  final String content;
  final String? description;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  TermuxScriptModel({
    this.id,
    required this.name,
    required this.content,
    this.description,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TermuxScriptModel.fromJson(Map<String, dynamic> json) {
    return TermuxScriptModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      content: json['content'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TermuxScriptModel.create({
    int? id,
    required String name,
    required String content,
    String? description,
    String? category,
  }) {
    final now = DateTime.now();
    return TermuxScriptModel(
      id: id,
      name: name,
      content: content,
      description: description,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
  }

  TermuxScriptModel copyWith({
    int? id,
    String? name,
    String? content,
    String? description,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TermuxScriptModel(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
