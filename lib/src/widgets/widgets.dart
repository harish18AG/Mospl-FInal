import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models.dart';
import '../state/app_state.dart';

class MosplLogo extends StatelessWidget {
  const MosplLogo({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/logo/mospl_logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'MOSPL',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.heroTag,
  });

  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final image = url.startsWith('assets/')
        ? Image.asset(
            url,
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/products/product_fallback.png',
              height: height,
              width: width,
              fit: fit,
            ),
          )
        : CachedNetworkImage(
            imageUrl: url,
            height: height,
            width: width,
            fit: fit,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: height,
                width: width,
                color: Colors.white,
              ),
            ),
            errorWidget: (context, url, error) => Image.asset(
              'assets/products/product_fallback.png',
              height: height,
              width: width,
              fit: fit,
            ),
          );
    if (heroTag == null) return image;
    return Hero(tag: heroTag!, child: image);
  }
}

class OfferBadge extends StatelessWidget {
  const OfferBadge({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? const Color(0xfffff2d8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color == null ? const Color(0xff8a4b00) : Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class PriceRow extends StatelessWidget {
  const PriceRow({super.key, required this.product, this.compact = false});

  final Product product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          product.priceLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        Text(
          product.oldPriceLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
              ),
        ),
        OfferBadge(text: product.discountLabel),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
  });

  final Product product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final wished = app.isWishlisted(product.productId);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<AppState>().viewProduct(product);
          context.push('/product/${product.productId}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: compact ? 1.05 : 1,
                  child: ProductImage(
                    url: product.thumbnail,
                    fit: BoxFit.contain,
                    heroTag: 'product-${product.productId}',
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: OfferBadge(text: product.discountLabel),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.read<AppState>().toggleWishlist(product),
                    icon: Icon(wished ? Icons.favorite : Icons.favorite_border),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  PriceRow(product: product, compact: compact),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        product.rating > 0 ? Icons.star : Icons.star_border,
                        color: const Color(0xffffb300),
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(product.rating > 0 ? '${product.rating.toStringAsFixed(1)} (${product.reviewCount})' : 'No Rating yet (${product.reviewCount})'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Color(0xff12833b), size: 15),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Free delivery',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: const Color(0xff12833b),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.read<AppState>().addToCart(product),
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, this.compact = false});

  final List<Product> products;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 700 ? 4 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.5,
          ),
          itemBuilder: (context, index) => ProductCard(
            product: products[index],
            compact: compact,
          ),
        );
      },
    );
  }
}

class HorizontalProducts extends StatelessWidget {
  const HorizontalProducts({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 388,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 172,
          child: ProductCard(product: products[index], compact: true),
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category});

  final ProductCategory category;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<AppState>().setCategory(category.name);
          context.go('/products');
        },
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: ProductImage(url: category.imageUrl, fit: BoxFit.contain),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(category.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${category.productCount} products',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, this.readOnly = false, this.onTap});

  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: TextField(
        readOnly: readOnly,
        onTap: onTap,
        onChanged: context.read<AppState>().updateSearch,
        controller: readOnly ? TextEditingController(text: state.searchQuery) : null,
        decoration: InputDecoration(
          hintText: 'Search wallets, belts, passport holders',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.read<AppState>().updateSearch(''),
                )
              : null,
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove, size: 16),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add, size: 16),
          ),
        ],
      ),
    );
  }
}

class RatingSummary extends StatelessWidget {
  const RatingSummary({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.rating <= 0) {
      final reviewLabel = product.reviewCount == 1 ? '1 review' : '${product.reviewCount} reviews';
      return Row(
        children: [
          const Icon(Icons.star_border, color: Color(0xffffb300), size: 18),
          const SizedBox(width: 8),
          Text('No Rating yet | $reviewLabel'),
        ],
      );
    }
    return Row(
      children: [
        RatingBarIndicator(
          rating: product.rating,
          itemSize: 18,
          itemBuilder: (context, index) => const Icon(Icons.star, color: Color(0xffffb300)),
        ),
        const SizedBox(width: 8),
        Text('${product.rating.toStringAsFixed(1)} | ${product.reviewCount} reviews'),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.12),
              child: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
