import 'models.dart';

// --- Opsiyon Grupları ---
const milkGroup = OptionGroup(
  id: 'milk',
  title: 'Süt Seçimi',
  singleChoice: true,
  items: [
    OptionItem(id: 'normal', name: 'Normal Süt'),
    OptionItem(id: 'lactosefree', name: 'Laktozsuz Süt', priceDelta: 5),
    OptionItem(id: 'oat', name: 'Yulaf Sütü', priceDelta: 7),
    OptionItem(id: 'almond', name: 'Badem Sütü', priceDelta: 8),
  ],
);

const sizeGroup = OptionGroup(
  id: 'size',
  title: 'Boy',
  singleChoice: true,
  items: [
    OptionItem(id: 's', name: 'Küçük'),
    OptionItem(id: 'm', name: 'Orta', priceDelta: 5),
    OptionItem(id: 'l', name: 'Büyük', priceDelta: 9),
  ],
);

const syrupGroup = OptionGroup(
  id: 'syrups',
  title: 'Şurup Ekle',
  singleChoice: false,
  items: [
    OptionItem(id: 'caramel', name: 'Karamel', priceDelta: 4),
    OptionItem(id: 'chocolate', name: 'Çikolata', priceDelta: 4),
    OptionItem(id: 'strawberry', name: 'Çilek', priceDelta: 4),
    OptionItem(id: 'vanilla', name: 'Vanilya', priceDelta: 4),
  ],
);

// --- Ürünler ---
const coffees = <Product>[
  // Sade, sütle iyi gider; boy ve şurup opsiyonel
  Product(
    id: 'coffee_filtre',
    name: 'Filtre Kahve',
    imagePath: 'assets/images/coffees/filtre.png',
    type: ProductType.coffee,
    basePrice: 35,
    optionGroups: [milkGroup, sizeGroup, syrupGroup],
  ),

  // Süt bazlı: süt + boy + (isteğe göre şurup)
  Product(
    id: 'coffee_latte',
    name: 'Latte',
    imagePath: 'assets/images/coffees/latte.png',
    type: ProductType.coffee,
    basePrice: 45,
    optionGroups: [milkGroup, sizeGroup, syrupGroup],
  ),

  // Süt yok; boy ve şurup uygun
  Product(
    id: 'coffee_americano',
    name: 'Americano',
    imagePath: 'assets/images/coffees/americano.png',
    type: ProductType.coffee,
    basePrice: 40,
    optionGroups: [sizeGroup, syrupGroup],
  ),

  // Süt köpüğü ağırlıklı; süt + boy mantıklı, şurup opsiyonel
  Product(
    id: 'coffee_cappuccino',
    name: 'Cappuccino',
    imagePath: 'assets/images/coffees/cappuccino.png',
    type: ProductType.coffee,
    basePrice: 48,
    optionGroups: [milkGroup, sizeGroup, syrupGroup],
  ),

  // Tek shot odaklı içim; boy var (s/m/l), şurup opsiyonel; süt yok
  Product(
    id: 'coffee_espresso',
    name: 'Espresso',
    imagePath: 'assets/images/coffees/espresso.png',
    type: ProductType.coffee,
    basePrice: 30,
    optionGroups: [sizeGroup, syrupGroup],
  ),

  // Espresso üstü az süt köpüğü; süt + boy mantıklı, şurup opsiyonel
  Product(
    id: 'coffee_macchiato',
    name: 'Macchiato',
    imagePath: 'assets/images/coffees/macchiato.png',
    type: ProductType.coffee,
    basePrice: 42,
    optionGroups: [milkGroup, sizeGroup, syrupGroup],
  ),

  // Çikolatalı süt bazlı; süt + boy + şurup (ek tatlandırma) uygun
  Product(
    id: 'coffee_mocha',
    name: 'Mocha',
    imagePath: 'assets/images/coffees/mocha.png',
    type: ProductType.coffee,
    basePrice: 50,
    optionGroups: [milkGroup, sizeGroup, syrupGroup],
  ),

  // Sütlü ama latte’den daha kahveli; süt + boy uygun, şurup opsiyonel
  Product(
    id: 'coffee_flatwhite',
    name: 'Flat White',
    imagePath: 'assets/images/coffees/flatwhite.png',
    type: ProductType.coffee,
    basePrice: 47,
    optionGroups: [milkGroup, sizeGroup, syrupGroup],
  ),

  // Soğuk demleme; süt ve şurup tercih edilebilir
  Product(
    id: 'coffee_coldbrew',
    name: 'Cold Brew',
    imagePath: 'assets/images/coffees/coldbrew.png',
    type: ProductType.coffee,
    basePrice: 55,
    optionGroups: [milkGroup, syrupGroup],
  ),

  // Geleneksel; süt/şurup genelde yok, sadece boy (fincan) mantıklı
  Product(
    id: 'coffee_turkish',
    name: 'Türk Kahvesi',
    imagePath: 'assets/images/coffees/turkish.png',
    type: ProductType.coffee,
    basePrice: 28,
    optionGroups: [sizeGroup],
  ),
];

const desserts = <Product>[
  Product(
    id: 'dessert_kremali_havuc',
    name: 'Kremalı Havuçlu Tatlı',
    imagePath: 'assets/images/desserts/kremalihavuc.png',
    type: ProductType.dessert,
    basePrice: 30,
    askQuantity: true,
  ),
  Product(
    id: 'dessert_cheesecake',
    name: 'Cheesecake',
    imagePath: 'assets/images/desserts/cheesecake.png',
    type: ProductType.dessert,
    basePrice: 38,
    askQuantity: true,
  ),
  Product(
    id: 'dessert_tiramisu',
    name: 'Tiramisu',
    imagePath: 'assets/images/desserts/tiramisu.png',
    type: ProductType.dessert,
    basePrice: 42,
    askQuantity: true,
  ),
  Product(
    id: 'dessert_mozaik',
    name: 'Mozaik Pasta',
    imagePath: 'assets/images/desserts/mozaik.png',
    type: ProductType.dessert,
    basePrice: 28,
    askQuantity: true,
  ),
  Product(
    id: 'dessert_magnolia',
    name: 'Magnolia',
    imagePath: 'assets/images/desserts/magnolia.png',
    type: ProductType.dessert,
    basePrice: 35,
    askQuantity: true,
  ),
  Product(
    id: 'dessert_brownie',
    name: 'Brownie',
    imagePath: 'assets/images/desserts/brownie.png',
    type: ProductType.dessert,
    basePrice: 34,
    askQuantity: true,
  ),
  Product(
    id: 'dessert_suffle',
    name: 'Sufle',
    imagePath: 'assets/images/desserts/suffle.png',
    type: ProductType.dessert,
    basePrice: 36,
    askQuantity: true,
  ),
  Product(
    id: 'dessert_kunefe',
    name: 'Künefe',
    imagePath: 'assets/images/desserts/kunefe.png',
    type: ProductType.dessert,
    basePrice: 45,
    askQuantity: true,
  ),
  Product(
    id: 'dessert_profiterol',
    name: 'Profiterol',
    imagePath: 'assets/images/desserts/profiterol.png',
    type: ProductType.dessert,
    basePrice: 37,
    askQuantity: true,
  ),
  Product(
    id: 'dessert_san_sebastian',
    name: 'San Sebastian',
    imagePath: 'assets/images/desserts/sansebastian.png',
    type: ProductType.dessert,
    basePrice: 48,
    askQuantity: true,
  ),
];


List<Product> get allProducts => [...coffees, ...desserts];
final Map<String, Product> productIndex = {for (final p in allProducts) p.id: p};