import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'data.dart';

class Order {
  final String id;
  final DateTime createdAt;
  final List<CartItem> items;
  final double total;
  final String delivery; // 'pickup' | 'delivery'
  final String payMethod;
  final String? address;
  final String? note;

  Order({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.total,
    required this.delivery,
    required this.payMethod,
    this.address,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((e) => e.toMap()).toList(),
    'total': total,
    'delivery': delivery,
    'payMethod': payMethod,
    'address': address,
    'note': note,
  };

  factory Order.fromMap(Map<String, dynamic> m) => Order(
    id: m['id'] as String,
    createdAt: DateTime.parse(m['createdAt'] as String),
    items: (m['items'] as List)
        .cast<Map>()
        .map((x) => CartItem.fromMap(x.cast<String, dynamic>()))
        .toList(),
    total: (m['total'] as num).toDouble(),
    delivery: m['delivery'] as String,
    payMethod: m['payMethod'] as String,
    address: m['address'] as String?,
    note: m['note'] as String?,
  );
}

class OrderRepo {
  static const _boxName = 'orders';
  static Box get _box => Hive.box(_boxName);
  static String userKey(String? email) => email ?? 'guest';

  static Future<void> addOrder(String userKey, Order o) async {
    final raw = _box.get(userKey);
    final list = (raw is List ? raw.cast<Map>() : <Map>[]);
    list.add(o.toMap());
    await _box.put(userKey, list);
  }

  static List<Order> listOrders(String userKey) {
    final raw = _box.get(userKey);
    if (raw is! List) return [];
    return raw
        .cast<Map>()
        .map((m) => Order.fromMap(m.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
