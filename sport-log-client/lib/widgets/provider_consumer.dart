import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProviderConsumer<T extends ChangeNotifier> extends StatelessWidget {
  const ProviderConsumer({
    required T Function(BuildContext) this.create,
    required this.builder,
    super.key,
  }) : value = null;

  const ProviderConsumer.value({
    required T this.value,
    required this.builder,
    super.key,
  }) : create = null;

  final T Function(BuildContext)? create;
  final T? value;
  final Widget Function(BuildContext, T, Widget?) builder;

  @override
  Widget build(BuildContext context) {
    return value != null
        ? ChangeNotifierProvider<T>.value(
            value: value!,
            child: Consumer<T>(builder: builder),
          )
        : ChangeNotifierProvider<T>(
            create: create!,
            child: Consumer<T>(builder: builder),
          );
  }
}
