import 'dart:convert';
import 'package:meta/meta.dart';
import 'result.dart';

// Configuration validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic>? migratedConfig;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.migratedConfig,
  });

  factory ValidationResult.success({
    List<String> warnings = const [],
    Map<String, dynamic>? migratedConfig,
  }) {
    return ValidationResult(
      isValid: true,
      errors: [],
      warnings: warnings,
      migratedConfig: migratedConfig,
    );
  }

  factory ValidationResult.failure({
    required List<String> errors,
    List<String> warnings = const [],
  }) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ValidationResult:');
    buffer.writeln('  Valid: $isValid');
    
    if (errors.isNotEmpty) {
      buffer.writeln('  Errors:');
      for (final error in errors) {
        buffer.writeln('    - $error');
      }
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('  Warnings:');
      for (final warning in warnings) {
        buffer.writeln('    - $warning');
      }
    }
    
    return buffer.toString();
  }
}

// Configuration validator interface
abstract class ConfigValidator {
  String get section;
  ValidationResult validate(Map<String, dynamic> config);
  Map<String, dynamic> getDefaults();
  Map<String, dynamic>? migrate(Map<String, dynamic> config, int fromVersion);
}

// Display configuration validator
class DisplayConfigValidator extends ConfigValidator {
  @override
  String get section => 'display';

  @override
  ValidationResult validate(Map<String, dynamic> config) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate fullscreen
    if (config.containsKey('fullscreen') && config['fullscreen'] is! bool) {
      errors.add('fullscreen must be a boolean');
    }

    // Validate resolution
    if (config.containsKey('resolution')) {
      final resolution = config['resolution'];
      if (resolution is! List || resolution.length != 2) {
        errors.add('resolution must be a list with exactly 2 elements');
      } else {
        for (int i = 0; i < resolution.length; i++) {
          if (resolution[i] is! int || resolution[i] <= 0) {
            errors.add('resolution[$i] must be a positive integer');
          }
        }
      }
    }

    // Validate orientation
    if (config.containsKey('orientation')) {
      final orientation = config['orientation'];
      if (orientation is! String || !['portrait', 'landscape'].contains(orientation)) {
        errors.add('orientation must be either "portrait" or "landscape"');
      }
    }

    // Validate auto_refresh_interval
    if (config.containsKey('auto_refresh_interval')) {
      final interval = config['auto_refresh_interval'];
      if (interval is! int || interval < 0) {
        errors.add('auto_refresh_interval must be a non-negative integer');
      } else if (interval > 0 && interval < 5) {
        warnings.add('auto_refresh_interval less than 5 seconds may cause excessive API calls');
      }
    }

    // Validate metadata_auto_hide_delay
    if (config.containsKey('metadata_auto_hide_delay')) {
      final delay = config['metadata_auto_hide_delay'];
      if (delay is! int || delay < 0) {
        errors.add('metadata_auto_hide_delay must be a non-negative integer');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success(warnings: warnings)
        : ValidationResult.failure(errors: errors, warnings: warnings);
  }

  @override
  Map<String, dynamic> getDefaults() {
    return {
      'fullscreen': true,
      'resolution': [600, 1024],
      'orientation': 'portrait',
      'auto_refresh_interval': 30,
      'show_metadata_on_tap': true,
      'metadata_auto_hide_delay': 3,
    };
  }

  @override
  Map<String, dynamic>? migrate(Map<String, dynamic> config, int fromVersion) {
    if (fromVersion < 2) {
      // Migration from version 1 to 2: rename 'auto_refresh' to 'auto_refresh_interval'
      if (config.containsKey('auto_refresh') && !config.containsKey('auto_refresh_interval')) {
        config['auto_refresh_interval'] = config['auto_refresh'];
        config.remove('auto_refresh');
      }
    }
    
    if (fromVersion < 3) {
      // Migration from version 2 to 3: add new metadata settings
      if (!config.containsKey('show_metadata_on_tap')) {
        config['show_metadata_on_tap'] = true;
      }
      if (!config.containsKey('metadata_auto_hide_delay')) {
        config['metadata_auto_hide_delay'] = 3;
      }
    }
    
    return config;
  }
}

// API configuration validator
class ApiConfigValidator extends ConfigValidator {
  @override
  String get section => 'api';

  @override
  ValidationResult validate(Map<String, dynamic> config) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate base_url
    if (config.containsKey('base_url')) {
      final baseUrl = config['base_url'];
      if (baseUrl is! String || !Uri.tryParse(baseUrl)?.hasScheme == true) {
        errors.add('base_url must be a valid URL');
      } else if (!baseUrl.startsWith('https://')) {
        warnings.add('base_url should use HTTPS for security');
      }
    }

    // Validate timeout
    if (config.containsKey('timeout')) {
      final timeout = config['timeout'];
      if (timeout is! int || timeout <= 0) {
        errors.add('timeout must be a positive integer');
      } else if (timeout > 60) {
        warnings.add('timeout greater than 60 seconds may cause poor user experience');
      }
    }

    // Validate retry_attempts
    if (config.containsKey('retry_attempts')) {
      final retryAttempts = config['retry_attempts'];
      if (retryAttempts is! int || retryAttempts < 0) {
        errors.add('retry_attempts must be a non-negative integer');
      } else if (retryAttempts > 10) {
        warnings.add('retry_attempts greater than 10 may cause excessive delays');
      }
    }

    // Validate cache_images
    if (config.containsKey('cache_images') && config['cache_images'] is! bool) {
      errors.add('cache_images must be a boolean');
    }

    return errors.isEmpty
        ? ValidationResult.success(warnings: warnings)
        : ValidationResult.failure(errors: errors, warnings: warnings);
  }

  @override
  Map<String, dynamic> getDefaults() {
    return {
      'base_url': 'https://api.scryfall.com',
      'timeout': 10,
      'retry_attempts': 3,
      'cache_images': true,
    };
  }

  @override
  Map<String, dynamic>? migrate(Map<String, dynamic> config, int fromVersion) {
    if (fromVersion < 2) {
      // Migration from version 1 to 2: ensure HTTPS
      if (config.containsKey('base_url') && config['base_url'] is String) {
        final url = config['base_url'] as String;
        if (url.startsWith('http://')) {
          config['base_url'] = url.replaceFirst('http://', 'https://');
        }
      }
    }
    
    return config;
  }
}

// Filters configuration validator
class FiltersConfigValidator extends ConfigValidator {
  @override
  String get section => 'filters';

  @override
  ValidationResult validate(Map<String, dynamic> config) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate enabled
    if (config.containsKey('enabled') && config['enabled'] is! bool) {
      errors.add('enabled must be a boolean');
    }

    // Validate list fields
    final listFields = ['sets', 'colors', 'card_types', 'creature_types', 'rarity'];
    for (final field in listFields) {
      if (config.containsKey(field)) {
        final value = config[field];
        if (value is! List) {
          errors.add('$field must be a list');
        } else {
          for (int i = 0; i < value.length; i++) {
            if (value[i] is! String) {
              errors.add('$field[$i] must be a string');
            }
          }
        }
      }
    }

    // Validate format
    if (config.containsKey('format')) {
      final format = config['format'];
      if (format is! String) {
        errors.add('format must be a string');
      } else {
        final validFormats = [
          'standard', 'modern', 'legacy', 'vintage', 'commander',
          'pioneer', 'historic', 'pauper', 'brawl', 'future'
        ];
        if (!validFormats.contains(format)) {
          warnings.add('format "$format" is not a recognized format');
        }
      }
    }

    return errors.isEmpty
        ? ValidationResult.success(warnings: warnings)
        : ValidationResult.failure(errors: errors, warnings: warnings);
  }

  @override
  Map<String, dynamic> getDefaults() {
    return {
      'enabled': false,
      'sets': <String>[],
      'colors': <String>[],
      'card_types': <String>[],
      'creature_types': <String>[],
      'rarity': <String>[],
      'format': 'standard',
    };
  }

  @override
  Map<String, dynamic>? migrate(Map<String, dynamic> config, int fromVersion) {
    if (fromVersion < 2) {
      // Migration from version 1 to 2: split types into card_types and creature_types
      if (config.containsKey('types') && !config.containsKey('card_types')) {
        config['card_types'] = config['types'];
        config.remove('types');
      }
      if (!config.containsKey('creature_types')) {
        config['creature_types'] = <String>[];
      }
    }
    
    return config;
  }
}

// Main configuration validator
class ConfigurationValidator {
  final List<ConfigValidator> _validators = [
    DisplayConfigValidator(),
    ApiConfigValidator(),
    FiltersConfigValidator(),
  ];

  static const int _currentVersion = 3;

  ValidationResult validateConfiguration(Map<String, dynamic> config) {
    final errors = <String>[];
    final warnings = <String>[];
    Map<String, dynamic>? migratedConfig;

    // Check version and migrate if needed
    final version = config['version'] as int? ?? 1;
    if (version < _currentVersion) {
      warnings.add('Configuration version $version is outdated, migrating to version $_currentVersion');
      migratedConfig = _migrateConfiguration(config, version);
    }

    final configToValidate = migratedConfig ?? config;

    // Validate each section
    for (final validator in _validators) {
      final sectionConfig = configToValidate[validator.section] as Map<String, dynamic>? ?? {};
      final result = validator.validate(sectionConfig);
      
      if (!result.isValid) {
        errors.addAll(result.errors.map((e) => '${validator.section}: $e'));
      }
      warnings.addAll(result.warnings.map((w) => '${validator.section}: $w'));
    }

    return errors.isEmpty
        ? ValidationResult.success(warnings: warnings, migratedConfig: migratedConfig)
        : ValidationResult.failure(errors: errors, warnings: warnings);
  }

  Map<String, dynamic> getDefaultConfiguration() {
    final config = <String, dynamic>{
      'version': _currentVersion,
    };

    for (final validator in _validators) {
      config[validator.section] = validator.getDefaults();
    }

    return config;
  }

  Map<String, dynamic> _migrateConfiguration(Map<String, dynamic> config, int fromVersion) {
    final migratedConfig = Map<String, dynamic>.from(config);

    for (final validator in _validators) {
      final sectionConfig = migratedConfig[validator.section] as Map<String, dynamic>? ?? {};
      final migrated = validator.migrate(sectionConfig, fromVersion);
      if (migrated != null) {
        migratedConfig[validator.section] = migrated;
      }
    }

    migratedConfig['version'] = _currentVersion;
    return migratedConfig;
  }

  Result<Map<String, dynamic>> validateAndMergeWithDefaults(Map<String, dynamic> config) {
    final result = validateConfiguration(config);
    
    if (!result.isValid) {
      return Failure(ValidationError(
        message: 'Configuration validation failed',
        fieldErrors: {
          for (final error in result.errors) error: error,
        },
      ));
    }

    // Merge with defaults
    final defaults = getDefaultConfiguration();
    final merged = _deepMerge(defaults, result.migratedConfig ?? config);
    
    return Success(merged);
  }

  Map<String, dynamic> _deepMerge(Map<String, dynamic> defaults, Map<String, dynamic> config) {
    final result = Map<String, dynamic>.from(defaults);
    
    config.forEach((key, value) {
      if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
        result[key] = _deepMerge(result[key] as Map<String, dynamic>, value);
      } else {
        result[key] = value;
      }
    });
    
    return result;
  }
}

// Enhanced configuration service with validation
class EnhancedConfigService {
  static EnhancedConfigService? _instance;
  static EnhancedConfigService get instance => _instance ??= EnhancedConfigService._();

  EnhancedConfigService._();

  final ConfigurationValidator _validator = ConfigurationValidator();
  Map<String, dynamic>? _cachedConfig;

  Result<Map<String, dynamic>> loadAndValidateConfiguration(String configJson) {
    try {
      final config = jsonDecode(configJson) as Map<String, dynamic>;
      return _validator.validateAndMergeWithDefaults(config);
    } catch (e) {
      return Failure(ConfigurationError(
        message: 'Failed to parse configuration',
        originalError: e,
      ));
    }
  }

  String getDefaultConfigurationJson() {
    final config = _validator.getDefaultConfiguration();
    return jsonEncode(config);
  }

  ValidationResult validateConfiguration(Map<String, dynamic> config) {
    return _validator.validateConfiguration(config);
  }

  Map<String, dynamic> getDefaultConfiguration() {
    return _validator.getDefaultConfiguration();
  }

  // Type-safe configuration getters
  bool getDisplayFullscreen(Map<String, dynamic> config) {
    return config['display']?['fullscreen'] as bool? ?? true;
  }

  List<int> getDisplayResolution(Map<String, dynamic> config) {
    final resolution = config['display']?['resolution'] as List?;
    return resolution?.cast<int>() ?? [600, 1024];
  }

  String getDisplayOrientation(Map<String, dynamic> config) {
    return config['display']?['orientation'] as String? ?? 'portrait';
  }

  int getAutoRefreshInterval(Map<String, dynamic> config) {
    return config['display']?['auto_refresh_interval'] as int? ?? 30;
  }

  String getApiBaseUrl(Map<String, dynamic> config) {
    return config['api']?['base_url'] as String? ?? 'https://api.scryfall.com';
  }

  int getApiTimeout(Map<String, dynamic> config) {
    return config['api']?['timeout'] as int? ?? 10;
  }

  bool getFiltersEnabled(Map<String, dynamic> config) {
    return config['filters']?['enabled'] as bool? ?? false;
  }

  List<String> getFilterSets(Map<String, dynamic> config) {
    final sets = config['filters']?['sets'] as List?;
    return sets?.cast<String>() ?? <String>[];
  }
} 