/// Abstract interface — BLoCs/consumers depend on this, never on
/// [ExampleRepositoryImpl] directly, per `docs/CODING_STANDARDS_APP.md`'s
/// Dependency Inversion rule.
abstract class ExampleRepository {
  String greeting();
}
