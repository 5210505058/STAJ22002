import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'data.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
      (ref) => CartNotifier()..loadFromHive(),
);

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);
  static const _boxName = 'cart';
  static const _key = 'items';

  Box get _box => Hive.box(_boxName);

  void loadFromHive() {
    final raw = _box.get(_key);
    if (raw is List) {
      try {
        final restored = raw
            .cast<Map>()
            .map((m) => CartItem.fromMap(m.cast<String, dynamic>()))
            .where((ci) => productIndex[ci.productId] != null)
            .toList();
        state = restored;
      } catch (_) {

        _box.put(_key, []);
      }
    }
  }

  void _persist() {
    final list = state.map((e) => e.toMap()).toList();
    _box.put(_key, list);
  }

  void add(CartItem item) {
    state = [...state, item];
    _persist();
  }

  void removeAt(int index) {
    state = [...state]..removeAt(index);
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }

  double total() {
    double sum = 0;
    for (final it in state) {
      final p = productIndex[it.productId]!;
      double price = p.basePrice;
      for (final group in p.optionGroups) {
        if (group.singleChoice) {
          final selId = it.selections.singleChoices[group.id];
          if (selId != null) {
            final item = group.items.firstWhere((e) => e.id == selId);
            price += item.priceDelta ?? 0;
          }
        } else {
          final setIds = it.selections.multiChoices[group.id] ?? {};
          for (final id in setIds) {
            final item = group.items.firstWhere((e) => e.id == id);
            price += item.priceDelta ?? 0;
          }
        }
      }
      sum += price * it.quantity;
    }
    return sum;
  }
}