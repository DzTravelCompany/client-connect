import 'package:client_connect/src/features/clients/data/client_model.dart';
import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/template_dao.dart';
import '../data/template_model.dart';


// Template DAO provider
final templateDaoProvider = Provider<TemplateDao>((ref) => TemplateDao());

// All templates provider
final templatesProvider = FutureProvider<List<TemplateModel>>((ref) async {
  final dao = ref.read(templateDaoProvider);
  return await dao.getAllTemplates();
});

final templateByIdProvider = FutureProvider.family<TemplateModel?, int>((ref, id) {
  final dao = ref.watch(templateDaoProvider);
  return dao.getTemplateById(id);
});

// Templates by type provider
final templatesByTypeProvider = FutureProvider.family<List<TemplateModel>, TemplateType>((ref, type) async {
  final dao = ref.read(templateDaoProvider);
  return await dao.watchTemplatesByType(type);
});

// Email templates provider
final emailTemplatesProvider = FutureProvider<List<TemplateModel>>((ref) async {
  final dao = ref.read(templateDaoProvider);
  return await dao.watchTemplatesByType(TemplateType.email);
});

// WhatsApp templates provider
final whatsappTemplatesProvider = FutureProvider<List<TemplateModel>>((ref) async {
  final dao = ref.read(templateDaoProvider);
  return await dao.watchTemplatesByType(TemplateType.whatsapp);
});

// Single template provider
final templateProvider = FutureProvider.family<TemplateModel?, int>((ref, id) async {
  final dao = ref.read(templateDaoProvider);
  return await dao.getTemplateById(id);
});

// Recent templates provider
final recentTemplatesProvider = FutureProvider<List<TemplateModel>>((ref) async {
  final dao = ref.read(templateDaoProvider);
  return await dao.getRecentTemplates();
});

// Template count provider
final templateCountProvider = FutureProvider<int>((ref) async {
  final dao = ref.read(templateDaoProvider);
  return await dao.getTemplateCount();
});

// Template count by type provider
final templateCountByTypeProvider = FutureProvider.family<int, TemplateType>((ref, type) async {
  final dao = ref.read(templateDaoProvider);
  return await dao.getTemplateCountByType(type);
});

// Search templates provider
final searchTemplatesProvider = FutureProvider.family<List<TemplateModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final dao = ref.read(templateDaoProvider);
  return await dao.searchTemplates(query);
});

// Templates with statistics provider
final templatesWithStatsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dao = ref.read(templateDaoProvider);
  return await dao.getTemplatesWithStats();
});

// Template operations notifier
class TemplateOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final TemplateDao _dao;
  final Ref _ref;

  TemplateOperationsNotifier(this._dao, this._ref) : super(const AsyncValue.data(null));

  // Create template
  Future<TemplateModel> createTemplate(TemplateModel template) async {
    state = const AsyncValue.loading();
    try {
      final createdTemplate = await _dao.createTemplate(template);
      state = const AsyncValue.data(null);
      
      // Refresh all template providers
      _refreshProviders();
      
      return createdTemplate;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // Update template
  Future<TemplateModel> updateTemplate(TemplateModel template) async {
    state = const AsyncValue.loading();
    try {
      final updatedTemplate = await _dao.updateTemplate(template);
      state = const AsyncValue.data(null);
      
      // Refresh providers
      _refreshProviders();
      _ref.invalidate(templateProvider(template.id));
      
      return updatedTemplate;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // Delete template
  Future<bool> deleteTemplate(int id) async {
    state = const AsyncValue.loading();
    try {
      final result = await _dao.deleteTemplate(id);
      state = const AsyncValue.data(null);
      
      // Refresh providers
      _refreshProviders();
      _ref.invalidate(templateProvider(id));
      
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // Duplicate template
  Future<TemplateModel> duplicateTemplate(int id) async {
    state = const AsyncValue.loading();
    try {
      final duplicatedTemplate = await _dao.duplicateTemplate(id);
      state = const AsyncValue.data(null);
      
      // Refresh providers
      _refreshProviders();
      
      return duplicatedTemplate;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // Delete multiple templates
  Future<void> deleteMultipleTemplates(List<int> ids) async {
    state = const AsyncValue.loading();
    try {
      await _dao.deleteMultipleTemplates(ids);
      state = const AsyncValue.data(null);
      
      // Refresh providers
      _refreshProviders();
      for (final id in ids) {
        _ref.invalidate(templateProvider(id));
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  // Check if template name exists
  Future<bool> templateNameExists(String name, {int? excludeId}) async {
    return await _dao.templateNameExists(name, excludeId: excludeId);
  }

  // Refresh all template-related providers
  void _refreshProviders() {
    _ref.invalidate(templatesProvider);
    _ref.invalidate(emailTemplatesProvider);
    _ref.invalidate(whatsappTemplatesProvider);
    _ref.invalidate(recentTemplatesProvider);
    _ref.invalidate(templateCountProvider);
    _ref.invalidate(templatesWithStatsProvider);
  }
}

// Template operations provider
final templateOperationsProvider = StateNotifierProvider<TemplateOperationsNotifier, AsyncValue<void>>((ref) {
  final dao = ref.read(templateDaoProvider);
  return TemplateOperationsNotifier(dao, ref);
});

// Template form state provider (for create/edit forms)
class TemplateFormState {
  final String name;
  final String subject;
  final TemplateType templateType;
  final List<TemplateBlock> blocks;
  final bool isValid;
  final String? error;

  const TemplateFormState({
    this.name = '',
    this.subject = '',
    this.templateType = TemplateType.email,
    this.blocks = const [],
    this.isValid = false,
    this.error,
  });

  TemplateFormState copyWith({
    String? name,
    String? subject,
    TemplateType? templateType,
    List<TemplateBlock>? blocks,
    bool? isValid,
    String? error,
  }) {
    return TemplateFormState(
      name: name ?? this.name,
      subject: subject ?? this.subject,
      templateType: templateType ?? this.templateType,
      blocks: blocks ?? this.blocks,
      isValid: isValid ?? this.isValid,
      error: error ?? this.error,
    );
  }

  bool get hasBlocks => blocks.isNotEmpty;
  int get blockCount => blocks.length;
}

class TemplateFormNotifier extends StateNotifier<TemplateFormState> {
  TemplateFormNotifier() : super(const TemplateFormState());

  void updateName(String name) {
    state = state.copyWith(name: name, isValid: _validateForm(name, state.subject));
  }

  void updateSubject(String subject) {
    state = state.copyWith(subject: subject, isValid: _validateForm(state.name, subject));
  }

  void updateTemplateType(TemplateType type) {
    state = state.copyWith(templateType: type);
  }

  void updateBlocks(List<TemplateBlock> blocks) {
    state = state.copyWith(blocks: blocks);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const TemplateFormState();
  }

  void loadTemplate(TemplateModel template) {
    state = TemplateFormState(
      name: template.name,
      subject: template.subject ?? '',
      templateType: template.templateType,
      blocks: template.blocks,
      isValid: true,
    );
  }

  bool _validateForm(String name, String subject) {
    return name.trim().isNotEmpty;
  }

  TemplateModel toTemplateModel({int? id}) {
    return TemplateModel(
      id: id ?? 0,
      name: state.name,
      subject: state.subject.isEmpty ? null : state.subject,
      body: '', // Will be generated from blocks
      templateType: state.templateType,
      blocks: state.blocks,
      isEmail: state.templateType == TemplateType.email,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

final templateFormProvider = StateNotifierProvider<TemplateFormNotifier, TemplateFormState>((ref) {
  return TemplateFormNotifier();
});


// Template preview service
class TemplatePreviewService {
  static String generatePreview(TemplateModel template, ClientModel sampleClient) {
    String preview = template.body;
    
    // Replace placeholders with sample client data
    final replacements = {
      '{{first_name}}': sampleClient.firstName,
      '{{last_name}}': sampleClient.lastName,
      '{{full_name}}': sampleClient.fullName,
      '{{email}}': sampleClient.email ?? '[No Email]',
      '{{phone}}': sampleClient.phone ?? '[No Phone]',
      '{{company}}': sampleClient.company ?? '[No Company]',
      '{{job_title}}': sampleClient.jobTitle ?? '[No Job Title]',
    };
    
    replacements.forEach((placeholder, value) {
      preview = preview.replaceAll(placeholder, value);
    });
    
    return preview;
  }

  static List<String> getAvailablePlaceholders() {
    return [
      '{{first_name}}',
      '{{last_name}}',
      '{{full_name}}',
      '{{email}}',
      '{{phone}}',
      '{{company}}',
      '{{job_title}}',
    ];
  }
}