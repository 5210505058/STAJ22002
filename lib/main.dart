// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';
import 'data.dart';
import 'cart_notifier.dart';

// Auth & Profil
import 'auth_notifier.dart';
import 'auth_pages.dart';
import 'profile_page.dart';
import 'order_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('cart');   // sepet
  await Hive.openBox('users');  // auth users
  await Hive.openBox('auth');   // session
  await Hive.openBox('orders'); // sipariş geçmişi
  runApp(const ProviderScope(child: MyApp()));
}

// ---- THEME MODE (Riverpod) ----
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Basit shimmer benzeri skeleton kutu
class SkeletonBox extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? radius;
  const SkeletonBox({super.key, required this.height, required this.width, this.radius});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? BorderRadius.circular(12);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return ClipRRect(
          borderRadius: radius,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 2, 0),
                end: Alignment(t * 2, 0),
                colors: [
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(.55),
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(.25),
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(.55),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
        visualDensity: VisualDensity.compact,
        cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
        visualDensity: VisualDensity.compact,
        cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: user == null ? const LoginPage() : const MainScaffold(),
    );
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});
  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CatalogGrid(title: 'Kahveler', products: coffees),
      const CatalogGrid(title: 'Tatlılar', products: desserts),
      const CartPage(),
    ];

    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kahve & Tatlı Dükkanı'),
        actions: [
          IconButton(
            tooltip: isDark ? 'Aydınlık moda geç' : 'Karanlık moda geç',
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round),
            onPressed: () {
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
              current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => setState(() => _index = 2),
            tooltip: 'Sepetim',
          ),
        ],
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_cafe_outlined), label: 'Kahve'),
          NavigationDestination(icon: Icon(Icons.cake_outlined), label: 'Tatlı'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Sepet'),
        ],
      ),
    );
  }
}

// ====== CATALOG w/ FILTER + SEARCH + SKELETON + CARD ANIM ======
class CatalogGrid extends StatefulWidget {
  final String title;
  final List<Product> products;
  const CatalogGrid({super.key, required this.title, required this.products});

  @override
  State<CatalogGrid> createState() => _CatalogGridState();
}

enum CoffeeFilter { all, milkBased, plain, cold }

class _CatalogGridState extends State<CatalogGrid> with AutomaticKeepAliveClientMixin {
  CoffeeFilter _coffeeFilter = CoffeeFilter.all;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Küçük bir gecikme ile skeleton göster
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  bool _isMilkBased(Product p) => p.optionGroups.any((g) => g.id == 'milk');

  bool _isCold(Product p) {
    final n = p.name.toLowerCase();
    final id = p.id.toLowerCase();
    return n.contains('cold') || n.contains('soğuk') || n.contains('iced') || id.contains('coldbrew');
  }

  bool _passesCoffeeFilter(Product p) {
    if (p.type != ProductType.coffee) return true; // Tatlı sayfasında filtre uygulama
    switch (_coffeeFilter) {
      case CoffeeFilter.all:
        return true;
      case CoffeeFilter.milkBased:
        return _isMilkBased(p);
      case CoffeeFilter.plain:
        return !_isMilkBased(p);
      case CoffeeFilter.cold:
        return _isCold(p);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isCoffeeTab = widget.products.isNotEmpty && widget.products.first.type == ProductType.coffee;

    // Arama + filtre
    final filtered = widget.products.where((p) {
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q);
      final matchesFilter = _passesCoffeeFilter(p);
      return matchesQuery && matchesFilter;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (isCoffeeTab) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tümü'),
                    selected: _coffeeFilter == CoffeeFilter.all,
                    onSelected: (_) => setState(() => _coffeeFilter = CoffeeFilter.all),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sütlü'),
                    selected: _coffeeFilter == CoffeeFilter.milkBased,
                    onSelected: (_) => setState(() => _coffeeFilter = CoffeeFilter.milkBased),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sade'),
                    selected: _coffeeFilter == CoffeeFilter.plain,
                    onSelected: (_) => setState(() => _coffeeFilter = CoffeeFilter.plain),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Soğuk'),
                    selected: _coffeeFilter == CoffeeFilter.cold,
                    onSelected: (_) => setState(() => _coffeeFilter = CoffeeFilter.cold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Ara',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _loading
                ? GridView.builder(
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .8,
              ),
              itemBuilder: (_, __) => const _SkeletonCard(),
            )
                : (filtered.isEmpty
                ? const Center(child: Text('Sonuç bulunamadı'))
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .8,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, i) => _AnimatedProductCard(product: filtered[i]),
            )),
          ),
        ],
      ),
    );
  }
}

// Kart skeleton’u
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: SkeletonBox(height: double.infinity, width: double.infinity)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 12, width: 120),
                SizedBox(height: 6),
                SkeletonBox(height: 10, width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mikro animasyonlu ürün kartı
class _AnimatedProductCard extends StatefulWidget {
  final Product product;
  const _AnimatedProductCard({required this.product});

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailPage(productId: p.id)),
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.98 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _pressed
                ? []
                : [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'img_${p.id}',
                    child: Image.asset(
                      p.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${p.basePrice.toStringAsFixed(2)} ₺', style: const TextStyle(color: Colors.brown)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ====== PRODUCT DETAIL ======
class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  SelectedOptions selections = const SelectedOptions();
  int quantity = 1;

  double _calcPrice(Product p) {
    double price = p.basePrice;
    for (final group in p.optionGroups) {
      if (group.singleChoice) {
        final selId = selections.singleChoices[group.id];
        if (selId != null) {
          final item = group.items.firstWhere((e) => e.id == selId);
          price += item.priceDelta ?? 0;
        }
      } else {
        final setIds = selections.multiChoices[group.id] ?? {};
        for (final id in setIds) {
          final item = group.items.firstWhere((e) => e.id == id);
          price += item.priceDelta ?? 0;
        }
      }
    }
    return price * (p.askQuantity ? quantity : 1);
  }

  bool _validateRequired(Product p, BuildContext context) {
    for (final g in p.optionGroups.where((g) => g.singleChoice)) {
      if (!selections.singleChoices.containsKey(g.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lütfen "${g.title}" için seçim yapın.')),
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final p = productIndex[widget.productId]!;

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Hero(
              tag: 'img_${p.id}',
              child: Image.asset(
                p.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(p.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Başlangıç fiyatı: ${p.basePrice.toStringAsFixed(2)} ₺'),
          const Divider(height: 24),

          // Opsiyon Grupları
          ...p.optionGroups.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (group.singleChoice)
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: group.items.map((item) {
                      final selected = selections.singleChoices[group.id] == item.id;
                      return ChoiceChip(
                        label: Text(item.priceDelta != null && item.priceDelta! > 0
                            ? '${item.name} (+${item.priceDelta!.toStringAsFixed(0)}₺)'
                            : item.name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            final map = Map<String, String>.from(selections.singleChoices);
                            map[group.id] = item.id;
                            selections = selections.copyWith(single: map);
                          });
                        },
                      );
                    }).toList(),
                  )
                else
                  Column(
                    children: group.items.map((item) {
                      final setIds = selections.multiChoices[group.id] ?? <String>{};
                      final checked = setIds.contains(item.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            final multi = selections.multiChoices.map((k, v) => MapEntry(k, Set.of(v)));
                            final set = multi[group.id] ?? <String>{};
                            if (v == true) set.add(item.id); else set.remove(item.id);
                            multi[group.id] = set;
                            selections = selections.copyWith(multi: multi);
                          });
                        },
                        title: Text(item.priceDelta != null && item.priceDelta! > 0
                            ? '${item.name} (+${item.priceDelta!.toStringAsFixed(0)}₺)'
                            : item.name),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),

          if (p.askQuantity) ...[
            const Text('Porsiyon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: quantity > 1 ? () => setState(() => quantity -= 1) : null,
                ),
                Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => quantity += 1),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Önizleme Fiyatı', style: Theme.of(context).textTheme.titleMedium),
              Text('${_calcPrice(p).toStringAsFixed(2)} ₺',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.brown)),
            ],
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Sepete Ekle'),
            onPressed: () {
              if (!_validateRequired(p, context)) return;
              final item = CartItem(
                productId: p.id,
                selections: selections,
                quantity: p.askQuantity ? quantity : 1,
              );
              ref.read(cartProvider.notifier).add(item);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sepete eklendi')),
              );
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ====== CART + CHECKOUT ======
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  String _subtitle(CartItem it) {
    final p = productIndex[it.productId]!;
    final parts = <String>[];
    for (final e in it.selections.singleChoices.entries) {
      final group = p.optionGroups.firstWhere(
            (g) => g.id == e.key,
        orElse: () => const OptionGroup(id: '', title: '', singleChoice: true, items: []),
      );
      if (group.id.isEmpty) continue;
      final item = group.items.firstWhere((x) => x.id == e.value, orElse: () => const OptionItem(id: '', name: ''));
      if (item.id.isNotEmpty) parts.add('${group.title}: ${item.name}');
    }
    for (final e in it.selections.multiChoices.entries) {
      final group = p.optionGroups.firstWhere(
            (g) => g.id == e.key,
        orElse: () => const OptionGroup(id: '', title: '', singleChoice: false, items: []),
      );
      if (group.id.isEmpty) continue;
      final names = e.value.map((id) => group.items.firstWhere((x) => x.id == id).name).join(', ');
      if (names.isNotEmpty) parts.add('${group.title}: $names');
    }
    final pAsk = p.askQuantity ? 'Porsiyon: ${it.quantity}' : 'Adet: ${it.quantity}';
    parts.add(pAsk);
    return parts.join(' • ');
  }

  double _itemTotal(CartItem it) {
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
    return price * it.quantity;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);

    double total = 0;
    for (final it in items) {
      total += _itemTotal(it);
    }

    if (items.isEmpty) {
      return const Center(child: Text('Sepetiniz boş'));
    }

    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final it = items[i];
              final p = productIndex[it.productId]!;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                visualDensity: VisualDensity.compact,
                minVerticalPadding: 6,
                leading: CircleAvatar(backgroundImage: AssetImage(p.imagePath)),
                title: Text(p.name),
                subtitle: Text(
                  _subtitle(it),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                trailing: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_itemTotal(it).toStringAsFixed(2)} ₺',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Kaldır',
                        onPressed: () => ref.read(cartProvider.notifier).removeAt(i),
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Toplam:', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${total.toStringAsFixed(2)} ₺',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.brown),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Ödemeyi Tamamla'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CheckoutPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});
  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  String delivery = 'pickup'; // 'pickup' | 'delivery'
  String payMethod = 'cash';  // 'cash' | 'card'

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  double _calcItemTotal(CartItem it) {
    final p = productIndex[it.productId]!;
    double price = p.basePrice;
    for (final g in p.optionGroups) {
      if (g.singleChoice) {
        final id = it.selections.singleChoices[g.id];
        if (id != null) {
          price += (g.items.firstWhere((e) => e.id == id).priceDelta ?? 0);
        }
      } else {
        for (final id in it.selections.multiChoices[g.id] ?? const <String>{}) {
          price += (g.items.firstWhere((e) => e.id == id).priceDelta ?? 0);
        }
      }
    }
    return price * it.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.fold<double>(0, (sum, it) => sum + _calcItemTotal(it));

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: SafeArea(
        child: _loading
            ? ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          itemBuilder: (_, i) {
            if (i < 3) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: const [
                    SkeletonBox(height: 48, width: 48, radius: BorderRadius.all(Radius.circular(24))),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonBox(height: 18, width: double.infinity)),
                    SizedBox(width: 12),
                    SkeletonBox(height: 16, width: 60),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonBox(height: 44, width: double.infinity, radius: BorderRadius.circular(8)),
            );
          },
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Sipariş Özeti', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...cart.map((it) {
              final p = productIndex[it.productId]!;
              final itemTotal = _calcItemTotal(it);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundImage: AssetImage(p.imagePath)),
                title: Text(p.name),
                subtitle: Text(p.askQuantity ? 'Porsiyon: ${it.quantity}' : 'Adet: ${it.quantity}'),
                trailing: Text('${itemTotal.toStringAsFixed(2)} ₺',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
            const Divider(height: 24),

            Text('Teslimat', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'pickup', groupValue: delivery,
              onChanged: (v) => setState(() => delivery = v!),
              title: const Text('Mağazadan Teslim (Pickup)'),
            ),
            RadioListTile<String>(
              value: 'delivery', groupValue: delivery,
              onChanged: (v) => setState(() => delivery = v!),
              title: const Text('Adrese Teslim'),
            ),
            const SizedBox(height: 8),

            Text('İletişim & Adres', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ad Soyad')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Telefon')),
            if (delivery == 'delivery') ...[
              const SizedBox(height: 8),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Adres'), maxLines: 2),
            ],
            const SizedBox(height: 8),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Sipariş Notu (opsiyonel)'), maxLines: 2),
            const Divider(height: 24),

            Text('Ödeme Yöntemi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'cash', groupValue: payMethod,
              onChanged: (v) => setState(() => payMethod = v!),
              title: const Text('Kapıda Nakit/Pos'),
            ),
            RadioListTile<String>(
              value: 'card', groupValue: payMethod,
              onChanged: (v) => setState(() => payMethod = v!),
              title: const Text('Kart (Mock)'),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Genel Toplam', style: Theme.of(context).textTheme.titleMedium),
                Text('${total.toStringAsFixed(2)} ₺',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.brown)),
              ],
            ),
            const SizedBox(height: 12),

            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Siparişi Onayla'),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen ad ve telefon girin.')),
                  );
                  return;
                }
                if (delivery == 'delivery' && addressCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teslimat için adres gerekli.')),
                  );
                  return;
                }

                final orderNo = DateTime.now().millisecondsSinceEpoch.toString();
                final userEmail = ref.read(authProvider)?.email; // null ise guest
                final userKey = OrderRepo.userKey(userEmail);

                final cartItems = List<CartItem>.from(ref.read(cartProvider));

                final order = Order(
                  id: orderNo,
                  createdAt: DateTime.now(),
                  items: cartItems,
                  total: total,
                  delivery: delivery,
                  payMethod: payMethod,
                  address: delivery == 'delivery' ? addressCtrl.text.trim() : null,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                );

                // HIVE yazımı bekle ve sonra navigate et
                await OrderRepo.addOrder(userKey, order);
                ref.read(cartProvider.notifier).clear();

                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: orderNo)),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  const OrderSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Sipariş Alındı')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 72),
                const SizedBox(height: 12),
                Text('Teşekkürler!', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('Sipariş numaran: $orderId'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Anasayfaya Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
