import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../widgets/widgets.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    if (user?.isAdmin == true) return child;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Access')),
      body: EmptyState(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Admin access required',
        subtitle: 'Only MOSPL admin accounts can view dashboard, products, orders, users, analytics, and settings.',
        actionLabel: 'Go to Home',
        onAction: () => context.go('/home'),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final metrics = state.adminMetrics;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(onPressed: () => context.read<AppState>().loadAdminData(), icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => context.go('/home'), icon: const Icon(Icons.storefront_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.55,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              MetricCard(title: 'Revenue', value: inr(metrics?.revenue ?? state.totalRevenue), icon: Icons.currency_rupee),
              MetricCard(title: 'Products', value: '${metrics?.products ?? state.allProducts.length}', icon: Icons.inventory_2_outlined),
              MetricCard(title: 'Orders', value: '${metrics?.orders ?? state.orders.length}', icon: Icons.receipt_long_outlined),
              MetricCard(title: 'Low Stock', value: '${metrics?.lowStock ?? state.lowStockCount}', icon: Icons.warning_amber_outlined, color: const Color(0xffff9800)),
            ],
          ),
          const SizedBox(height: 14),
          _AdminChartCard(title: 'Weekly Sales', chart: _salesBarChart(state.revenueByDay)),
          const SizedBox(height: 14),
          Text('Store Management', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _adminLink(context, 'Products', Icons.inventory_2_outlined, '/admin/products'),
          _adminLink(context, 'Categories', Icons.category_outlined, '/admin/categories'),
          _adminLink(context, 'Daily Offers', Icons.local_offer_outlined, '/admin/daily-offers'),
          _adminLink(context, 'Orders', Icons.receipt_long_outlined, '/admin/orders'),
          _adminLink(context, 'Users', Icons.people_outline, '/admin/users'),
          _adminLink(context, 'Reviews', Icons.rate_review_outlined, '/admin/reviews'),
          _adminLink(context, 'Returns', Icons.assignment_return_outlined, '/admin/returns'),
          _adminLink(context, 'Sales Charts', Icons.show_chart, '/admin/sales-charts'),
          const SectionHeader(title: 'Recent Orders'),
          if (state.orders.isEmpty)
            const Text('No orders yet. Place a test order from the customer app.')
          else
            ...state.orders.take(5).map(
                  (order) => _AdminOrderStatusCard(order: order),
                ),
        ],
      ),
    );
  }

  Widget _adminLink(BuildContext context, String title, IconData icon, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }

  Widget _salesBarChart(List<int> revenueByDay) {
    final values = revenueByDay.isEmpty ? List.generate(7, (index) => (index + 2) * 1200) : revenueByDay;
    final maxVal = values.fold<double>(0.0, (max, val) => val > max ? val.toDouble() : max);
    final calculatedMaxY = maxVal == 0.0 ? 1000.0 : maxVal;
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: calculatedMaxY,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(leftTitles: AxisTitles(), topTitles: AxisTitles(), rightTitles: AxisTitles()),
        barGroups: List.generate(values.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: values[index].toDouble(), width: 14, borderRadius: BorderRadius.circular(4)),
            ],
          );
        }),
      ),
    );
  }
}

class _AdminChartCard extends StatelessWidget {
  const _AdminChartCard({required this.title, required this.chart});

  final String title;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            SizedBox(height: 190, child: chart),
          ],
        ),
      ),
    );
  }
}

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<AppState>().allProducts;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/products/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            child: ListTile(
              leading: SizedBox(width: 54, height: 54, child: ProductImage(url: product.thumbnail, fit: BoxFit.contain)),
              title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${product.sku} • Stock ${product.stock} • ${product.priceLabel}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') context.push('/admin/products/edit/${product.productId}');
                  if (value == 'stock') _showStockDialog(context, product);
                  if (value == 'delete') context.read<AppState>().deleteProduct(product.productId);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'stock', child: Text('Update Stock')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStockDialog(BuildContext context, Product product) {
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    showDialog<void>(
      context: context,
      builder: (_) => _StockDialog(
        product: product,
        messenger: messenger,
        onConfirm: (val) => appState.updateInventoryStock(
          productId: product.productId,
          stock: val,
        ),
      ),
    );
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late Product? _editing;
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _oldPrice;
  late final TextEditingController _customDiscount;
  late final TextEditingController _stock;
  late final TextEditingController _sourceUrl;
  late final TextEditingController _description;

  late final TextEditingController _specHeight;
  late final TextEditingController _specWidth;
  late final TextEditingController _specClosureType;
  late final TextEditingController _specStitching;
  late final TextEditingController _specCompartments;
  late final TextEditingController _specCardSlots;
  late final TextEditingController _specPockets;
  late final TextEditingController _specPattern;
  late final TextEditingController _specColor;
  late final TextEditingController _specMaterial;

  late final String _productId;
  final List<String?> _images = List.filled(5, null);
  final List<bool> _uploading = List.filled(5, false);

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _editing = widget.productId == null ? null : state.productById(widget.productId!);
    final sample = _editing ?? state.allProducts.first;
    
    _productId = _editing?.productId ?? 'MOSPL-ADMIN-${DateTime.now().millisecondsSinceEpoch}';
    
    _name = TextEditingController(text: _editing?.name ?? 'MOSPL Custom Leather Product');
    _category = TextEditingController(text: _editing?.category ?? 'Men Wallets');
    _price = TextEditingController(text: (_editing?.price ?? 595).toString());
    _oldPrice = TextEditingController(text: (_editing?.oldPrice ?? 850).toString());
    _customDiscount = TextEditingController(text: (_editing?.customDiscount ?? 0).toString());
    _stock = TextEditingController(text: (_editing?.stock ?? 25).toString());
    _sourceUrl = TextEditingController(text: _editing?.sourceUrl ?? 'Not Specified');
    _description = TextEditingController(text: _editing?.description ?? sample.description);

    final specs = _editing?.specifications ?? {};
    _specHeight = TextEditingController(text: specs['Height'] ?? '90 mm');
    _specWidth = TextEditingController(text: specs['Width'] ?? '120 mm');
    _specClosureType = TextEditingController(text: specs['Closure Type'] ?? 'Flap');
    _specStitching = TextEditingController(text: specs['Stitching'] ?? 'Double Stitch');
    _specCompartments = TextEditingController(text: specs['No. of Compartments'] ?? '2');
    _specCardSlots = TextEditingController(text: specs['Card Slots'] ?? '7');
    _specPockets = TextEditingController(text: specs['No. of Pocket'] ?? '3');
    _specPattern = TextEditingController(text: specs['Pattern'] ?? 'Brand Embossed');
    _specColor = TextEditingController(text: specs['Color'] ?? _editing?.color ?? 'Black');
    _specMaterial = TextEditingController(text: specs['Material'] ?? _editing?.material ?? 'Genuine Leather');

    if (_editing != null) {
      final gallery = _editing!.galleryImages;
      for (int i = 0; i < 5; i++) {
        if (i < gallery.length) {
          _images[i] = gallery[i];
        }
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _oldPrice.dispose();
    _customDiscount.dispose();
    _stock.dispose();
    _sourceUrl.dispose();
    _description.dispose();

    _specHeight.dispose();
    _specWidth.dispose();
    _specClosureType.dispose();
    _specStitching.dispose();
    _specCompartments.dispose();
    _specCardSlots.dispose();
    _specPockets.dispose();
    _specPattern.dispose();
    _specColor.dispose();
    _specMaterial.dispose();

    super.dispose();
  }  Future<void> _pickAndUploadImage(int index) async {
    try {
      final picker = image_picker.ImagePicker();
      final image = await picker.pickImage(
        source: image_picker.ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );
      if (image == null) return;

      setState(() {
        _uploading[index] = true;
      });

      final bytes = await image.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64.encode(bytes)}';

      setState(() {
        _images[index] = base64Str;
        _uploading[index] = false;
      });
    } catch (e) {
      setState(() {
        _uploading[index] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $e')),
      );
    }
  }

  Widget _buildImageSlot(int index) {
    final imageUrl = _images[index];
    final isUploading = _uploading[index];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            Positioned.fill(
              child: ProductImage(
                url: imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _images[index] = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ] else if (isUploading) ...[
            const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => _pickAndUploadImage(index),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400),
                  const SizedBox(height: 4),
                  Text(
                    'Image ${index + 1}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sample = _editing ?? context.read<AppState>().allProducts.first;
    return Scaffold(
      appBar: AppBar(title: Text(_editing == null ? 'Add Product' : 'Edit Product')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_name, 'Product name', Icons.inventory_2_outlined),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: ['Men Wallets', 'Passport Holders', 'Men Belts', 'Women Wallets'].contains(_category.text)
                  ? _category.text
                  : 'Men Wallets',
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
                labelText: 'Category',
              ),
              items: ['Men Wallets', 'Passport Holders', 'Men Belts', 'Women Wallets']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  _category.text = val;
                }
              },
            ),
          ),
          Row(
            children: [
              Expanded(child: _field(_price, 'Price', Icons.currency_rupee, keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _field(_oldPrice, 'Old price', Icons.money_off, keyboard: TextInputType.number)),
            ],
          ),
          _field(
            _customDiscount,
            'Discount % (Optional override)',
            Icons.percent_outlined,
            keyboard: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              PercentLimitTextInputFormatter(),
            ],
          ),
          _field(
            _stock,
            'Stock',
            Icons.warehouse_outlined,
            keyboard: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              StockLimitTextInputFormatter(),
            ],
          ),
          _field(_sourceUrl, 'Source URL', Icons.open_in_new),
          _field(_description, 'Description', Icons.description_outlined, maxLines: 4),
          const SizedBox(height: 16),
          Text(
            'Product Specifications',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _field(_specHeight, 'Height (e.g. 90 mm)', Icons.height),
          _field(_specWidth, 'Width (e.g. 120 mm)', Icons.straighten),
          _field(
            _specClosureType,
            'Closure Type (e.g. Flap)',
            Icons.lock_outline,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))],
          ),
          _field(
            _specStitching,
            'Stitching (e.g. Double Stitch)',
            Icons.gesture,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))],
          ),
          _field(
            _specCompartments,
            'No. of Compartments (e.g. 2)',
            Icons.grid_view,
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _field(
            _specCardSlots,
            'Card Slots (e.g. 7)',
            Icons.credit_card,
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _field(
            _specPockets,
            'No. of Pockets (e.g. 3)',
            Icons.folder_open,
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          _field(
            _specPattern,
            'Pattern (e.g. Brand Embossed)',
            Icons.texture,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))],
          ),
          _field(
            _specColor,
            'Color (e.g. Black)',
            Icons.color_lens_outlined,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))],
          ),
          _field(
            _specMaterial,
            'Material (e.g. Genuine Leather)',
            Icons.gavel_outlined,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))],
          ),
          const SizedBox(height: 16),
          Text(
            'Product Images (5 slots)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildImageSlot(index);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final stockVal = int.tryParse(_stock.text) ?? sample.stock;
              if (stockVal > 30) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('you cannot update more than 30')),
                );
                return;
              }
              final oldPrice = int.tryParse(_oldPrice.text) ?? sample.oldPrice;
              final customDiscount = int.tryParse(_customDiscount.text) ?? 0;
              var price = int.tryParse(_price.text) ?? sample.price;
              if (customDiscount > 0) {
                price = oldPrice - (oldPrice * customDiscount / 100).round();
              }

              final nonNullableImages = _images.where((img) => img != null && img.isNotEmpty).toList();
              if (nonNullableImages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('atleast single image must be uploaded')),
                );
                return;
              }

              final wordsRegex = RegExp(r'[0-9]');
              if (wordsRegex.hasMatch(_specClosureType.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Closure Type must not contain numbers')),
                );
                return;
              }
              if (wordsRegex.hasMatch(_specStitching.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stitching must not contain numbers')),
                );
                return;
              }
              if (wordsRegex.hasMatch(_specPattern.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pattern must not contain numbers')),
                );
                return;
              }
              if (wordsRegex.hasMatch(_specColor.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Color must not contain numbers')),
                );
                return;
              }
              if (wordsRegex.hasMatch(_specMaterial.text)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Material must not contain numbers')),
                );
                return;
              }

              final numbersRegex = RegExp(r'^\d+$');
              if (!numbersRegex.hasMatch(_specCompartments.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No. of Compartments must contain only numbers')),
                );
                return;
              }
              if (!numbersRegex.hasMatch(_specCardSlots.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card Slots must contain only numbers')),
                );
                return;
              }
              if (!numbersRegex.hasMatch(_specPockets.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No. of Pockets must contain only numbers')),
                );
                return;
              }

              final specifications = {
                ...(_editing?.specifications ?? {}),
                'Height': _specHeight.text.trim(),
                'Width': _specWidth.text.trim(),
                'Closure Type': _specClosureType.text.trim(),
                'Stitching': _specStitching.text.trim(),
                'No. of Compartments': _specCompartments.text.trim(),
                'Card Slots': _specCardSlots.text.trim(),
                'No. of Pocket': _specPockets.text.trim(),
                'Pattern': _specPattern.text.trim(),
                'Color': _specColor.text.trim(),
                'Material': _specMaterial.text.trim(),
                'Stock': stockVal.toString(),
              };

              final product = sample.copyWith(
                productId: _productId,
                name: _name.text.trim(),
                category: _category.text.trim(),
                subcategory: _category.text.trim(),
                price: price,
                oldPrice: oldPrice,
                customDiscount: customDiscount,
                discountPercentage: customDiscount > 0
                    ? customDiscount
                    : (oldPrice > 0 ? ((oldPrice - price) * 100 / oldPrice).round() : 0),
                stock: stockVal,
                shortDescription: _description.text.trim(),
                description: _description.text.trim(),
                sourceUrl: _sourceUrl.text.trim().isEmpty ? 'Not Specified' : _sourceUrl.text.trim(),
                sku: _editing?.sku ?? 'ADMIN-${DateTime.now().millisecondsSinceEpoch}',
                thumbnail: nonNullableImages.first!,
                galleryImages: nonNullableImages.cast<String>().toList(),
                color: _specColor.text.trim(),
                material: _specMaterial.text.trim(),
                size: '${_specHeight.text.trim()} x ${_specWidth.text.trim()}',
                specifications: specifications,
                createdAt: _editing?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              context.pop();
              context.read<AppState>().upsertProduct(product);
            },
            child: const Text('Save Product'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      ),
    );
  }
}

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppState>().categories;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Categories')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => CategoryTile(category: categories[index]),
      ),
    );
  }
}

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppState>().orders;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Orders'),
        actions: [
          IconButton(onPressed: () => context.read<AppState>().loadAdminData(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: orders.isEmpty
          ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'No orders', subtitle: 'Customer orders will appear here.')
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _AdminOrderStatusCard(order: orders[index]),
            ),
    );
  }
}

class _AdminOrderStatusCard extends StatelessWidget {
  const _AdminOrderStatusCard({required this.order});

  final AppOrder order;

  static const _statusSteps = ['Confirmed', 'Packed', 'Shipped', 'Delivered'];

  Color _stepColor(BuildContext context, int stepIndex) {
    if (order.status == 'Cancelled') return Colors.grey.shade300;
    final currentIndex = _statusSteps.indexOf(order.status);
    if (stepIndex <= currentIndex) return const Color(0xff12833b);
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _statusSteps.indexOf(order.status);
    final isPaid = order.paymentStatus == 'Paid';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        '${order.items.length} item${order.items.length == 1 ? '' : 's'} • ${order.address.city} • ${order.paymentMethod}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(order.totalLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPaid ? const Color(0xffe8f5e9) : const Color(0xfffff3e0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.paymentStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPaid ? const Color(0xff12833b) : const Color(0xffe65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status stepper
            Row(
              children: List.generate(_statusSteps.length, (index) {
                final isActive = index <= currentIndex;
                final isLast = index == _statusSteps.length - 1;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: _stepColor(context, index),
                              child: Icon(
                                isActive ? Icons.check : Icons.circle,
                                size: 12,
                                color: isActive ? Colors.white : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _statusSteps[index],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                color: isActive ? const Color(0xff12833b) : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 18),
                            color: index < currentIndex ? const Color(0xff12833b) : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Action buttons – only show next possible statuses
            Wrap(
              spacing: 8,
              children: [
                if (order.status != 'Cancelled') ...[
                  if (currentIndex < 1)
                    _actionChip(
                      context,
                      label: '✓ Mark Packed',
                      color: const Color(0xff1565c0),
                      onTap: () => _updateStatus(context, 'Packed'),
                    ),
                  if (currentIndex < 2)
                    _actionChip(
                      context,
                      label: '✓ Mark Shipped',
                      color: const Color(0xff6a1b9a),
                      onTap: () => _updateStatus(context, 'Shipped'),
                    ),
                  if (currentIndex < 3)
                    _actionChip(
                      context,
                      label: '✓ Mark Delivered',
                      color: const Color(0xff12833b),
                      onTap: () => _updateStatus(context, 'Delivered'),
                    ),
                ],
                if (order.status != 'Delivered' && order.status != 'Cancelled')
                  _actionChip(
                    context,
                    label: '✗ Cancel Order',
                    color: const Color(0xffd32f2f),
                    onTap: () => _updateStatus(context, 'Cancelled'),
                  ),
                if (order.status == 'Cancelled')
                  const Chip(
                    label: Text('Order Cancelled', style: TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Color(0xffd32f2f),
                    padding: EdgeInsets.zero,
                  ),
                if (order.status == 'Delivered')
                  const Chip(
                    label: Text('Order Delivered', style: TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: Color(0xff12833b),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(BuildContext context, {required String label, required Color color, required VoidCallback onTap}) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _updateStatus(BuildContext context, String status) {
    context.read<AppState>().updateOrderStatus(
          orderId: order.orderId,
          status: status,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order.orderId} marked as $status'),
        backgroundColor: const Color(0xff12833b),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = state.allProducts.where((product) => product.stock <= 5).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Inventory'),
        actions: [
          IconButton(onPressed: () => context.read<AppState>().loadAdminData(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_outlined, color: Color(0xffff9800)),
              title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('SKU ${product.sku}'),
              trailing: TextButton(
                onPressed: () => _showStockDialog(context, product),
                child: Text('Stock ${product.stock}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStockDialog(BuildContext context, Product product) {
    // Capture BEFORE showDialog — dialog context has no Scaffold ancestor
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    showDialog<void>(
      context: context,
      builder: (_) => _StockDialog(
        product: product,
        messenger: messenger,
        onConfirm: (val) => appState.updateInventoryStock(
          productId: product.productId,
          stock: val,
        ),
      ),
    );
  }
}

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final revenue = state.revenueByDay.isEmpty ? List.generate(8, (index) => (index * index + 4) * 450) : state.revenueByDay;
    final performance = state.adminProductPerformance.isEmpty ? state.bestSellers : state.adminProductPerformance;
    final maxRevenue = revenue.fold<double>(0.0, (max, val) => val > max ? val.toDouble() : max);
    final calculatedMaxY = maxRevenue == 0.0 ? 1000.0 : maxRevenue;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(onPressed: () => context.read<AppState>().loadAdminData(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          MetricCard(title: 'Product Performance', value: '${performance.length} best sellers', icon: Icons.trending_up),
          const SizedBox(height: 10),
          MetricCard(title: 'Payment Analytics', value: '${state.payments.length} transactions', icon: Icons.payments_outlined),
          const SizedBox(height: 10),
          _AdminChartCard(
            title: 'Revenue Trend',
            chart: LineChart(
              LineChartData(
                minY: 0,
                maxY: calculatedMaxY,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(leftTitles: AxisTitles(), topTitles: AxisTitles(), rightTitles: AxisTitles()),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(revenue.length, (index) => FlSpot(index.toDouble(), revenue[index].toDouble())),
                    isCurved: true,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Product Performance'),
          ...performance.take(8).map(
                (product) {
                  final liveRating = state.getProductLiveRating(product.productId);
                  final liveReviewCount = state.getProductLiveReviewCount(product.productId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: SizedBox(width: 48, height: 48, child: ProductImage(url: product.thumbnail, fit: BoxFit.contain)),
                      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('$liveReviewCount reviews • ${liveRating.toStringAsFixed(1)} rating'),
                      trailing: Text(product.priceLabel),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}

class AdminSimpleScreen extends StatelessWidget {
  const AdminSimpleScreen({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = _items(state);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          MetricCard(title: title, value: '${items.length} records', icon: icon),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('No records yet'),
                subtitle: Text('This admin module is connected and will show backend data when records are available.'),
              ),
            )
          else
            ...items.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text(item.$1),
                    subtitle: Text(item.$2),
                    onTap: title.contains('Returns')
                        ? () {
                            final returnReq = state.returnRequests[index];
                            final orderId = returnReq.orderId;
                            final orders = state.orders.where((o) => o.orderId == orderId).toList();
                            if (orders.isNotEmpty) {
                              showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Review Return Request'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Reason for Return:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(returnReq.reason, style: const TextStyle(fontSize: 14)),
                                        const SizedBox(height: 12),
                                        const Text('Order Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        _AdminOrderStatusCard(order: orders.first),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order $orderId not found locally.')),
                              );
                            }
                          }
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<(String, String)> _items(AppState state) {
    if (title.contains('Users')) {
      return state.adminUsers.map((user) => (user.name, '${user.email} - ${user.role}')).toList();
    }
    if (title.contains('Reviews')) {
      return state.reviews.map((review) => (review.userName, '${review.rating.toStringAsFixed(1)} stars - ${review.comment}')).toList();
    }
    if (title.contains('Notifications')) {
      return state.notifications.map((item) => (item.title, item.body)).toList();
    }
    if (title.contains('Returns')) {
      return state.returnRequests.map((item) => ('Order ID: ${item.orderId}', 'Reason: ${item.reason} [${item.status}]')).toList();
    }
    return [
      ('Backend connected', 'Admin APIs are protected by JWT and admin role checks.'),
      ('Firestore ready', 'Products, orders, addresses, users, and configured modules sync through the backend.'),
    ];
  }
}

class AdminDailyOffersScreen extends StatefulWidget {
  const AdminDailyOffersScreen({super.key});

  @override
  State<AdminDailyOffersScreen> createState() => _AdminDailyOffersScreenState();
}

class _AdminDailyOffersScreenState extends State<AdminDailyOffersScreen> {
  late final TextEditingController _monday;
  late final TextEditingController _tuesday;
  late final TextEditingController _wednesday;
  late final TextEditingController _thursday;
  late final TextEditingController _friday;
  late final TextEditingController _saturday;
  late final TextEditingController _sunday;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final offers = state.dailyOffers;
    _monday = TextEditingController(text: (offers['monday'] ?? 10).toString());
    _tuesday = TextEditingController(text: (offers['tuesday'] ?? 15).toString());
    _wednesday = TextEditingController(text: (offers['wednesday'] ?? 20).toString());
    _thursday = TextEditingController(text: (offers['thursday'] ?? 25).toString());
    _friday = TextEditingController(text: (offers['friday'] ?? 30).toString());
    _saturday = TextEditingController(text: (offers['saturday'] ?? 35).toString());
    _sunday = TextEditingController(text: (offers['sunday'] ?? 40).toString());
  }

  @override
  void dispose() {
    _monday.dispose();
    _tuesday.dispose();
    _wednesday.dispose();
    _thursday.dispose();
    _friday.dispose();
    _saturday.dispose();
    _sunday.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Daily Offers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Configure baseline discount percentages offered to customers dynamically based on the day of the week.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _dayField(_monday, 'Monday'),
          _dayField(_tuesday, 'Tuesday'),
          _dayField(_wednesday, 'Wednesday'),
          _dayField(_thursday, 'Thursday'),
          _dayField(_friday, 'Friday'),
          _dayField(_saturday, 'Saturday'),
          _dayField(_sunday, 'Sunday'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const CircularProgressIndicator() : const Text('Save Schedule'),
          ),
        ],
      ),
    );
  }

  Widget _dayField(TextEditingController controller, String day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          PercentLimitTextInputFormatter(),
        ],
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.percent_outlined),
          labelText: '$day Discount %',
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final schedule = {
      'monday': int.tryParse(_monday.text) ?? 10,
      'tuesday': int.tryParse(_tuesday.text) ?? 15,
      'wednesday': int.tryParse(_wednesday.text) ?? 20,
      'thursday': int.tryParse(_thursday.text) ?? 25,
      'friday': int.tryParse(_friday.text) ?? 30,
      'saturday': int.tryParse(_saturday.text) ?? 35,
      'sunday': int.tryParse(_sunday.text) ?? 40,
    };
    try {
      await context.read<AppState>().updateDailyOffers(schedule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily offers updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update daily offers: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Shared stock update dialog — StatefulWidget so the TextEditingController
// is owned by the widget and disposed by Flutter in the correct order
// (TextField is deactivated before dispose() is called on the controller).
// This prevents the `_dependents.isEmpty` crash when pressing the back button.
// ---------------------------------------------------------------------------
class _StockDialog extends StatefulWidget {
  const _StockDialog({
    required this.product,
    required this.messenger,
    required this.onConfirm,
  });

  final Product product;
  final ScaffoldMessengerState messenger;
  final void Function(int stock) onConfirm;

  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  late final TextEditingController _stock;

  @override
  void initState() {
    super.initState();
    _stock = TextEditingController(text: widget.product.stock.toString());
  }

  @override
  void dispose() {
    _stock.dispose(); // Flutter calls this AFTER the TextField is disposed ✅
    super.dispose();
  }

  void _submit() {
    final text = _stock.text.trim();

    if (text.isEmpty) {
      widget.messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter a stock value'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final val = int.tryParse(text);
    if (val == null) {
      widget.messenger.showSnackBar(
        const SnackBar(
          content: Text('Invalid number — enter a valid stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (val < 1) {
      widget.messenger.showSnackBar(
        const SnackBar(
          content: Text('Stock must be at least 1'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (val > 30) {
      widget.messenger.showSnackBar(
        const SnackBar(
          content: Text('Stock cannot exceed 30'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop();
    widget.onConfirm(val);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Stock — ${widget.product.sku}'),
      content: TextField(
        controller: _stock,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          StockLimitTextInputFormatter(),
        ],
        decoration: const InputDecoration(
          labelText: 'Stock (1 – 30)',
          hintText: 'Enter a value between 1 and 30',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Update'),
        ),
      ],
    );
  }
}
