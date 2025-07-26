import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/client_model.dart';
import '../logic/client_providers.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final int? clientId;
  
  const ClientFormScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  Timer? _autosaveTimer;
  bool _isInitialized = false;
  bool _hasUnsavedChanges = false;
  ClientModel? _originalClient;
  
  // Track the current client ID - this is key to fixing the autosave issue
  int? _currentClientId;
  bool _isCreatingNewClient = false;

  @override
  void initState() {
    super.initState();
    _currentClientId = widget.clientId;
    _setupFormListeners();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setupFormListeners() {
    final controllers = [
      _firstNameController,
      _lastNameController,
      _emailController,
      _phoneController,
      _companyController,
      _jobTitleController,
      _addressController,
      _notesController,
    ];

    for (final controller in controllers) {
      controller.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (!_isInitialized) return;
    
    setState(() {
      _hasUnsavedChanges = true;
    });
    
    // Cancel previous timer and start new one
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _hasUnsavedChanges && _shouldPerformAutosave()) {
        _performAutosave();
      }
    });
  }

  // New method to determine if autosave should be performed
  bool _shouldPerformAutosave() {
    // Don't autosave if we're already in the process of creating a new client
    if (_isCreatingNewClient) return false;
    
    // Don't autosave if required fields are empty for new clients
    if (_currentClientId == null) {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      if (firstName.isEmpty || lastName.isEmpty) {
        return false;
      }
    }
    
    return true;
  }

  Future<void> _performAutosave() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Prevent multiple simultaneous autosave operations
    if (_isCreatingNewClient) return;
    
    final client = _buildClientFromForm();
    
    // Set flag to prevent duplicate creation attempts
    if (_currentClientId == null) {
      setState(() {
        _isCreatingNewClient = true;
      });
    }
    
    try {
      final savedClientId = await ref.read(clientFormProvider.notifier).saveClient(client);
      
      if (savedClientId != null && mounted) {
        // Update the current client ID if this was a new client creation
        if (_currentClientId == null) {
          setState(() {
            _currentClientId = savedClientId;
            _hasUnsavedChanges = false;
            _isCreatingNewClient = false;
          });
          
          // Update the original client reference
          _originalClient = client.copyWith(id: savedClientId);
        } else {
          setState(() {
            _hasUnsavedChanges = false;
          });
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() {
          _isCreatingNewClient = false;
        });
      }
    }
  }

  ClientModel _buildClientFromForm() {
    return ClientModel(
      id: _currentClientId ?? 0, // Use the tracked client ID
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
      jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: _originalClient?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _populateForm(ClientModel client) {
    _firstNameController.text = client.firstName;
    _lastNameController.text = client.lastName;
    _emailController.text = client.email ?? '';
    _phoneController.text = client.phone ?? '';
    _companyController.text = client.company ?? '';
    _jobTitleController.text = client.jobTitle ?? '';
    _addressController.text = client.address ?? '';
    _notesController.text = client.notes ?? '';
    _originalClient = client;
    _currentClientId = client.id;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(clientFormProvider);
    final isEditing = _currentClientId != null; // Use tracked client ID

    // Load existing client data if editing
    if (widget.clientId != null && !_isInitialized) {
      ref.watch(clientByIdProvider(widget.clientId!)).whenData((client) {
        if (client != null && !_isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateForm(client);
          });
        }
      });
    } else if (widget.clientId == null && !_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isInitialized = true;
        });
      });
    }

    return ScaffoldPage(
      header: PageHeader(
        title: Text(isEditing ? 'Edit Client' : 'Add Client'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('Save'),
              onPressed: (formState.isLoading || _isCreatingNewClient) ? null : _saveClient,
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status indicator - Updated to show creation state
            if (formState.isLoading || _hasUnsavedChanges || formState.isSaved || _isCreatingNewClient)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _getStatusColor(formState),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    if (formState.isLoading || _isCreatingNewClient) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: ProgressRing(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCreatingNewClient ? 'Creating client...' : 'Saving...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ] else if (_hasUnsavedChanges) ...[
                      const Icon(FluentIcons.edit, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('Unsaved changes', style: TextStyle(color: Colors.white)),
                    ] else if (formState.isSaved) ...[
                      const Icon(FluentIcons.check_mark, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _currentClientId != null && _originalClient == null ? 'Client created' : 'Saved',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),

            // Error message
            if (formState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(FluentIcons.error, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Save failed: ${formState.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _firstNameController,
                              label: 'First Name *',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'First name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _lastNameController,
                              label: 'Last Name *',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Last name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _emailController,
                              label: 'Email',
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _phoneController,
                              label: 'Phone',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Professional Information Section
                      _buildSectionHeader('Professional Information'),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _companyController,
                              label: 'Company',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _jobTitleController,
                              label: 'Job Title',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Additional Information Section
                      _buildSectionHeader('Additional Information'),
                      const SizedBox(height: 12),
                      
                      _buildTextFormField(
                        controller: _addressController,
                        label: 'Address',
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildTextFormField(
                        controller: _notesController,
                        label: 'Notes',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: FluentTheme.of(context).typography.subtitle,
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FluentTheme.of(context).typography.body),
        const SizedBox(height: 4),
        TextFormBox(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          expands: false,
        ),
      ],
    );
  }

  Color _getStatusColor(ClientFormState formState) {
    if (formState.isLoading || _isCreatingNewClient) return Colors.blue;
    if (_hasUnsavedChanges) return Colors.orange;
    if (formState.isSaved) return Colors.green;
    return Colors.grey;
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final client = _buildClientFromForm();
    final savedClientId = await ref.read(clientFormProvider.notifier).saveClient(client);

    if (savedClientId != null && mounted) {
      // Update the current client ID if this was a new client creation
      if (_currentClientId == null) {
        setState(() {
          _currentClientId = savedClientId;
        });
      }
      
      final formState = ref.read(clientFormProvider);
      if (formState.error == null) {
        // Navigate back to client list on successful save
        context.go('/clients');
      }
    }
  }
}