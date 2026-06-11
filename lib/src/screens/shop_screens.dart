import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../widgets/widgets.dart';

class ShopShell extends StatelessWidget {
  const ShopShell({super.key, required this.child});

  final Widget child;

  int _indexFor(String path) {
    if (path.startsWith('/categories')) return 1;
    if (path.startsWith('/wishlist')) return 2;
    if (path.startsWith('/cart')) return 3;
    if (path.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final state = context.watch<AppState>();
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(path),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/categories');
            case 2:
              context.go('/wishlist');
            case 3:
              context.go('/cart');
            case 4:
              context.go('/profile');
          }
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Categories'),
          const NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Wishlist'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: state.cartCount > 0,
              label: Text('${state.cartCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const MosplLogo(size: 34),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: state.unreadNotifications > 0,
              label: Text('${state.unreadNotifications}'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
          IconButton(
            onPressed: () => context.push('/ai-chatbot'),
            icon: const Icon(Icons.smart_toy_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final app = context.read<AppState>();
          await app.loadCatalogFromBackend();
          await app.loadAuthenticatedData();
        },
        child: ListView(
          children: [
            SearchBox(readOnly: true, onTap: () => context.push('/search')),
            _HomeBanner(),
            SizedBox(
              height: 104,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: state.categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return InkWell(
                    onTap: () {
                      context.read<AppState>().setCategory(category.name);
                      context.go('/products');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 106,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          Expanded(child: ProductImage(url: category.imageUrl, fit: BoxFit.contain)),
                          const SizedBox(height: 4),
                          Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SectionHeader(
              title: 'Trending MOSPL Deals',
              actionLabel: 'View all',
              onAction: () => context.push('/trending'),
            ),
            HorizontalProducts(products: state.trendingProducts.take(10).toList()),
            SectionHeader(
              title: 'Current MOSPL Products',
              actionLabel: 'See more',
              onAction: () => context.push('/recommended'),
            ),
            ProductGrid(products: state.bestSellers.take(8).toList(), compact: true),
            SectionHeader(
              title: 'More from Online Madras',
              actionLabel: 'Collections',
              onAction: () => context.push('/leather-collections'),
            ),
            HorizontalProducts(products: state.featuredProducts.take(10).toList()),
          ],
        ),
      ),
    );
  }
}

class _HomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backendBanners = context.watch<AppState>().banners;
    if (backendBanners.isNotEmpty) {
      return CarouselSlider.builder(
        itemCount: backendBanners.length,
        itemBuilder: (context, index, realIndex) {
          final item = backendBanners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xffe8f1ff),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl.isNotEmpty)
                  Opacity(
                    opacity: 0.18,
                    child: ProductImage(url: item.imageUrl, fit: BoxFit.cover),
                  ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer_outlined, size: 46, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 240.ms).slideX(begin: 0.03, end: 0);
        },
        options: CarouselOptions(
          height: 138,
          viewportFraction: 0.92,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          enlargeCenterPage: false,
        ),
      );
    }
    final banners = const [
      _BannerData('30% OFF', 'MOSPL wallets, belts and passport holders', Icons.local_offer_outlined),
      _BannerData('Free Shipping', 'Delivered by 5 days across India', Icons.local_shipping_outlined),
      _BannerData('Women Wallets', 'Black and brown genuine leather wallets', Icons.wallet_outlined),
    ];
    return CarouselSlider.builder(
      itemCount: banners.length,
      itemBuilder: (context, index, realIndex) {
        final item = banners[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: index == 1 ? const Color(0xffe9f8ed) : const Color(0xffe8f1ff),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 46, color: index == 1 ? const Color(0xff12833b) : Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 240.ms).slideX(begin: 0.03, end: 0);
      },
      options: CarouselOptions(
        height: 138,
        viewportFraction: 0.92,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        enlargeCenterPage: false,
      ),
    );
  }
}

class _BannerData {
  const _BannerData(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: state.categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => CategoryTile(category: state.categories[index]),
      ),
    );
  }
}

class ProductListingScreen extends StatelessWidget {
  const ProductListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = state.visibleProducts;
    return Scaffold(
      appBar: AppBar(
        title: Text(state.selectedCategory ?? 'All Products'),
        actions: [
          IconButton(onPressed: () => context.push('/filters'), icon: const Icon(Icons.tune)),
          IconButton(onPressed: () => showSortSheet(context), icon: const Icon(Icons.sort)),
        ],
      ),
      body: Column(
        children: [
          SearchBox(readOnly: true, onTap: () => context.push('/search')),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: state.selectedCategory == null,
                  onSelected: (_) => context.read<AppState>().setCategory(null),
                ),
                const SizedBox(width: 8),
                ...state.categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: state.selectedCategory == category.name,
                      onSelected: (_) => context.read<AppState>().setCategory(category.name),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: 'No products found',
                    subtitle: 'Try another search or clear filters.',
                    actionLabel: 'Clear Filters',
                    onAction: context.read<AppState>().clearFilters,
                  )
                : ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text('${products.length} products • ${state.sortOption}'),
                      ),
                      ProductGrid(products: products),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImage = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final product = state.productById(widget.productId);
    final images = product.galleryImages.isEmpty ? [product.thumbnail] : product.galleryImages;
    final visibleSpecifications = product.specifications.entries
        .where((entry) => entry.key != 'Source URL' && entry.key != 'Source Product ID')
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            onPressed: () => context.read<AppState>().toggleWishlist(product),
            icon: Icon(state.isWishlisted(product.productId) ? Icons.favorite : Icons.favorite_border),
          ),
          IconButton(onPressed: () => context.push('/cart'), icon: const Icon(Icons.shopping_cart_outlined)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.read<AppState>().addToCart(product),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Cart'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AppState>().addToCart(product);
                    context.push('/checkout');
                  },
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Buy Now'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          InkWell(
            onTap: () => context.push('/gallery/${product.productId}?index=$_selectedImage'),
            child: Container(
              color: Theme.of(context).cardColor,
              child: AspectRatio(
                aspectRatio: 1,
                child: ProductImage(
                  url: images[_selectedImage],
                  fit: BoxFit.contain,
                  heroTag: 'product-${product.productId}',
                ),
              ),
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => InkWell(
                onTap: () => setState(() => _selectedImage = index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedImage == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: _selectedImage == index ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ProductImage(url: images[index], fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                RatingSummary(product: product),
                const SizedBox(height: 12),
                PriceRow(product: product),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    OfferBadge(text: 'Free Delivery', color: Color(0xff12833b)),
                    SizedBox(width: 8),
                    OfferBadge(text: 'Razorpay Test Mode'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(product.description),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openSourceListing(context, product),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open source listing'),
                ),
                const SizedBox(height: 18),
                Text('Specifications', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...visibleSpecifications.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_shipping_outlined, color: Color(0xff12833b)),
                  title: Text(product.deliveryInfo),
                  subtitle: Text(product.returnPolicy),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(product.warranty),
                  subtitle: const Text('Genuine leather product inspired by Online Madras MOSPL catalog.'),
                ),
                SectionHeader(
                  title: 'Recommended Products',
                  actionLabel: 'View all',
                  onAction: () => context.push('/recommended'),
                ),
              ],
            ),
          ),
          HorizontalProducts(
            products: state.allProducts.where((item) => item.category == product.category && item.productId != product.productId).take(10).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _openSourceListing(BuildContext context, Product product) async {
    final sourceUrl = product.sourceUrl.trim();
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || uri.host.isEmpty || (uri.scheme != 'http' && uri.scheme != 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source URL is not available for this product.')),
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open source listing.')),
      );
    }
  }
}

class ProductGalleryScreen extends StatefulWidget {
  const ProductGalleryScreen({super.key, required this.productId, this.initialIndex = 0});

  final String productId;
  final int initialIndex;

  @override
  State<ProductGalleryScreen> createState() => _ProductGalleryScreenState();
}

class _ProductGalleryScreenState extends State<ProductGalleryScreen> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final product = context.watch<AppState>().productById(widget.productId);
    final images = product.galleryImages.isEmpty ? [product.thumbnail] : product.galleryImages;
    final safeIndex = _index.clamp(0, images.length - 1);
    return Scaffold(
      appBar: AppBar(title: Text('${safeIndex + 1}/${images.length}')),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: ProductImage(
                  url: images[safeIndex],
                  fit: BoxFit.contain,
                  heroTag: 'product-${product.productId}',
                ),
              ),
            ),
          ),
          SizedBox(
            height: 86,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => InkWell(
                onTap: () => setState(() => _index = index),
                child: SizedBox(width: 62, child: ProductImage(url: images[index], fit: BoxFit.contain)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          const SearchBox(),
          Expanded(
            child: ListView(
              children: [
                if (state.searchQuery.isEmpty) ...[
                  const SectionHeader(title: 'Popular Searches'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Men wallet', 'Coat wallet', 'Hand woven belt', 'Passport holder', 'Women wallet']
                          .map(
                            (term) => ActionChip(
                              label: Text(term),
                              onPressed: () => context.read<AppState>().updateSearch(term),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                SectionHeader(title: state.searchQuery.isEmpty ? 'Recommended' : 'Search Results'),
                ProductGrid(products: state.visibleProducts.take(24).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  int? _min;
  int? _max;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _min = state.minPrice;
    _max = state.maxPrice;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Filters')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AppState>().clearFilters();
                    context.pop();
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AppState>().setPriceFilter(_min, _max);
                    context.pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: state.selectedCategory == null,
                onSelected: (_) => context.read<AppState>().setCategory(null),
              ),
              ...state.categories.map(
                (category) => ChoiceChip(
                  label: Text(category.name),
                  selected: state.selectedCategory == category.name,
                  onSelected: (_) => context.read<AppState>().setCategory(category.name),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Price', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Under ₹700'),
                selected: _max == 700,
                onSelected: (_) => setState(() {
                  _min = null;
                  _max = 700;
                }),
              ),
              ChoiceChip(
                label: const Text('₹700 - ₹1000'),
                selected: _min == 700,
                onSelected: (_) => setState(() {
                  _min = 700;
                  _max = 1000;
                }),
              ),
              ChoiceChip(
                label: const Text('Above ₹1000'),
                selected: _min == 1000,
                onSelected: (_) => setState(() {
                  _min = 1000;
                  _max = null;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showSortSheet(BuildContext context) {
  const options = ['Recommended', 'Price: Low to High', 'Price: High to Low', 'Top Rated', 'Newest'];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final selected = context.watch<AppState>().sortOption;
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Sort By', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            ),
            ...options.map(
              (option) => ListTile(
                leading: Icon(selected == option ? Icons.radio_button_checked : Icons.radio_button_off),
                title: Text(option),
                onTap: () {
                  context.read<AppState>().setSort(option);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<AppState>().wishlistProducts;
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: products.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border,
              title: 'Your wishlist is empty',
              subtitle: 'Save wallets, belts, passport holders and women wallets you like.',
              actionLabel: 'Shop Products',
              onAction: () => context.go('/products'),
            )
          : ListView(
              children: [
                ProductGrid(products: products),
              ],
            ),
    );
  }
}

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({
    super.key,
    required this.title,
    required this.selector,
    this.emptyText = 'No products available.',
  });

  final String title;
  final List<Product> Function(AppState state) selector;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = selector(state);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: products.isEmpty
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: title,
              subtitle: emptyText,
              actionLabel: 'Explore Store',
              onAction: () => context.go('/home'),
            )
          : ListView(
              children: [
                ProductGrid(products: products),
              ],
            ),
    );
  }
}

class ProductComparisonScreen extends StatefulWidget {
  const ProductComparisonScreen({super.key});

  @override
  State<ProductComparisonScreen> createState() => _ProductComparisonScreenState();
}

class _ProductComparisonScreenState extends State<ProductComparisonScreen> {
  final _search = TextEditingController();
  final Set<String> _selectedProductIds = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedProducts = state.allProducts.where((product) => _selectedProductIds.contains(product.productId)).toList();
    final query = _search.text.trim().toLowerCase();
    final selectableProducts = state.allProducts.where((product) {
      if (query.isEmpty) return true;
      final text = '${product.name} ${product.category} ${product.color} ${product.material}'.toLowerCase();
      return text.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Comparison')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search product to compare',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selected ${selectedProducts.length}/3',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (_selectedProductIds.isNotEmpty)
                TextButton(
                  onPressed: () => setState(_selectedProductIds.clear),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: selectableProducts.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching products',
                    subtitle: 'Try wallet, belt, passport holder, black, or brown.',
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectableProducts.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final product = selectableProducts[index];
                      final selected = _selectedProductIds.contains(product.productId);
                      return SizedBox(
                        width: 210,
                        child: _CompareProductPickerCard(
                          product: product,
                          selected: selected,
                          onTap: () => _toggleProduct(product),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          if (selectedProducts.length < 2)
            EmptyState(
              icon: Icons.compare_arrows,
              title: 'Choose products to compare',
              subtitle: _selectedProductIds.isEmpty
                  ? 'Select two or three MOSPL products above.'
                  : 'Select one more product to start comparison.',
            )
          else
            _ComparisonResult(products: selectedProducts),
        ],
      ),
    );
  }

  void _toggleProduct(Product product) {
    setState(() {
      if (!_selectedProductIds.remove(product.productId)) {
        if (_selectedProductIds.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can compare up to 3 products at a time.')),
          );
          return;
        }
        _selectedProductIds.add(product.productId);
      }
    });
  }
}

class _CompareProductPickerCard extends StatelessWidget {
  const _CompareProductPickerCard({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final Product product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                ),
              ),
              Expanded(
                child: Center(
                  child: ProductImage(url: product.thumbnail, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(product.priceLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonResult extends StatelessWidget {
  const _ComparisonResult({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comparison', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: products
                .map(
                  (product) => SizedBox(
                    width: 300,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _ComparisonProductCard(product: product),
                    ),
                  ),
                )
                .toList(),
            ),
        ),
      ],
    );
  }
}

class _ComparisonProductCard extends StatelessWidget {
  const _ComparisonProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final specs = product.specifications;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: ProductImage(url: product.thumbnail, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            PriceRow(product: product),
            const Divider(height: 22),
            _CompareRow(label: 'Rating', value: product.rating.toStringAsFixed(1)),
            _CompareRow(label: 'Color', value: product.color),
            _CompareRow(label: 'Material', value: product.material),
            _CompareRow(label: 'Size', value: product.size),
            _CompareRow(label: 'Card slots', value: specs['Card Slots'] ?? 'Not Specified'),
            _CompareRow(label: 'Compartments', value: specs['No. of Compartments'] ?? 'Not Specified'),
            _CompareRow(label: 'Delivery', value: product.deliveryInfo),
          ],
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
