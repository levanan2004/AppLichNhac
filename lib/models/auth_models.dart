class AccessCode {
  final String? id;
  final String code;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;
  final String? usedBy;
  final DateTime? usedAt;

  AccessCode({
    this.id,
    required this.code,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    this.usedBy,
    this.usedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'is_active': isActive,
      'used_by': usedBy,
      'used_at': usedAt?.toIso8601String(),
    };
  }

  factory AccessCode.fromMap(Map<String, dynamic> map, String id) {
    return AccessCode(
      id: id,
      code: map['code'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      createdBy: map['created_by'] ?? '',
      isActive: map['is_active'] ?? true,
      usedBy: map['used_by'],
      usedAt: map['used_at'] != null ? DateTime.parse(map['used_at']) : null,
    );
  }

  AccessCode copyWith({
    String? id,
    String? code,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
    String? usedBy,
    DateTime? usedAt,
  }) {
    return AccessCode(
      id: id ?? this.id,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      usedBy: usedBy ?? this.usedBy,
      usedAt: usedAt ?? this.usedAt,
    );
  }
}

class AdminCredentials {
  final String username;
  final String password; // Hashed
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminCredentials({
    required this.username,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AdminCredentials.fromMap(Map<String, dynamic> map) {
    // Helper function để parse DateTime từ nhiều format
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString() == 'Timestamp') {
        // Firebase Timestamp
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return AdminCredentials(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      createdAt: parseDateTime(map['created_at']),
      updatedAt: parseDateTime(map['updated_at']),
    );
  }
}

enum UserRole {
  admin,
  employee,
}

class AuthState {
  final UserRole role;
  final String userId;
  final String? username;
  final DateTime loginTime;

  AuthState({
    required this.role,
    required this.userId,
    this.username,
    required this.loginTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'user_id': userId,
      'username': username,
      'login_time': loginTime.toIso8601String(),
    };
  }

  factory AuthState.fromMap(Map<String, dynamic> map) {
    return AuthState(
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      userId: map['user_id'] ?? '',
      username: map['username'],
      loginTime: DateTime.parse(map['login_time']),
    );
  }
}
