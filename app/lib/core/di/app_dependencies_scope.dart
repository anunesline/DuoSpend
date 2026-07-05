import 'package:flutter/widgets.dart';

import 'app_dependency_container.dart';

class AppDependenciesScope extends InheritedWidget {
  final AppDependencyContainer dependencies;

  const AppDependenciesScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  static AppDependencyContainer of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppDependenciesScope>();

    if (scope == null) {
      throw StateError(
        'AppDependenciesScope não encontrado na árvore de widgets.',
      );
    }

    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependenciesScope oldWidget) {
    return dependencies != oldWidget.dependencies;
  }
}