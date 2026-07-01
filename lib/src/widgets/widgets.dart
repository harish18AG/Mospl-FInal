import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models.dart';
import '../state/app_state.dart';

// Global cache to store decoded base64 image bytes, avoiding parsing/garbage collection churn on every rebuild.
final Map<String, Uint8List> _base64ImageCache = {};

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
    var resolvedUrl = url;
    if (resolvedUrl.startsWith('data:image/') && resolvedUrl.contains(';base64,')) {
      try {
        Uint8List? bytes = _base64ImageCache[resolvedUrl];
        if (bytes == null) {
          final base64String = resolvedUrl.substring(resolvedUrl.indexOf(';base64,') + 8);
          bytes = base64.decode(base64String.trim());
          _base64ImageCache[resolvedUrl] = bytes;
        }
        final img = Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          gaplessPlayback: true, // Prevents visual blink/flash when the widget is rebuilt
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/products/product_fallback.png',
            height: height,
            width: width,
            fit: fit,
          ),
        );
        if (heroTag == null) return img;
        return Hero(tag: heroTag!, child: img);
      } catch (_) {}
    }

    if (resolvedUrl.startsWith('/static/products/')) {
      resolvedUrl = resolvedUrl.replaceFirst('/static/products/', 'assets/products/');
    } else if (resolvedUrl.startsWith('static/products/')) {
      resolvedUrl = resolvedUrl.replaceFirst('static/products/', 'assets/products/');
    }

    final image = resolvedUrl.startsWith('assets/')
        ? Image.asset(
            resolvedUrl,
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
            imageUrl: resolvedUrl,
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
    this.heroTagPrefix,
  });

  final Product product;
  final bool compact;
  final String? heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    debugPrint('ProductCard build: ${product.productId}');
    final resolvedHeroTag = heroTagPrefix != null
        ? '$heroTagPrefix-${product.productId}'
        : 'product-${product.productId}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<AppState>().viewProduct(product);
          context.push('/product/${product.productId}?heroTag=${Uri.encodeComponent(resolvedHeroTag)}');
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
                    heroTag: resolvedHeroTag,
                  ),
                ),
                if (product.stock <= 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SOLD OUT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
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
                  child: _WishlistButton(productId: product.productId, product: product),
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
                  _RatingRow(productId: product.productId),
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
                      _AddToCartButton(product: product),
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

/// Isolated widget: only rebuilds when THIS product's wishlist state changes.
class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.productId, required this.product});

  final String productId;
  final Product product;

  @override
  Widget build(BuildContext context) {
    debugPrint('WishlistIcon build: $productId');
    final wished = context.select<AppState, bool>((app) => app.isWishlisted(productId));
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      onPressed: () => context.read<AppState>().toggleWishlist(product),
      icon: Icon(wished ? Icons.favorite : Icons.favorite_border),
    );
  }
}

/// Isolated widget: reads NO global state — only fires writes.
/// Will NEVER rebuild due to cart or wishlist changes.
class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      visualDensity: VisualDensity.compact,
      onPressed: product.stock <= 0
          ? null
          : () => context.read<AppState>().addToCart(product),
      icon: Icon(
        product.stock <= 0
            ? Icons.remove_shopping_cart
            : Icons.add_shopping_cart,
        size: 18,
      ),
    );
  }
}

/// Isolated widget: only rebuilds when THIS product's rating/review changes.
/// Uses a single tuple selector to halve the number of Provider subscriptions
/// per card (one instead of two), reducing rebuild triggers on review changes.
class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    // Single selector for both values — avoids two separate subscription registrations
    // so a review update only causes ONE equality check (not two) per card.
    final (liveRating, liveReviewCount) = context.select<AppState, (double, int)>(
      (app) => (app.getProductLiveRating(productId), app.getProductLiveReviewCount(productId)),
    );
    return Row(
      children: [
        Icon(
          liveRating > 0 ? Icons.star : Icons.star_border,
          color: const Color(0xffffb300),
          size: 16,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            liveRating > 0
                ? '${liveRating.toStringAsFixed(1)} ($liveReviewCount)'
                : 'No Rating yet ($liveReviewCount)',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    this.compact = false,
    this.heroTagPrefix,
  });

  final List<Product> products;
  final bool compact;
  final String? heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    debugPrint('ProductGrid build');
    debugPrint('Grid build');
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
            childAspectRatio: 0.45,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return RepaintBoundary(
              key: ValueKey(product.productId),
              child: ProductCard(
                product: product,
                compact: compact,
                heroTagPrefix: heroTagPrefix,
              ),
            );
          },
        );
      },
    );
  }
}

class HorizontalProducts extends StatelessWidget {
  const HorizontalProducts({
    super.key,
    required this.products,
    this.heroTagPrefix,
  });

  final List<Product> products;
  final String? heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 388,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            key: ValueKey(product.productId),
            width: 172,
            child: RepaintBoundary(
              child: ProductCard(
                product: product,
                compact: true,
                heroTagPrefix: heroTagPrefix,
              ),
            ),
          );
        },
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
    // FIX: Was context.watch<AppState>() which rebuilt on EVERY state change
    // (including cart/wishlist toggles). Now only rebuilds when searchQuery changes.
    final searchQuery = context.select<AppState, String>((app) => app.searchQuery);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: TextField(
        readOnly: readOnly,
        onTap: onTap,
        onChanged: context.read<AppState>().updateSearch,
        controller: readOnly ? TextEditingController(text: searchQuery) : null,
        decoration: InputDecoration(
          hintText: 'Search wallets, belts, passport holders',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
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
    this.max,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final bool disableAdd = max != null && quantity >= max!;
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
            onPressed: disableAdd ? null : () => onChanged(quantity + 1),
            icon: Icon(Icons.add, size: 16, color: disableAdd ? Colors.grey : null),
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
    // FIX: Was context.watch<AppState>() which rebuilt on EVERY state change.
    // Now uses a single tuple selector so this widget only rebuilds when
    // the rating or review count for THIS specific product changes.
    final (liveRating, liveReviewCount) = context.select<AppState, (double, int)>(
      (app) => (
        app.getProductLiveRating(product.productId),
        app.getProductLiveReviewCount(product.productId),
      ),
    );
    if (liveRating <= 0) {
      final reviewLabel = liveReviewCount == 1 ? '1 review' : '$liveReviewCount reviews';
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
          rating: liveRating,
          itemSize: 18,
          itemBuilder: (context, index) => const Icon(Icons.star, color: Color(0xffffb300)),
        ),
        const SizedBox(width: 8),
        Text('${liveRating.toStringAsFixed(1)} | $liveReviewCount reviews'),
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

class StockLimitTextInputFormatter extends TextInputFormatter {
  final int maxVal = 30;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final intValue = int.tryParse(newValue.text);
    if (intValue == null || intValue > maxVal || intValue < 0) {
      return oldValue;
    }
    return newValue;
  }
}

class PercentLimitTextInputFormatter extends TextInputFormatter {
  final int maxVal = 100;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final intValue = int.tryParse(newValue.text);
    if (intValue == null || intValue > maxVal || intValue < 0) {
      return oldValue;
    }
    return newValue;
  }
}
