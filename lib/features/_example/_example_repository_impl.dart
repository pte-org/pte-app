import 'package:logger/logger.dart';

import 'package:pte_app/features/_example/_example_repository.dart';

/// Depends on [Logger] via constructor injection (resolved through GetIt in
/// [setupExampleModule]), never constructed with `new` inside a BLoC — the
/// property this throwaway example exists to demonstrate for Phase 1+.
class ExampleRepositoryImpl implements ExampleRepository {
  final Logger _logger;

  ExampleRepositoryImpl({required Logger logger}) : _logger = logger;

  @override
  String greeting() {
    const message = 'hello from example module';
    _logger.d(message);
    return message;
  }
}
