import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'config_service.dart';

typedef ServiceFactory<T> = T Function();

class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();

  ServiceLocator._();

  final Map<Type, dynamic> _services = {};
  final Map<Type, ServiceFactory> _factories = {};
  final Map<Type, bool> _singletons = {};

  // Register a singleton service
  void registerSingleton<T>(T service) {
    _services[T] = service;
    _singletons[T] = true;
    _logRegistration<T>('singleton');
  }

  // Register a factory that creates new instances each time
  void registerFactory<T>(ServiceFactory<T> factory) {
    _factories[T] = factory;
    _singletons[T] = false;
    _logRegistration<T>('factory');
  }

  // Register a lazy singleton (created on first access)
  void registerLazySingleton<T>(ServiceFactory<T> factory) {
    _factories[T] = factory;
    _singletons[T] = true;
    _logRegistration<T>('lazy singleton');
  }

  // Get a service
  T get<T>() {
    final type = T;
    
    // Check if already instantiated
    if (_services.containsKey(type)) {
      return _services[type] as T;
    }

    // Check if factory exists
    if (_factories.containsKey(type)) {
      final factory = _factories[type] as ServiceFactory<T>;
      final instance = factory();
      
      // Store if singleton
      if (_singletons[type] == true) {
        _services[type] = instance;
      }
      
      return instance;
    }

    throw ServiceNotRegisteredException(type);
  }

  // Check if service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  // Remove a service
  void unregister<T>() {
    _services.remove(T);
    _factories.remove(T);
    _singletons.remove(T);
    _logUnregistration<T>();
  }

  // Clear all services (useful for testing)
  void reset() {
    _services.clear();
    _factories.clear();
    _singletons.clear();
    Logger.instance.debug('ServiceLocator reset');
  }

  // Get all registered service types
  List<Type> get registeredTypes => [
    ..._services.keys,
    ..._factories.keys,
  ];

  void _logRegistration<T>(String type) {
    Logger.instance.debug('Registered $type: ${T.toString()}');
  }

  void _logUnregistration<T>() {
    Logger.instance.debug('Unregistered: ${T.toString()}');
  }
}

class ServiceNotRegisteredException implements Exception {
  final Type type;
  ServiceNotRegisteredException(this.type);
  
  @override
  String toString() => 'Service not registered: $type';
}

// Extension for easier access
extension ServiceLocatorExtension on Object {
  ServiceLocator get locator => ServiceLocator.instance;
}

// Helper functions for common patterns
T getService<T>() => ServiceLocator.instance.get<T>();
bool isServiceRegistered<T>() => ServiceLocator.instance.isRegistered<T>();

// Service registration configuration
class ServiceConfig {
  static Future<void> setupDependencies() async {
    final locator = ServiceLocator.instance;
    
    // Register core services
    locator.registerSingleton<Logger>(Logger.instance);
    
    // Register configuration service
    locator.registerSingleton<ConfigService>(ConfigService.instance);
    
    Logger.instance.info('Dependencies configured');
  }
  
  static Future<void> setupTestDependencies() async {
    final locator = ServiceLocator.instance;
    locator.reset();
    
    // Register test/mock services
    locator.registerSingleton<Logger>(Logger.instance);
    
    Logger.instance.info('Test dependencies configured');
  }
}

// Abstract base class for services
abstract class Service {
  bool _disposed = false;
  
  bool get disposed => _disposed;
  
  @mustCallSuper
  void dispose() {
    _disposed = true;
  }
}

// Mixin for automatic service disposal
mixin DisposableService {
  final List<Service> _services = [];
  
  void registerService(Service service) {
    _services.add(service);
  }
  
  void disposeServices() {
    for (final service in _services) {
      if (!service.disposed) {
        service.dispose();
      }
    }
    _services.clear();
  }
} 