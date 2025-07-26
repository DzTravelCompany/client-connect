import 'package:client_connect/src/core/validation/form_validator.dart';
import 'package:client_connect/src/core/validation/validators.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/client_model.dart';
import '../../logic/client_providers.dart';

class QuickEditClientDialog extends ConsumerStatefulWidget {
  final ClientModel client;

  const QuickEditClientDialog({
    super.key,
    required this.client,
  });

  @override
  ConsumerState<QuickEditClientDialog> createState() => _QuickEditClientDialogState();
}

class _QuickEditClientDialogState extends ConsumerState<QuickEditClientDialog> {
  late final FormValidator _formValidator;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyController;
  late final TextEditingController _jobTitleController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current client data
    _firstNameController = TextEditingController(text: widget.client.firstName);
    _lastNameController = TextEditingController(text: widget.client.lastName);
    _emailController = TextEditingController(text: widget.client.email ?? '');
    _phoneController = TextEditingController(text: widget.client.phone ?? '');
    _companyController = TextEditingController(text: widget.client.company ?? '');
    _jobTitleController = TextEditingController(text: widget.client.jobTitle ?? '');

    // Initialize form validator
    _formValidator = FormValidator();
    _formValidator.addValidator('firstName', RequiredValidator('First name is required'));
    _formValidator.addValidator('lastName', RequiredValidator('Last name is required'));
    _formValidator.addValidator('email', CompositeValidator([
      EmailValidator(),
    ]));
    _formValidator.addValidator('phone', PhoneValidator());

    // Set initial values
    _formValidator.setValue('firstName', widget.client.firstName);
    _formValidator.setValue('lastName', widget.client.lastName);
    _formValidator.setValue('email', widget.client.email ?? '');
    _formValidator.setValue('phone', widget.client.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _formValidator.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formValidator.validateAll()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final clientFormNotifier = ref.read(clientFormProvider.notifier);
      
      final updatedClient = widget.client.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
      );

      await clientFormNotifier.saveClient(updatedClient);

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to save changes: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage() {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Success'),
        content: const Text('Client updated successfully'),
        severity: InfoBarSeverity.success,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Error'),
        content: Text(message),
        severity: InfoBarSeverity.error,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ContentDialog(
      title: Row(
        children: [
          Icon(
            FluentIcons.edit,
            size: 20,
            color: theme.accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Quick Edit - ${widget.client.fullName}',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Name and Last Name Row
            Row(
              children: [
                Expanded(
                  child: ValidatedTextBox(
                    fieldName: 'firstName',
                    formValidator: _formValidator,
                    controller: _firstNameController,
                    placeholder: 'First Name',
                    enabled: !_isLoading,
                    onChanged: (value) {
                      _formValidator.setValue('firstName', value, validate: true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValidatedTextBox(
                    fieldName: 'lastName',
                    formValidator: _formValidator,
                    controller: _lastNameController,
                    placeholder: 'Last Name',
                    enabled: !_isLoading,
                    onChanged: (value) {
                      _formValidator.setValue('lastName', value, validate: true);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Email
            ValidatedTextBox(
              fieldName: 'email',
              formValidator: _formValidator,
              controller: _emailController,
              placeholder: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              prefix: const Icon(FluentIcons.mail, size: 16),
              onChanged: (value) {
                _formValidator.setValue('email', value, validate: true);
              },
            ),
            const SizedBox(height: 16),
            
            // Phone
            ValidatedTextBox(
              fieldName: 'phone',
              formValidator: _formValidator,
              controller: _phoneController,
              placeholder: 'Phone Number',
              keyboardType: TextInputType.phone,
              enabled: !_isLoading,
              prefix: const Icon(FluentIcons.phone, size: 16),
              onChanged: (value) {
                _formValidator.setValue('phone', value, validate: true);
              },
            ),
            const SizedBox(height: 16),
            
            // Company and Job Title Row
            Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _companyController,
                    placeholder: 'Company',
                    enabled: !_isLoading,
                    prefix: const Icon(FluentIcons.build, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextBox(
                    controller: _jobTitleController,
                    placeholder: 'Job Title',
                    enabled: !_isLoading,
                    prefix: const Icon(FluentIcons.add_work, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveChanges,
          child: _isLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    const Text('Saving...'),
                  ],
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}