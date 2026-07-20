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
import '../theme/app_theme.dart';
import 'neumorphic.dart';

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
        Image.asset(
          'assets/logo/mospl_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 9),
        Text(
          'MOSPL',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.leatherBrown,
                letterSpacing: 1.5,
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
      padding: const EdgeInsets.fromLTRB(16, 22, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.1,
                  ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.leatherBrown,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
              baseColor: AppColors.softBeige,
              highlightColor: AppColors.ivoryWhite,
              child: Container(
                height: height,
                width: width,
                color: AppColors.ivoryWhite,
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
    final bool isCustomColor = color != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCustomColor ? color! : AppColors.goldLight,
        borderRadius: BorderRadius.circular(99),
        border: isCustomColor ? null : Border.all(color: AppColors.luxuryGold.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isCustomColor ? Colors.white : const Color(0xff8A5B16),
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.3,
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
                fontWeight: FontWeight.w800,
                color: AppColors.leatherBrown,
              ),
        ),
        Text(
          product.oldPriceLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText.withValues(alpha: 0.7),
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.secondaryText.withValues(alpha: 0.5),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Neumorphic(
      borderRadius: 18,
      isClickable: true,
      onTap: () {
        context.read<AppState>().viewProduct(product);
        context.push('/product/${product.productId}?heroTag=${Uri.encodeComponent(resolvedHeroTag)}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Fill all available height so the cart row can be pinned to the bottom
        mainAxisSize: MainAxisSize.max,
        children: [
          Stack(
            children: [
              // Fixed-height image area — all product images are the SAME pixel height
              SizedBox(
                width: double.infinity,
                height: 160,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child: ColoredBox(
                    color: isDark ? AppColors.darkInputFill : Colors.white,
                    child: ProductImage(
                      url: product.thumbnail,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      heroTag: resolvedHeroTag,
                    ),
                  ),
                ),
              ),
              if (product.stock <= 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.50),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'SOLD OUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 1.2,
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
                right: 6,
                top: 6,
                child: _WishlistButton(productId: product.productId, product: product),
              ),
            ],
          ),
          // Expanded fills remaining card height so Spacer can push cart to the bottom
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 7),
                  PriceRow(product: product, compact: compact),
                  const SizedBox(height: 7),
                  _RatingRow(productId: product.productId),
                  // Pushes the cart row to the BOTTOM of every card — this is the key fix
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: AppColors.successGreen, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Free delivery',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.successGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      _AddToCartButton(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.wishlistBg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoBrown.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        onPressed: () => context.read<AppState>().toggleWishlist(product),
        icon: Icon(
          wished ? Icons.favorite : Icons.favorite_border,
          size: 16,
          color: wished ? AppColors.leatherBrown : AppColors.leatherBrown.withValues(alpha: 0.6),
        ),
      ),
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
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton.filled(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: product.stock <= 0
              ? AppColors.softBeige
              : AppColors.leatherBrown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: product.stock <= 0
            ? null
            : () => context.read<AppState>().addToCart(product),
        icon: Icon(
          product.stock <= 0
              ? Icons.remove_shopping_cart
              : Icons.add_shopping_cart,
          size: 15,
        ),
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
          liveRating > 0 ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xffF59E0B),
          size: 15,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            liveRating > 0
                ? '${liveRating.toStringAsFixed(1)} ($liveReviewCount)'
                : 'No Rating yet ($liveReviewCount)',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.secondaryText,
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            // Fixed card height so all cards are identically sized regardless of screen width
            mainAxisExtent: 375,
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
      height: 405,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
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
  const CategoryTile({super.key, required this.category, this.trailing});

  final ProductCategory category;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Neumorphic(
      borderRadius: 18,
      isClickable: true,
      onTap: () {
        context.read<AppState>().setCategory(category.name);
        context.go('/products');
      },
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputFill : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: SizedBox(
                width: 96,
                height: 96,
                child: ProductImage(url: category.imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${category.productCount} products',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.leatherBrown,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
          trailing ?? Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(Icons.chevron_right, color: AppColors.leatherBrown.withValues(alpha: 0.6), size: 20),
          ),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isShort = constraints.maxHeight < 340;
        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: isShort ? 12 : 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isShort ? 64 : 88,
                  height: isShort ? 64 : 88,
                  decoration: BoxDecoration(
                    color: AppColors.warmCream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.softBeige, width: 1.5),
                  ),
                  child: Icon(
                    icon,
                    size: isShort ? 32 : 44,
                    color: AppColors.leatherBrown.withValues(alpha: 0.55),
                  ),
                ),
                SizedBox(height: isShort ? 10 : 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: isShort ? 18 : null,
                      ),
                ),
                SizedBox(height: isShort ? 4 : 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                ),
                if (actionLabel != null) ...[
                  SizedBox(height: isShort ? 16 : 24),
                  ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: TextField(
        readOnly: readOnly,
        onTap: onTap,
        onChanged: context.read<AppState>().updateSearch,
        controller: readOnly ? TextEditingController(text: searchQuery) : null,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search wallets, belts, passport holders…',
          hintStyle: TextStyle(
            color: AppColors.secondaryText.withValues(alpha: 0.65),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.leatherBrown.withValues(alpha: 0.7),
            size: 20,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: AppColors.leatherBrown.withValues(alpha: 0.6)),
                  onPressed: () => context.read<AppState>().updateSearch(''),
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.darkInputFill : AppColors.creamInputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: AppColors.softBeige, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: AppColors.softBeige, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppColors.leatherBrown, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stepperBg = isDark ? AppColors.darkInputFill : AppColors.warmCream;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.softBeige;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: stepperBg,
        border: Border.all(color: borderCol, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove, size: 16),
            color: AppColors.leatherBrown,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: disableAdd ? null : () => onChanged(quantity + 1),
            icon: Icon(Icons.add, size: 16, color: disableAdd ? AppColors.secondaryText : AppColors.leatherBrown),
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
          const Icon(Icons.star_border_rounded, color: Color(0xffF59E0B), size: 18),
          const SizedBox(width: 8),
          Text(
            'No Rating yet | $reviewLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
          ),
        ],
      );
    }
    return Row(
      children: [
        RatingBarIndicator(
          rating: liveRating,
          itemSize: 18,
          itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: Color(0xffF59E0B)),
        ),
        const SizedBox(width: 8),
        Text(
          '${liveRating.toStringAsFixed(1)} | $liveReviewCount reviews',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
        ),
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
    final resolvedColor = color ?? AppColors.leatherBrown;
    return Neumorphic(
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: resolvedColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: resolvedColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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
