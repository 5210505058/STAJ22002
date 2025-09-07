import 'package:flutter/foundation.dart';

enum ProductType { coffee, dessert }

@immutable
class OptionItem {
  final String id;
  final String name;
  final double? priceDelta;
  const OptionItem({required this.id, required this.name, this.priceDelta});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'priceDelta': priceDelta,
  };

  factory OptionItem.fromMap(Map<String, dynamic> map) => OptionItem(
    id: map['id'] as String,
    name: map['name'] as String,
    priceDelta: (map['priceDelta'] as num?)?.toDouble(),
  );
}

@immutable
class OptionGroup {
  final String id;
  final String title;
  final bool singleChoice; // true: tek seçim, false: çoklu seçim
  final List<OptionItem> items;
  const OptionGroup({
    required this.id,
    required this.title,
    required this.singleChoice,
    required this.items,
  });
}

@immutable
class Product {
  final String id;
  final String name;
  final String imagePath;
  final ProductType type;
  final double basePrice;
  final List<OptionGroup> optionGroups; // kahveler için
  final bool askQuantity; // tatlılarda porsiyon

  const Product({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.type,
    required this.basePrice,
    this.optionGroups = const [],
    this.askQuantity = false,
  });
}

@immutable
class SelectedOptions {
  // singleChoice gruplar için: groupId -> itemId
  final Map<String, String> singleChoices;
  // multiChoice gruplar için: groupId -> {itemId1, itemId2, ...}
  final Map<String, Set<String>> multiChoices;

  const SelectedOptions({
    this.singleChoices = const {},
    this.multiChoices = const {},
  });

  SelectedOptions copyWith({
    Map<String, String>? single,
    Map<String, Set<String>>? multi,
  }) => SelectedOptions(
    singleChoices: single ?? Map.of(singleChoices),
    multiChoices: multi ?? multiChoices.map((k, v) => MapEntry(k, Set.of(v))),
  );

  Map<String, dynamic> toMap() => {
    'single': singleChoices,
    'multi': multiChoices.map((k, v) => MapEntry(k, v.toList())),
  };

  factory SelectedOptions.fromMap(Map<String, dynamic> map) => SelectedOptions(
    singleChoices: (map['single'] as Map?)?.cast<String, String>() ?? const {},
    multiChoices: ((map['multi'] as Map?)?.map((k, v) =>
        MapEntry(k as String, (v as List).map((e) => e as String).toSet())) ?? const {})
        .cast<String, Set<String>>(),
  );
}

@immutable
class CartItem {
  final String productId; // persist için id saklıyoruz
  final SelectedOptions selections;
  final int quantity; // tatlı için porsiyon, kahvede 1

  const CartItem({required this.productId, required this.selections, required this.quantity});

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'selections': selections.toMap(),
    'quantity': quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    productId: map['productId'] as String,
    selections: SelectedOptions.fromMap((map['selections'] as Map).cast<String, dynamic>()),
    quantity: (map['quantity'] as num).toInt(),
  );
}