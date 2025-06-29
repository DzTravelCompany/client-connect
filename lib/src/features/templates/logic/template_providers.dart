import 'package:client_connect/src/core/models/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/template_dao.dart';
import '../data/template_model.dart';
import '../../clients/data/client_model.dart';

// Template DAO provider
final templateDaoProvider = Provider<TemplateDao>((ref) => TemplateDao());

// All templates stream provider
final allTemplatesProvider = StreamProvider<List<TemplateModel>>((ref) {
  final dao = ref.watch(templateDaoProvider);
  return dao.watchAllTemplates();
});

// Templates by type provider
final templatesByTypeProvider = StreamProvider.family<List<TemplateModel>, String>((ref, type) {
  final dao = ref.watch(templateDaoProvider);
  return dao.watchTemplatesByType(type);
});

// Template by ID provider
final templateByIdProvider = FutureProvider.family<TemplateModel?, int>((ref, id) {
  final dao = ref.watch(templateDaoProvider);
  return dao.getTemplateById(id);
});

// Template form state provider
final templateFormProvider = StateNotifierProvider<TemplateFormNotifier, TemplateFormState>((ref) {
  return TemplateFormNotifier(ref.watch(templateDaoProvider));
});

// Template preview provider
final templatePreviewProvider = Provider.family<String, TemplatePreviewParams>((ref, params) {
  return TemplatePreviewService.generatePreview(params.template, params.sampleClient);
});

// Template form state
class TemplateFormState {
  final bool isLoading;
  final String? error;
  final bool isSaved;

  const TemplateFormState({
    this.isLoading = false,
    this.error,
    this.isSaved = false,
  });

  TemplateFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSaved,
  }) {
    return TemplateFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

// Template form notifier
class TemplateFormNotifier extends StateNotifier<TemplateFormState> {
  final TemplateDao _dao;

  TemplateFormNotifier(this._dao) : super(const TemplateFormState());

  Future<void> saveTemplate(TemplateModel template) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      if (template.id == 0) {
        // New template
        await _dao.insertTemplate(TemplatesCompanion.insert(
          name: template.name,
          type: template.type,
          subject: Value(template.subject),
          body: template.body,
        ));
      } else {
        // Update existing template
        await _dao.updateTemplate(template.id, TemplatesCompanion(
          name: Value(template.name),
          type: Value(template.type),
          subject: Value(template.subject),
          body: Value(template.body),
        ));
      }
      
      state = state.copyWith(isLoading: false, isSaved: true);
      
      // Reset saved state after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(isSaved: false);
        }
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void resetState() {
    state = const TemplateFormState();
  }
}

// Template preview parameters
class TemplatePreviewParams {
  final TemplateModel template;
  final ClientModel sampleClient;

  const TemplatePreviewParams({
    required this.template,
    required this.sampleClient,
  });
}

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