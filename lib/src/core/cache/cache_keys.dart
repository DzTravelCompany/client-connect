class CacheKeys {
  // Client cache keys
  static const String clientPrefix = 'clients';
  static String clientById(int id) => '${clientPrefix}_by_id_$id';
  static String clientsPaginated(int page, int limit, String? searchTerm) => 
      '${clientPrefix}_paginated_${page}_${limit}_${searchTerm ?? 'all'}';
  static const String clientCompanies = '${clientPrefix}_companies';
  
  // Tag cache keys
  static const String tagPrefix = 'tags';
  static String clientTags(int clientId) => '${tagPrefix}_client_$clientId';
  
  // Campaign cache keys
  static const String campaignPrefix = 'campaigns';
  static String campaignsByClient(int clientId) => '${campaignPrefix}_client_$clientId';
  
  // Template cache keys
  static const String templatePrefix = 'templates';
  
  // Analytics cache keys
  static const String analyticsPrefix = 'analytics';
}