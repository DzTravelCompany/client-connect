import 'package:drift/drift.dart';

part 'database.g.dart';


// Client table definition
class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstName => text().withLength(min: 1, max: 100)();
  TextColumn get lastName => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get jobTitle => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ClientActivity')
class ClientActivities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clientId => integer().references(Clients, #id, onDelete: KeyAction.cascade)();
  TextColumn get activityType => text()();
  TextColumn get description => text()();
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}


// Drift table definition for filter presets
@DataClassName('ClientFilterPresetData')
class ClientFilterPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get searchTerm => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get company => text().nullable()();
  TextColumn get dateRangeStart => text().nullable()();
  TextColumn get dateRangeEnd => text().nullable()();
  TextColumn get sortBy => text().withDefault(const Constant('name'))();
  BoolColumn get sortAscending => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Template table definition
class Templates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get subject => text().nullable()();
  TextColumn get body => text()(); // Keep for backward compatibility
  TextColumn get templateType => text().withDefault(const Constant('email'))(); // 'email' or 'whatsapp'
  TextColumn get blocksJson => text().nullable()(); // JSON representation of blocks
  BoolColumn get isEmail => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class TemplateBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(Templates, #id, onDelete: KeyAction.cascade)();
  TextColumn get blockId => text()(); // UUID for the block
  TextColumn get blockType => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get propertiesJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class ContentPlaceholders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get label => text()();
  TextColumn get description => text().nullable()();
  TextColumn get defaultValue => text().nullable()();
  TextColumn get dataType => text().withDefault(const Constant('text'))(); // 'text', 'number', 'date', 'boolean'
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Tags table for client categorization
@DataClassName('Tag')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text().withLength(min: 7, max: 7)(); // Hex color
  TextColumn get description => text().nullable().withLength(max: 200)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Junction table for client-tag relationships
@DataClassName('ClientTag')
class ClientTags extends Table {
  IntColumn get clientId => integer().references(Clients, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {clientId, tagId};
}

// Campaign table for tracking message campaigns
class Campaigns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  IntColumn get templateId => integer().references(Templates, #id)();
  TextColumn get status => text().withLength(min: 1, max: 50)(); // 'pending', 'in_progress', 'completed', 'failed'
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

// Message log for tracking individual message sends
class MessageLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get campaignId => integer().references(Campaigns, #id)();
  IntColumn get clientId => integer().references(Clients, #id)();
  TextColumn get type => text().withLength(min: 1, max: 50)(); // 'email' or 'whatsapp'
  TextColumn get status => text().withLength(min: 1, max: 50)(); // 'pending', 'sent', 'failed'
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get lastRetryAt => dateTime().nullable()();
  TextColumn get retryReason => text().nullable()();
  DateTimeColumn get sentAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class RetryConfigurations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();
  IntColumn get initialDelayMinutes => integer().withDefault(const Constant(5))();
  IntColumn get maxDelayMinutes => integer().withDefault(const Constant(60))();
  TextColumn get backoffStrategy => text().withDefault(const Constant('exponential'))(); // 'linear', 'exponential', 'fixed'
  BoolColumn get retryOnNetworkError => boolean().withDefault(const Constant(true))();
  BoolColumn get retryOnServerError => boolean().withDefault(const Constant(true))();
  BoolColumn get retryOnTimeout => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class RetryLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get messageLogId => integer().references(MessageLogs, #id)();
  IntColumn get retryAttempt => integer()();
  TextColumn get status => text().withLength(min: 1, max: 50)();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get errorType => text().nullable()();
  DateTimeColumn get attemptedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get delayMinutes => integer().nullable()();
  TextColumn get triggerType => text().withDefault(const Constant('automatic'))(); // 'automatic', 'manual'
}

@DriftDatabase(tables: [Clients, ClientActivities, ClientFilterPresets, Templates, Tags, ClientTags, Campaigns, MessageLogs, RetryConfigurations, RetryLogs,
  TemplateBlocks,
  ContentPlaceholders,])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
