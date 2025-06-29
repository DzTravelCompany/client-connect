class SmtpSettingsModel {
  final String host;
  final int port;
  final String username;
  final String password;
  final String fromName;
  final bool ssl;
  final bool isConfigured;

  const SmtpSettingsModel({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.fromName,
    required this.ssl,
    this.isConfigured = false,
  });

  SmtpSettingsModel copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    String? fromName,
    bool? ssl,
    bool? isConfigured,
  }) {
    return SmtpSettingsModel(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      fromName: fromName ?? this.fromName,
      ssl: ssl ?? this.ssl,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  Map<String, String> toSecureStorage() {
    return {
      'smtp_host': host,
      'smtp_port': port.toString(),
      'smtp_username': username,
      'smtp_password': password,
      'smtp_from_name': fromName,
      'smtp_ssl': ssl.toString(),
    };
  }

  static SmtpSettingsModel fromSecureStorage(Map<String, String?> data) {
    return SmtpSettingsModel(
      host: data['smtp_host'] ?? '',
      port: int.tryParse(data['smtp_port'] ?? '587') ?? 587,
      username: data['smtp_username'] ?? '',
      password: data['smtp_password'] ?? '',
      fromName: data['smtp_from_name'] ?? 'Client Connect',
      ssl: (data['smtp_ssl'] ?? 'true') == 'true',
      isConfigured: (data['smtp_host']?.isNotEmpty ?? false) && 
                   (data['smtp_username']?.isNotEmpty ?? false),
    );
  }
}

class WhatsAppSettingsModel {
  final String apiUrl;
  final String apiKey;
  final String phoneNumberId;
  final bool isConfigured;

  const WhatsAppSettingsModel({
    required this.apiUrl,
    required this.apiKey,
    required this.phoneNumberId,
    this.isConfigured = false,
  });

  WhatsAppSettingsModel copyWith({
    String? apiUrl,
    String? apiKey,
    String? phoneNumberId,
    bool? isConfigured,
  }) {
    return WhatsAppSettingsModel(
      apiUrl: apiUrl ?? this.apiUrl,
      apiKey: apiKey ?? this.apiKey,
      phoneNumberId: phoneNumberId ?? this.phoneNumberId,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  Map<String, String> toSecureStorage() {
    return {
      'whatsapp_api_url': apiUrl,
      'whatsapp_api_key': apiKey,
      'whatsapp_phone_number_id': phoneNumberId,
    };
  }

  static WhatsAppSettingsModel fromSecureStorage(Map<String, String?> data) {
    return WhatsAppSettingsModel(
      apiUrl: data['whatsapp_api_url'] ?? '',
      apiKey: data['whatsapp_api_key'] ?? '',
      phoneNumberId: data['whatsapp_phone_number_id'] ?? '',
      isConfigured: (data['whatsapp_api_url']?.isNotEmpty ?? false) && 
                   (data['whatsapp_api_key']?.isNotEmpty ?? false),
    );
  }
}

class AppSettingsModel {
  final String theme; // 'light', 'dark', 'system'
  final bool enableNotifications;
  final bool autoSaveEnabled;
  final int autoSaveInterval; // in seconds
  final String language;

  const AppSettingsModel({
    this.theme = 'system',
    this.enableNotifications = true,
    this.autoSaveEnabled = true,
    this.autoSaveInterval = 2,
    this.language = 'en',
  });

  AppSettingsModel copyWith({
    String? theme,
    bool? enableNotifications,
    bool? autoSaveEnabled,
    int? autoSaveInterval,
    String? language,
  }) {
    return AppSettingsModel(
      theme: theme ?? this.theme,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      language: language ?? this.language,
    );
  }
}