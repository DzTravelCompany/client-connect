import 'package:client_connect/src/features/settings/data/settings_service.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/settings_providers.dart';
import '../data/settings_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Settings'),
      ),
      content: Row(
        children: [
          // Settings navigation
          SizedBox(
            width: 200,
            child: NavigationView(
              pane: NavigationPane(
                selected: _selectedIndex,
                onChanged: (index) => setState(() => _selectedIndex = index),
                displayMode: PaneDisplayMode.compact,
                items: [
                  PaneItem(
                    icon: const Icon(FluentIcons.mail),
                    title: const Text('Email (SMTP)'),
                    body: const SizedBox.shrink(),
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.chat),
                    title: const Text('WhatsApp'),
                    body: const SizedBox.shrink(),
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.settings),
                    title: const Text('Application'),
                    body: const SizedBox.shrink(),
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.info),
                    title: const Text('About'),
                    body: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          
          // Settings content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey[60]),
                ),
              ),
              child: _buildSettingsContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    switch (_selectedIndex) {
      case 0:
        return const SmtpSettingsPanel();
      case 1:
        return const WhatsAppSettingsPanel();
      case 2:
        return const AppSettingsPanel();
      case 3:
        return const AboutPanel();
      default:
        return const SizedBox.shrink();
    }
  }
}

// SMTP Settings Panel
class SmtpSettingsPanel extends ConsumerStatefulWidget {
  const SmtpSettingsPanel({super.key});

  @override
  ConsumerState<SmtpSettingsPanel> createState() => _SmtpSettingsPanelState();
}

class _SmtpSettingsPanelState extends ConsumerState<SmtpSettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fromNameController = TextEditingController();
  bool _sslEnabled = true;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _fromNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final smtpSettingsAsync = ref.watch(smtpSettingsProvider);
    final connectionTest = ref.watch(smtpConnectionTestProvider);

    return smtpSettingsAsync.when(
      data: (settings) {
        // Populate form fields when settings load
        if (_hostController.text.isEmpty) {
          _hostController.text = settings.host;
          _portController.text = settings.port.toString();
          _usernameController.text = settings.username;
          _passwordController.text = settings.password;
          _fromNameController.text = settings.fromName;
          _sslEnabled = settings.ssl;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(FluentIcons.mail, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Email (SMTP) Configuration',
                      style: FluentTheme.of(context).typography.title,
                    ),
                    const Spacer(),
                    if (settings.isConfigured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.completed, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'CONFIGURED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Configure your SMTP server settings to send emails through Client Connect.',
                  style: FluentTheme.of(context).typography.body,
                ),
                
                const SizedBox(height: 24),

                // Connection test result
                if (connectionTest.isSuccess != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: connectionTest.isSuccess! 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: connectionTest.isSuccess! 
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          connectionTest.isSuccess! 
                              ? FluentIcons.completed 
                              : FluentIcons.error,
                          size: 16,
                          color: connectionTest.isSuccess! ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            connectionTest.isSuccess!
                                ? 'Connection successful! SMTP settings are working correctly.'
                                : 'Connection failed: ${connectionTest.errorMessage}',
                            style: TextStyle(
                              color: connectionTest.isSuccess! ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form fields
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextFormField(
                        controller: _hostController,
                        label: 'SMTP Host *',
                        placeholder: 'smtp.gmail.com',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'SMTP host is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildTextFormField(
                        controller: _portController,
                        label: 'Port *',
                        placeholder: '587',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Port is required';
                          }
                          final port = int.tryParse(value);
                          if (port == null || port < 1 || port > 65535) {
                            return 'Invalid port number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _usernameController,
                  label: 'Username/Email *',
                  placeholder: 'your-email@gmail.com',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildPasswordField(),
                
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _fromNameController,
                  label: 'From Name',
                  placeholder: 'Client Connect',
                ),
                
                const SizedBox(height: 16),
                
                // SSL/TLS Toggle
                Row(
                  children: [
                    Checkbox(
                      checked: _sslEnabled,
                      onChanged: (value) => setState(() => _sslEnabled = value ?? true),
                    ),
                    const SizedBox(width: 8),
                    const Text('Enable SSL/TLS (Recommended)'),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    FilledButton(
                      onPressed: connectionTest.isLoading ? null : _testConnection,
                      child: connectionTest.isLoading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: ProgressRing(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Testing...'),
                              ],
                            )
                          : const Text('Test Connection'),
                    ),
                    const SizedBox(width: 12),
                    Button(
                      onPressed: _saveSettings,
                      child: const Text('Save Settings'),
                    ),
                    const SizedBox(width: 12),
                    Button(
                      onPressed: _clearSettings,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Help section
                _buildHelpSection(),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => Center(
        child: Text('Error loading SMTP settings: $error'),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? placeholder,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FluentTheme.of(context).typography.body),
        const SizedBox(height: 4),
        TextFormBox(
          controller: controller,
          placeholder: placeholder,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password *', style: FluentTheme.of(context).typography.body),
        const SizedBox(height: 4),
        TextFormBox(
          controller: _passwordController,
          placeholder: 'Your email password or app password',
          obscureText: !_passwordVisible,
          suffix: IconButton(
            icon: Icon(_passwordVisible ? FluentIcons.hide : FluentIcons.view),
            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Password is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.info, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Common SMTP Settings',
                style: FluentTheme.of(context).typography.subtitle?.copyWith(color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Gmail: smtp.gmail.com, Port 587, SSL enabled'),
          const Text('Outlook: smtp-mail.outlook.com, Port 587, SSL enabled'),
          const Text('Yahoo: smtp.mail.yahoo.com, Port 587, SSL enabled'),
          const SizedBox(height: 8),
          const Text(
            'Note: For Gmail, you may need to use an App Password instead of your regular password.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _testConnection() {
    if (!_formKey.currentState!.validate()) return;

    final settings = SmtpSettingsModel(
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      fromName: _fromNameController.text.trim().isEmpty 
          ? 'Client Connect' 
          : _fromNameController.text.trim(),
      ssl: _sslEnabled,
    );

    ref.read(smtpConnectionTestProvider.notifier).testSmtpConnection(settings);
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = SmtpSettingsModel(
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      fromName: _fromNameController.text.trim().isEmpty 
          ? 'Client Connect' 
          : _fromNameController.text.trim(),
      ssl: _sslEnabled,
    );

    await ref.read(smtpSettingsProvider.notifier).saveSettings(settings);
    
    if (mounted) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Settings Saved'),
          content: const Text('SMTP settings have been saved successfully.'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
    }
  }

  void _clearSettings() {
    setState(() {
      _hostController.clear();
      _portController.text = '587';
      _usernameController.clear();
      _passwordController.clear();
      _fromNameController.text = 'Client Connect';
      _sslEnabled = true;
    });
    
    ref.read(smtpConnectionTestProvider.notifier).reset();
  }
}

// WhatsApp Settings Panel
class WhatsAppSettingsPanel extends ConsumerStatefulWidget {
  const WhatsAppSettingsPanel({super.key});

  @override
  ConsumerState<WhatsAppSettingsPanel> createState() => _WhatsAppSettingsPanelState();
}

class _WhatsAppSettingsPanelState extends ConsumerState<WhatsAppSettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  final _apiUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _phoneNumberIdController = TextEditingController();
  bool _apiKeyVisible = false;

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _phoneNumberIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final whatsAppSettingsAsync = ref.watch(whatsAppSettingsProvider);
    final connectionTest = ref.watch(whatsAppConnectionTestProvider);

    return whatsAppSettingsAsync.when(
      data: (settings) {
        // Populate form fields when settings load
        if (_apiUrlController.text.isEmpty) {
          _apiUrlController.text = settings.apiUrl;
          _apiKeyController.text = settings.apiKey;
          _phoneNumberIdController.text = settings.phoneNumberId;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(FluentIcons.chat, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'WhatsApp Business API Configuration',
                      style: FluentTheme.of(context).typography.title,
                    ),
                    const Spacer(),
                    if (settings.isConfigured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.completed, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'CONFIGURED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Configure your WhatsApp Business API to send WhatsApp messages through Client Connect.',
                  style: FluentTheme.of(context).typography.body,
                ),
                
                const SizedBox(height: 24),

                // Connection test result
                if (connectionTest.isSuccess != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: connectionTest.isSuccess! 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: connectionTest.isSuccess! 
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          connectionTest.isSuccess! 
                              ? FluentIcons.completed 
                              : FluentIcons.error,
                          size: 16,
                          color: connectionTest.isSuccess! ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            connectionTest.isSuccess!
                                ? 'Connection successful! WhatsApp API settings are working correctly.'
                                : 'Connection failed: ${connectionTest.errorMessage}',
                            style: TextStyle(
                              color: connectionTest.isSuccess! ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form fields
                _buildTextFormField(
                  controller: _apiUrlController,
                  label: 'API Base URL *',
                  placeholder: 'https://graph.facebook.com',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'API URL is required';
                    }
                    if (Uri.tryParse(value)?.hasAbsolutePath ?? false) {
                      return 'Please enter a valid URL';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API Access Token *', style: FluentTheme.of(context).typography.body),
                    const SizedBox(height: 4),
                    TextFormBox(
                      controller: _apiKeyController,
                      placeholder: 'Your WhatsApp Business API access token',
                      obscureText: !_apiKeyVisible,
                      suffix: IconButton(
                        icon: Icon(_apiKeyVisible ? FluentIcons.hide : FluentIcons.view),
                        onPressed: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'API access token is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  controller: _phoneNumberIdController,
                  label: 'Phone Number ID *',
                  placeholder: 'Your WhatsApp Business phone number ID',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone Number ID is required';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    FilledButton(
                      onPressed: connectionTest.isLoading ? null : _testConnection,
                      child: connectionTest.isLoading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: ProgressRing(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Testing...'),
                              ],
                            )
                          : const Text('Test Connection'),
                    ),
                    const SizedBox(width: 12),
                    Button(
                      onPressed: _saveSettings,
                      child: const Text('Save Settings'),
                    ),
                    const SizedBox(width: 12),
                    Button(
                      onPressed: _clearSettings,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Help section
                _buildHelpSection(),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => Center(
        child: Text('Error loading WhatsApp settings: $error'),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? placeholder,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FluentTheme.of(context).typography.body),
        const SizedBox(height: 4),
        TextFormBox(
          controller: controller,
          placeholder: placeholder,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.info, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'WhatsApp Business API Setup',
                style: FluentTheme.of(context).typography.subtitle?.copyWith(color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('1. Create a WhatsApp Business account'),
          const Text('2. Set up WhatsApp Business API through Meta for Developers'),
          const Text('3. Get your access token and phone number ID'),
          const Text('4. Use the Graph API base URL: https://graph.facebook.com'),
          const SizedBox(height: 8),
          const Text(
            'Note: WhatsApp Business API requires approval from Meta and may have associated costs.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _testConnection() {
    if (!_formKey.currentState!.validate()) return;

    final settings = WhatsAppSettingsModel(
      apiUrl: _apiUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      phoneNumberId: _phoneNumberIdController.text.trim(),
    );

    ref.read(whatsAppConnectionTestProvider.notifier).testWhatsAppConnection(settings);
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = WhatsAppSettingsModel(
      apiUrl: _apiUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      phoneNumberId: _phoneNumberIdController.text.trim(),
    );

    await ref.read(whatsAppSettingsProvider.notifier).saveSettings(settings);
    
    if (mounted) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Settings Saved'),
          content: const Text('WhatsApp settings have been saved successfully.'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
    }
  }

  void _clearSettings() {
    setState(() {
      _apiUrlController.text = 'https://graph.facebook.com';
      _apiKeyController.clear();
      _phoneNumberIdController.clear();
    });
    
    ref.read(whatsAppConnectionTestProvider.notifier).reset();
  }
}

// App Settings Panel
class AppSettingsPanel extends ConsumerWidget {
  const AppSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettingsAsync = ref.watch(appSettingsProvider);

    return appSettingsAsync.when(
      data: (settings) => SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(FluentIcons.settings, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Application Settings',
                  style: FluentTheme.of(context).typography.title,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Customize your Client Connect experience.',
              style: FluentTheme.of(context).typography.body,
            ),
            
            const SizedBox(height: 24),

            // Theme setting
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(FluentIcons.color_solid, size: 16),
                        const SizedBox(width: 8),
                        const Text('Theme:'),
                        const SizedBox(width: 16),
                        ComboBox<String>(
                          value: settings.theme,
                          items: const [
                            ComboBoxItem(value: 'light', child: Text('Light')),
                            ComboBoxItem(value: 'dark', child: Text('Dark')),
                            ComboBoxItem(value: 'system', child: Text('System Default')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(appSettingsProvider.notifier).saveSettings(
                                settings.copyWith(theme: value),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notifications setting
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          checked: settings.enableNotifications,
                          onChanged: (value) {
                            ref.read(appSettingsProvider.notifier).saveSettings(
                              settings.copyWith(enableNotifications: value ?? true),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('Enable notifications for campaign completion'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Auto-save settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Save',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          checked: settings.autoSaveEnabled,
                          onChanged: (value) {
                            ref.read(appSettingsProvider.notifier).saveSettings(
                              settings.copyWith(autoSaveEnabled: value ?? true),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: const Text('Enable auto-save for forms')
                        ),
                      ],
                    ),
                    if (settings.autoSaveEnabled) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Auto-save interval:'),
                          const SizedBox(width: 16),
                          Flexible(
                            child: NumberBox<int>(
                              value: settings.autoSaveInterval,
                              min: 1,
                              max: 10,
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(appSettingsProvider.notifier).saveSettings(
                                    settings.copyWith(autoSaveInterval: value),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('seconds'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reset settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Settings',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    const Text('This will reset all application settings to their defaults.'),
                    const SizedBox(height: 12),
                    Button(
                      onPressed: () => _showResetDialog(context, ref),
                      child: const Text('Reset All Settings'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => Center(
        child: Text('Error loading app settings: $error'),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings? This will clear all SMTP, WhatsApp, and application settings. This action cannot be undone.',
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Reset'),
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Clear all settings
              await SettingsService.instance.clearAllSettings();
              
              // Refresh all providers
              ref.invalidate(smtpSettingsProvider);
              ref.invalidate(whatsAppSettingsProvider);
              ref.invalidate(appSettingsProvider);
              
              if (context.mounted) {
                displayInfoBar(
                  context,
                  builder: (context, close) => InfoBar(
                    title: const Text('Settings Reset'),
                    content: const Text('All settings have been reset to defaults.'),
                    severity: InfoBarSeverity.warning,
                    onClose: close,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// About Panel
class AboutPanel extends StatelessWidget {
  const AboutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(FluentIcons.info, size: 24),
              const SizedBox(width: 12),
              Text(
                'About Client Connect',
                style: FluentTheme.of(context).typography.title,
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // App info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: FluentTheme.of(context).accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          FluentIcons.people,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client Connect CRM',
                            style: FluentTheme.of(context).typography.subtitle,
                          ),
                          const Text('Version 1.0.0'),
                          const Text('Professional Desktop CRM'),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Client Connect is a professional desktop CRM application designed to empower users with robust client management and targeted communication capabilities. Built with Flutter for Windows.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  const _FeatureItem(
                    icon: FluentIcons.people,
                    title: 'Client Management',
                    description: 'Complete CRUD operations with search and filtering',
                  ),
                  const _FeatureItem(
                    icon: FluentIcons.mail,
                    title: 'Template System',
                    description: 'Create and manage email and WhatsApp templates',
                  ),
                  const _FeatureItem(
                    icon: FluentIcons.send,
                    title: 'Campaign Engine',
                    description: 'Background processing with real-time progress tracking',
                  ),
                  const _FeatureItem(
                    icon: FluentIcons.refresh,
                    title: 'Crash Recovery',
                    description: 'Automatic campaign recovery after interruptions',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // System info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Information',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  const Text('Platform: Windows Desktop'),
                  const Text('Framework: Flutter 3.x'),
                  const Text('Database: SQLite with Drift ORM'),
                  const Text('State Management: Riverpod'),
                  const Text('UI Framework: Fluent UI'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Support
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support & Documentation',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  const Text('For help and documentation, please refer to:'),
                  const SizedBox(height: 8),
                  const Text('• User Manual (included with installation)'),
                  const Text('• Online Documentation'),
                  const Text('• Support Portal'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[100]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
