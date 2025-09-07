import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_notifier.dart';
import 'order_repo.dart';
import 'models.dart';
import 'data.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  String _subtitleForItem(CartItem it) {
    final p = productIndex[it.productId]!;
    final parts = <String>[];
    for (final e in it.selections.singleChoices.entries) {
      final g = p.optionGroups.firstWhere((x) => x.id == e.key, orElse: () =>
      const OptionGroup(id: '', title: '', singleChoice: true, items: []));
      if (g.id.isEmpty) continue;
      final item = g.items.firstWhere((x) => x.id == e.value, orElse: () => const OptionItem(id: '', name: ''));
      if (item.id.isNotEmpty) parts.add('${g.title}: ${item.name}');
    }
    for (final e in it.selections.multiChoices.entries) {
      final g = p.optionGroups.firstWhere((x) => x.id == e.key, orElse: () =>
      const OptionGroup(id: '', title: '', singleChoice: false, items: []));
      if (g.id.isEmpty) continue;
      final names = e.value.map((id) => g.items.firstWhere((x) => x.id == id).name).join(', ');
      if (names.isNotEmpty) parts.add('${g.title}: $names');
    }
    if (p.askQuantity) parts.add('Porsiyon: ${it.quantity}');
    return parts.isEmpty ? 'Kişiselleştirme yok' : parts.join(' • ');
  }

  double _itemTotal(CartItem it) {
    final p = productIndex[it.productId]!;
    double price = p.basePrice;
    for (final g in p.optionGroups) {
      if (g.singleChoice) {
        final id = it.selections.singleChoices[g.id];
        if (id != null) price += (g.items.firstWhere((e) => e.id == id).priceDelta ?? 0);
      } else {
        for (final id in it.selections.multiChoices[g.id] ?? const <String>{}) {
          price += (g.items.firstWhere((e) => e.id == id).priceDelta ?? 0);
        }
      }
    }
    return price * it.quantity;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final key = OrderRepo.userKey(user?.email);
    final orders = OrderRepo.listOrders(key);

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Misafir', style: Theme.of(context).textTheme.titleMedium),
                      Text(user?.email ?? '-', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            Text('Sipariş Geçmişi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            if (orders.isEmpty)
              const Text('Henüz siparişiniz yok.')
            else
              ...orders.map((o) {
                return Card(
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text('Sipariş #${o.id}'),
                    subtitle: Text(
                      '${o.createdAt.toLocal()} • ${o.total.toStringAsFixed(2)} ₺',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      Column(
                        children: o.items.map((it) {
                          final p = productIndex[it.productId]!;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(backgroundImage: AssetImage(p.imagePath)),
                            title: Text(p.name),
                            subtitle: Text(_subtitleForItem(it), maxLines: 3, overflow: TextOverflow.ellipsis),
                            trailing: Text('${_itemTotal(it).toStringAsFixed(2)} ₺',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Teslimat: ${o.delivery == 'delivery' ? 'Adrese Teslim' : 'Pickup'}'),
                          Text('Ödeme: ${o.payMethod == 'card' ? 'Kart' : 'Nakit/Pos'}'),
                        ],
                      ),
                      if (o.address != null && o.address!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Adres: ${o.address!}'),
                      ],
                      if (o.note != null && o.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Not: ${o.note!}'),
                      ],
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Toplam: ${o.total.toStringAsFixed(2)} ₺',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Çıkış yapıldı')));
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
