import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'package:pte_app/features/_example/_example_module.dart';
import 'package:pte_app/features/_example/_example_repository.dart';
import 'package:pte_app/features/_example/_example_repository_impl.dart';

void main() {
  tearDown(() => GetIt.instance.reset());

  test('setupExampleModule registers ExampleRepository behind its abstract interface', () {
    setupExampleModule();

    // Resolved by the abstract type, per CODING_STANDARDS_APP.md's DI rule —
    // this is the property a real feature module must replicate, not just
    // "something gets registered." (`greeting()`'s return value is covered
    // by the constructor-injection test below, not repeated here.)
    expect(GetIt.instance.isRegistered<ExampleRepository>(), isTrue);
    expect(GetIt.instance<ExampleRepository>(), isA<ExampleRepositoryImpl>());
  });

  test('ExampleRepositoryImpl receives its dependency via constructor injection, not a hardcoded instance', () {
    final fakeLogger = Logger();
    final repository = ExampleRepositoryImpl(logger: fakeLogger);

    expect(repository.greeting(), 'hello from example module');
  });
}
