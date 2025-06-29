import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_service.dart';
import '../data/settings_model.dart';

// Settings service provider
final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService.instance);

// SMTP settings provider
final smtpSettingsProvider = StateNotifierProvider<SmtpSettingsNotifier, AsyncValue<SmtpSettingsModel>>((ref) {
  return SmtpSettingsNotifier(ref.watch(settingsServiceProvider));
});

// WhatsApp settings provider
final whatsAppSettingsProvider = StateNotifierProvider<WhatsAppSettingsNotifier, AsyncValue<WhatsAppSettingsModel>>((ref) {
  return WhatsAppSettingsNotifier(ref.watch(settingsServiceProvider));
});

// App settings provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettingsModel>>((ref) {
  return AppSettingsNotifier(ref.watch(settingsServiceProvider));
});

// Connection test providers
final smtpConnectionTestProvider = StateNotifierProvider<ConnectionTestNotifier, ConnectionTestState>((ref) {
  return ConnectionTestNotifier(ref.watch(settingsServiceProvider));
});

final whatsAppConnectionTestProvider = StateNotifierProvider<ConnectionTestNotifier, ConnectionTestState>((ref) {
  return ConnectionTestNotifier(ref.watch(settingsServiceProvider));
});

// SMTP Settings Notifier
class SmtpSettingsNotifier extends StateNotifier<AsyncValue<SmtpSettingsModel>> {
  final SettingsService _service;

  SmtpSettingsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.getSmtpSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveSettings(SmtpSettingsModel settings) async {
    try {
      await _service.saveSmtpSettings(settings);
      state = AsyncValue.data(settings.copyWith(isConfigured: true));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void refresh() => _loadSettings();
}

// WhatsApp Settings Notifier
class WhatsAppSettingsNotifier extends StateNotifier<AsyncValue<WhatsAppSettingsModel>> {
  final SettingsService _service;

  WhatsAppSettingsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.getWhatsAppSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveSettings(WhatsAppSettingsModel settings) async {
    try {
      await _service.saveWhatsAppSettings(settings);
      state = AsyncValue.data(settings.copyWith(isConfigured: true));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void refresh() => _loadSettings();
}

// App Settings Notifier
class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettingsModel>> {
  final SettingsService _service;

  AppSettingsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.getAppSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    try {
      await _service.saveAppSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void refresh() => _loadSettings();
}

// Connection Test State
class ConnectionTestState {
  final bool isLoading;
  final bool? isSuccess;
  final String? errorMessage;

  const ConnectionTestState({
    this.isLoading = false,
    this.isSuccess,
    this.errorMessage,
  });

  ConnectionTestState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return ConnectionTestState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Connection Test Notifier
class ConnectionTestNotifier extends StateNotifier<ConnectionTestState> {
  final SettingsService _service;

  ConnectionTestNotifier(this._service) : super(const ConnectionTestState());

  Future<void> testSmtpConnection(SmtpSettingsModel settings) async {
    state = state.copyWith(isLoading: true, isSuccess: null, errorMessage: null);
    
    try {
      final success = await _service.testSmtpConnection(settings);
      state = state.copyWith(
        isLoading: false,
        isSuccess: success,
        errorMessage: success ? null : 'Connection failed. Please check your settings.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> testWhatsAppConnection(WhatsAppSettingsModel settings) async {
    state = state.copyWith(isLoading: true, isSuccess: null, errorMessage: null);
    
    try {
      final success = await _service.testWhatsAppConnection(settings);
      state = state.copyWith(
        isLoading: false,
        isSuccess: success,
        errorMessage: success ? null : 'Connection failed. Please check your settings.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const ConnectionTestState();
  }
}