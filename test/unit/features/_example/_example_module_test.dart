import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:aptis_app/features/_example/_example_module.dart';
import 'package:aptis_app/features/_example/_example_service.dart';

void main() {
  tearDown(() => GetIt.instance.reset());

  test('setupExampleModule registers ExampleService as a resolvable singleton', () {
    setupExampleModule();

    expect(GetIt.instance.isRegistered<ExampleService>(), isTrue);
    expect(GetIt.instance<ExampleService>().greeting(), 'hello from example module');
  });
}
