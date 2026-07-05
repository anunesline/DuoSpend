import '../di/app_dependency_container.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<AppDependencyContainer> initialize() async {
    return const AppDependencyContainer();
  }
}