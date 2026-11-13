import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShopEaseApp());
}

class Product {
  final int id;
  final String name, category, emoji, description;
  final double price;
  const Product(this.id, this.name, this.category, this.emoji, this.price, this.description);
}

const catalog = <Product>[
  Product(1, 'AirBeat Pro Headphones', 'Electronics', '🎧', 2499, 'Wireless headphones with immersive sound and comfortable ear cups.'),
  Product(2, 'Everyday Backpack', 'Fashion', '🎒', 1299, 'A lightweight backpack with practical storage.'),
  Product(3, 'Smart Watch Series X', 'Electronics', '⌚', 3299, 'Track daily activity and stay connected.'),
  Product(4, 'Cloud Comfort Sneakers', 'Fashion', '👟', 1899, 'Comfortable sneakers for everyday styling.'),
  Product(5, 'Ceramic Coffee Set', 'Home', '☕', 899, 'A modern ceramic cup set for your coffee corner.'),
  Product(6, 'Desk Glow Lamp', 'Home', '💡', 1499, 'Warm desk lighting for reading and studying.'),
  Product(7, 'Daily Care Kit', 'Beauty', '🧴', 699, 'A simple self-care kit for everyday use.'),
  Product(8, 'Minimal Travel Bottle', 'Home', '🧋', 499, 'A reusable bottle for daily commutes and travel.'),
];

class ShopEaseApp extends StatefulWidget {
  const ShopEaseApp({super.key});
  @override
  State<ShopEaseApp> createState() => _ShopEaseAppState();
}

class _ShopEaseAppState extends State<ShopEaseApp> {
  final Map<int, int> cart = {};
  final Set<int> saved = {};
  bool loading = true, loggedIn = false;
  int tab = 0;
  String search = '', category = 'All', sort = 'Featured';

  @override
  void initState() { super.initState(); _restore(); }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    for (final item in prefs.getStringList('cart') ?? <String>[]) {
      final pair = item.split(':');
      if (pair.length == 2) cart[int.parse(pair[0])] = int.parse(pair[1]);
    }
    saved.addAll((prefs.getStringList('saved') ?? <String>[]).map(int.parse));
    if (mounted) setState(() => loading = false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cart', cart.entries.map((e) => e.key.toString() + ':' + e.value.toString()).toList());
    await prefs.setStringList('saved', saved.map((e) => e.toString()).toList());
  }

  void add(Product p) { setState(() => cart[p.id] = (cart[p.id] ?? 0) + 1); _persist(); }
  void remove(Product p) {
    setState(() {
      final n = cart[p.id] ?? 0;
      if (n <= 1) { cart.remove(p.id); } else { cart[p.id] = n - 1; }
    });
    _persist();
  }
  void toggleSaved(Product p) {
    setState(() { if (!saved.add(p.id)) saved.remove(p.id); });
    _persist();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ShopEase', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457D6)), scaffoldBackgroundColor: const Color(0xFFF7F8FC)),
    home: loading ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : !loggedIn ? LoginPage(onDone: () => setState(() => loggedIn = true))
      : _buildShop(),
  );

  Widget _buildShop() {
    final filtered = catalog.where((p) =>
      (p.name.toLowerCase().contains(search.toLowerCase()) || p.category.toLowerCase().contains(search.toLowerCase())) &&
      (category == 'All' || p.category == category)).toList();
    if (sort == 'Price: Low to High') filtered.sort((a, b) => a.price.compareTo(b.price));
    if (sort == 'Price: High to Low') filtered.sort((a, b) => b.price.compareTo(a.price));
    final pages = <Widget>[
      HomePage(items: filtered, search: search, category: category, sort: sort,
        onSearch: (v) => setState(() => search = v), onCategory: (v) => setState(() => category = v),
        onSort: (v) => setState(() => sort = v), saved: saved, onSave: toggleSaved, onAdd: add, onOpen: openProduct),
      SavedPage(items: catalog.where((p) => saved.contains(p.id)).toList(), saved: saved, onSave: toggleSaved, onAdd: add, onOpen: openProduct),
      CartPage(cart: cart, onAdd: add, onRemove: remove),
      ProfilePage(onSignOut: () => setState(() { loggedIn = false; tab = 0; })),
    ];
    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Badge(isLabelVisible: saved.isNotEmpty, child: const Icon(Icons.favorite_border)), label: 'Saved'),
          NavigationDestination(icon: Badge(isLabelVisible: cart.isNotEmpty, label: Text(cart.values.fold<int>(0, (a, b) => a + b).toString()), child: const Icon(Icons.shopping_bag_outlined)), label: 'Cart'),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ]),
    );
  }

  void openProduct(Product p) => Navigator.push(context, MaterialPageRoute(builder: (_) =>
    DetailPage(product: p, isSaved: saved.contains(p.id), onSave: () => toggleSaved(p), onAdd: () => add(p))));
}

class LoginPage extends StatefulWidget {
  final VoidCallback onDone;
  const LoginPage({super.key, required this.onDone});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final keyForm = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool hide = true, signup = false;
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
      child: Form(key: keyForm, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CircleAvatar(radius: 32, child: Icon(Icons.shopping_bag, size: 32)),
        const SizedBox(height: 24),
        Text(signup ? 'Create your account' : 'Welcome to ShopEase', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8), const Text('Your everyday shopping, made simpler.'),
        const SizedBox(height: 28),
        TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
          validator: (v) => v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim()) ? 'Enter a valid email' : null),
        const SizedBox(height: 16),
        TextFormField(controller: password, obscureText: hide,
          decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility : Icons.visibility_off))),
          validator: (v) => v == null || v.length < 6 ? 'Use at least 6 characters' : null),
        const SizedBox(height: 22),
        SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: () { if (keyForm.currentState!.validate()) widget.onDone(); }, child: Text(signup ? 'Sign up' : 'Sign in'))),
        Center(child: TextButton(onPressed: () => setState(() => signup = !signup), child: Text(signup ? 'Already registered? Sign in' : 'New here? Create an account'))),
        Center(child: TextButton(onPressed: widget.onDone, child: const Text('Continue as guest'))),
        const Center(child: Text('Demo only • No account is created', style: TextStyle(fontSize: 12, color: Colors.blueGrey))),
      ])),
    ),
  ))));
}

class HomePage extends StatelessWidget {
  final List<Product> items;
  final String search, category, sort;
  final ValueChanged<String> onSearch, onCategory, onSort;
  final Set<int> saved;
  final ValueChanged<Product> onSave, onAdd, onOpen;
  const HomePage({super.key, required this.items, required this.search, required this.category, required this.sort, required this.onSearch, required this.onCategory, required this.onSort, required this.saved, required this.onSave, required this.onAdd, required this.onOpen});
  @override
  Widget build(BuildContext context) => SafeArea(child: CustomScrollView(slivers: [
    SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ShopEase', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const Text('Find something you will love', style: TextStyle(color: Colors.blueGrey)),
      const SizedBox(height: 18),
      TextField(onChanged: onSearch, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search products')),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: sort, decoration: const InputDecoration(labelText: 'Sort by'),
        items: const ['Featured', 'Price: Low to High', 'Price: High to Low'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) { if (v != null) onSort(v); }),
      const SizedBox(height: 12),
      SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: ['All', 'Electronics', 'Fashion', 'Home', 'Beauty'].map((v) =>
        Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(v), selected: category == v, onSelected: (_) => onCategory(v)))).toList())),
      Text(items.length.toString() + ' products', style: const TextStyle(fontWeight: FontWeight.bold)),
    ]))),
    if (items.isEmpty) const SliverFillRemaining(child: Center(child: Text('No products found')))
    else SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), sliver: SliverGrid(
      delegate: SliverChildBuilderDelegate((c, i) => ProductCard(product: items[i], isSaved: saved.contains(items[i].id),
        onTap: () => onOpen(items[i]), onSave: () => onSave(items[i]), onAdd: () => onAdd(items[i])), childCount: items.length),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .68))),
  ]));
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isSaved;
  final VoidCallback onTap, onSave, onAdd;
  const ProductCard({super.key, required this.product, required this.isSaved, required this.onTap, required this.onSave, required this.onAdd});
  @override
  Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(18), child: InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Stack(children: [
        Container(width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFE9EEFF), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 54)))),
        Positioned(right: 0, top: 0, child: IconButton(onPressed: onSave, icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? Colors.red : Colors.blueGrey))),
      ])),
      const SizedBox(height: 8), Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4), Text('₹' + product.price.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2457D6))),
      const SizedBox(height: 6), SizedBox(width: double.infinity, height: 34, child: OutlinedButton(onPressed: onAdd, child: const Text('Add to cart'))),
    ]))));
}

class DetailPage extends StatelessWidget {
  final Product product;
  final bool isSaved;
  final VoidCallback onSave, onAdd;
  const DetailPage({super.key, required this.product, required this.isSaved, required this.onSave, required this.onAdd});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Product details')),
    body: Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
        Container(height: 260, decoration: BoxDecoration(color: const Color(0xFFE9EEFF), borderRadius: BorderRadius.circular(24)), child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 110)))),
        const SizedBox(height: 20), Text(product.category.toUpperCase(), style: const TextStyle(color: Color(0xFF2457D6), fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), Text(product.name, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12), Text('₹' + product.price.toStringAsFixed(0), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2457D6))),
        const SizedBox(height: 18), const Text('About this product', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), Text(product.description),
        const SizedBox(height: 18), OutlinedButton.icon(onPressed: onSave, icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border), label: const Text('Save to favourites')),
      ])),
      SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 52,
        child: FilledButton.icon(onPressed: () { onAdd(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart'))); }, icon: const Icon(Icons.shopping_bag_outlined), label: const Text('Add to cart'))))),
    ]));
}

class SavedPage extends StatelessWidget {
  final List<Product> items;
  final Set<int> saved;
  final ValueChanged<Product> onSave, onAdd, onOpen;
  const SavedPage({super.key, required this.items, required this.saved, required this.onSave, required this.onAdd, required this.onOpen});
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Saved items', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const Text('Products you want to revisit', style: TextStyle(color: Colors.blueGrey)),
    const SizedBox(height: 18),
    if (items.isEmpty) const Expanded(child: Center(child: Text('No saved products yet. Tap a heart to save one.')))
    else Expanded(child: GridView.builder(itemCount: items.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .68),
      itemBuilder: (c, i) => ProductCard(product: items[i], isSaved: saved.contains(items[i].id), onTap: () => onOpen(items[i]), onSave: () => onSave(items[i]), onAdd: () => onAdd(items[i])))),
  ])));
}

class CartPage extends StatelessWidget {
  final Map<int, int> cart;
  final ValueChanged<Product> onAdd, onRemove;
  const CartPage({super.key, required this.cart, required this.onAdd, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    final items = catalog.where((p) => (cart[p.id] ?? 0) > 0).toList();
    final total = items.fold<double>(0, (sum, p) => sum + p.price * (cart[p.id] ?? 0));
    return SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your cart', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      Text(items.length.toString() + ' different products', style: const TextStyle(color: Colors.blueGrey)),
      const SizedBox(height: 18),
      if (items.isEmpty) const Expanded(child: Center(child: Text('Your cart is empty')))
      else Expanded(child: ListView(children: [
        ...items.map((p) => Card(color: Colors.white, child: ListTile(
          leading: CircleAvatar(child: Text(p.emoji)), title: Text(p.name),
          subtitle: Text('₹' + p.price.toStringAsFixed(0) + '  •  Qty ' + cart[p.id].toString()),
          trailing: Wrap(mainAxisSize: MainAxisSize.min, children: [
            IconButton(onPressed: () => onRemove(p), icon: const Icon(Icons.remove_circle_outline)),
            IconButton(onPressed: () => onAdd(p), icon: const Icon(Icons.add_circle_outline)),
          ]),
        ))),
        Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('₹' + total.toStringAsFixed(0))]),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), Text('₹' + total.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20))]),
          const SizedBox(height: 10), const Text('Checkout preview only. No payment is collected.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
        ]))),
      ])),
    ])));
  }
}

class ProfilePage extends StatelessWidget {
  final VoidCallback onSignOut;
  const ProfilePage({super.key, required this.onSignOut});
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Your profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const SizedBox(height: 24), const Center(child: CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42))),
    const SizedBox(height: 12), const Center(child: Text('ShopEase Guest', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
    const Center(child: Text('Demo shopper account', style: TextStyle(color: Colors.blueGrey))),
    const SizedBox(height: 24), const ListTile(leading: Icon(Icons.local_shipping_outlined), title: Text('Delivery information'), subtitle: Text('Checkout is a demo preview')),
    const ListTile(leading: Icon(Icons.help_outline), title: Text('Help & support'), subtitle: Text('ShopEase sample application')),
    const Spacer(), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onSignOut, icon: const Icon(Icons.logout), label: const Text('Sign out'))),
  ])));
}
