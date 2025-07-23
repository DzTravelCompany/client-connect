import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../clients/data/client_model.dart';
import '../../clients/logic/client_providers.dart';
import '../../templates/data/template_model.dart';

/// Service for generating smart client suggestions based on various factors
class ClientSuggestionService {
  /// Generate client suggestions based on campaign context
  static Future<List<ClientModel>> getSuggestedClients({
    required Ref ref,
    required String? campaignContext,
    TemplateModel? selectedTemplate,
    List<ClientModel>? alreadySelectedClients,
    int limit = 10,
  }) async {
    final allClients = await ref.read(allClientsProvider.future);
    
    // Filter out already selected clients
    final availableClients = alreadySelectedClients != null
        ? allClients.where((client) => 
            !alreadySelectedClients.any((selected) => selected.id == client.id)).toList()
        : allClients;
    
    if (availableClients.isEmpty) return [];
    
    // Calculate suggestion scores for each client
    final scoredClients = availableClients.map((client) {
      return ScoredClient(
        client: client,
        score: _calculateSuggestionScore(
          client: client,
          campaignContext: campaignContext,
          templateType: selectedTemplate?.type,
        ),
      );
    }).toList();
    
    // Sort by score (descending)
    scoredClients.sort((a, b) => b.score.compareTo(a.score));
    
    // Return top suggestions
    return scoredClients
        .take(limit)
        .map((scored) => scored.client)
        .toList();
  }
  
  /// Calculate a suggestion score for a client based on various factors
  /// Higher score = better suggestion
  static double _calculateSuggestionScore({
    required ClientModel client,
    String? campaignContext,
    String? templateType,
  }) {
    double score = 0.0;
    
    // Factor 1: Contact information completeness
    if (client.email != null && client.email!.isNotEmpty) {
      score += 10.0;
    }
    
    if (client.phone != null && client.phone!.isNotEmpty) {
      score += 10.0;
    }
    
    // Factor 2: Template type compatibility
    if (templateType == 'email' && client.email != null && client.email!.isNotEmpty) {
      score += 20.0;
    } else if (templateType == 'whatsapp' && client.phone != null && client.phone!.isNotEmpty) {
      score += 20.0;
    }
    
    // Factor 3: Campaign context relevance
    // This would be more sophisticated in a real implementation
    if (campaignContext != null) {
      final contextLower = campaignContext.toLowerCase();
      
      if (contextLower.contains('newsletter') && 
          client.email != null && 
          client.email!.isNotEmpty) {
        score += 15.0;
      }
      
      if (contextLower.contains('promo') && 
          client.company != null && 
          ['Acme Inc', 'TechCorp', 'Global Services'].contains(client.company)) {
        score += 15.0;
      }
      
      // Add more context-specific scoring rules as needed
    }
    
    // Factor 4: Client engagement history (simulated)
    // In a real implementation, this would use actual engagement data
    score += (client.id % 5) * 2.0; // Simulated engagement score
    
    return score;
  }
  
  /// Get the suggestion reason for a client
  static String getSuggestionReason({
    required ClientModel client,
    String? campaignContext,
    String? templateType,
  }) {
    // In a real implementation, this would provide actual reasons based on the scoring factors
    
    if (templateType == 'email' && client.email != null && client.email!.isNotEmpty) {
      return 'Has valid email address';
    }
    
    if (templateType == 'whatsapp' && client.phone != null && client.phone!.isNotEmpty) {
      return 'Has valid phone number';
    }
    
    if (campaignContext != null) {
      final contextLower = campaignContext.toLowerCase();
      
      if (contextLower.contains('newsletter')) {
        return 'Good fit for newsletters';
      }
      
      if (contextLower.contains('promo')) {
        return 'Responds well to promotions';
      }
    }
    
    // Default reasons based on client ID (simulated)
    if (client.id % 3 == 0) {
      return 'Recently active client';
    } else if (client.id % 3 == 1) {
      return 'High engagement rate';
    } else {
      return 'Matches campaign profile';
    }
  }
}

/// Helper class for scoring clients
class ScoredClient {
  final ClientModel client;
  final double score;
  
  ScoredClient({
    required this.client,
    required this.score,
  });
}

/// Provider for client suggestions based on campaign context
final clientSuggestionsProvider = FutureProvider.family<List<ClientModel>, ClientSuggestionParams>((ref, params) async {
  return ClientSuggestionService.getSuggestedClients(
    ref: ref,
    campaignContext: params.campaignContext,
    selectedTemplate: params.selectedTemplate,
    alreadySelectedClients: params.alreadySelectedClients,
    limit: params.limit,
  );
});

/// Parameters for client suggestions
class ClientSuggestionParams {
  final String? campaignContext;
  final TemplateModel? selectedTemplate;
  final List<ClientModel>? alreadySelectedClients;
  final int limit;
  
  const ClientSuggestionParams({
    this.campaignContext,
    this.selectedTemplate,
    this.alreadySelectedClients,
    this.limit = 10,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientSuggestionParams &&
          runtimeType == other.runtimeType &&
          campaignContext == other.campaignContext &&
          selectedTemplate == other.selectedTemplate &&
          limit == other.limit;

  @override
  int get hashCode => 
      campaignContext.hashCode ^ 
      selectedTemplate.hashCode ^ 
      limit.hashCode;
}