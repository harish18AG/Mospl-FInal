import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../services/razorpay_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty',
          subtitle: 'Add MOSPL wallets, belts, passport holders or women wallets.',
          actionLabel: 'Shop Now',
          onAction: () => context.go('/products'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Cart (${state.cartCount})')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: () => context.push('/checkout'),
            child: Text('Checkout • ${inr(state.cartTotal)}'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...state.cart.map((line) => _CartLineCard(line: line)),
          const SizedBox(height: 12),
          _PriceSummary(),
        ],
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.ivoryWhite;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.softBeige;
    final shadowCol = isDark 
        ? Colors.black.withValues(alpha: 0.2)
        : AppColors.espressoBrown.withValues(alpha: 0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowCol,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail — fixed 90×90 square with warm ivory bg
            SizedBox(
              width: 90,
              height: 90,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkInputFill : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ProductImage(
                    url: line.product.thumbnail,
                    fit: BoxFit.contain,
                    width: 90,
                    height: 90,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Details — same order as original: name → color/size → price → qty+remove
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    line.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${line.product.color} • ${line.product.size}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                  ),
                  const SizedBox(height: 6),
                  PriceRow(product: line.product),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QuantityStepper(
                        quantity: line.quantity,
                        max: line.product.stock,
                        onChanged: (qty) => context
                            .read<AppState>()
                            .setCartQuantity(line.product.productId, qty),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context
                            .read<AppState>()
                            .removeFromCart(line.product.productId),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              AppColors.leatherBrown.withValues(alpha: 0.75),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Remove'),
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

class _PriceSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.ivoryWhite;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.softBeige;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            _row(context, 'Subtotal', inr(state.cartSubtotal)),
            _row(context, 'Delivery', state.deliveryFee == 0 ? 'Free' : inr(state.deliveryFee)),
            if (state.cartDiscount > 0)
              _row(context, 'Coupon savings', '-${inr(state.cartDiscount)}', positive: true),
            Divider(height: 24, color: AppColors.softBeige),
            _row(context, 'Total', inr(state.cartTotal), bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false, bool positive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? const Color(0xff9E8E7E) : AppColors.secondaryText;
    final mainCol = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? mainCol : textCol,
              fontSize: bold ? 15 : 13,
            ),
          )),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: positive ? AppColors.successGreen : (bold ? AppColors.leatherBrown : mainCol),
              fontSize: bold ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final address = _selectedAddress(state);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: state.cart.isEmpty
                ? null
                : () => address == null ? context.push('/add-address') : context.push('/payment-method'),
            child: Text(address == null ? 'Add Delivery Address' : 'Select Payment • ${inr(state.cartTotal)}'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(address?.name ?? 'Add delivery address'),
              subtitle: Text(address?.shortLabel ?? 'Enter your address after checkout to continue.'),
              trailing: TextButton(
                onPressed: () => context.push(address == null ? '/add-address' : '/addresses'),
                child: Text(address == null ? 'Add' : 'Change'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _CouponSection(
            appliedCoupon: state.appliedCoupon,
            cartDiscount: state.cartDiscount,
            onApply: (code) => context.read<AppState>().applyCoupon(code),
            onRemove: () => context.read<AppState>().removeCoupon(),
          ),
          const SizedBox(height: 10),
          ...state.cart.map((line) => _CartLineCard(line: line)),
          _PriceSummary(),
        ],
      ),
    );
  }
}

// ── Interactive coupon entry / applied coupon card ─────────────────────────
// Data is passed as constructor params from CheckoutScreen (which already
// watches AppState) to avoid double-watch that blanks the body on mobile.
class _CouponSection extends StatefulWidget {
  const _CouponSection({
    required this.appliedCoupon,
    required this.cartDiscount,
    required this.onApply,
    required this.onRemove,
  });

  final Coupon? appliedCoupon;
  final int cartDiscount;
  final String? Function(String code) onApply;
  final VoidCallback onRemove;

  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a coupon code');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final err = widget.onApply(code);
    setState(() { _loading = false; _error = err; });
    if (err == null) _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final applied = widget.appliedCoupon;

    // ── Applied state ───────────────────────────────────────────────────────
    if (applied != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.local_offer, color: Color(0xff12833b)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffe6f4ea),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xff12833b)),
                ),
                child: Text(
                  applied.code,
                  style: const TextStyle(
                    color: Color(0xff12833b),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('applied', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          subtitle: Text(
            'You saved ${inr(widget.cartDiscount)} on this order!',
            style: const TextStyle(color: Color(0xff12833b), fontWeight: FontWeight.w600),
          ),
          trailing: TextButton.icon(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
      );
    }

    // ── Entry state ─────────────────────────────────────────────────────────
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 20),
                const SizedBox(width: 8),
                const Text('Have a coupon?', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter coupon code (e.g. MOSPL30)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                errorText: _error,
              ),
              onSubmitted: (_) => _apply(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _loading ? null : _apply,
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Apply Coupon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    // Always do a background refresh when the screen opens.
    // Cached addresses show instantly; the network fetch updates silently.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addresses = context.watch<AppState>().addresses;
    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-address'),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().loadAddresses(),
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: addresses.isEmpty ? 1 : addresses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (addresses.isEmpty) {
              return EmptyState(
                icon: Icons.location_on_outlined,
                title: 'No address saved',
                subtitle: 'Add your delivery address to continue checkout.',
                actionLabel: 'Add Address',
                onAction: () => context.push('/add-address'),
              );
            }
            final address = addresses[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardBg = isDark ? AppColors.darkCard : AppColors.ivoryWhite;
            final borderCol = isDark ? AppColors.darkBorder : AppColors.softBeige;
            final shadowCol = isDark 
                ? Colors.black.withValues(alpha: 0.15)
                : AppColors.espressoBrown.withValues(alpha: 0.05);

            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: shadowCol,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkInputFill : const Color(0xffF5EDE3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.home_outlined, color: isDark ? const Color(0xffD4B896) : AppColors.leatherBrown, size: 20),
                ),
                title: Text(
                  address.name,
                  style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${address.line1}, ${address.line2}\n${address.city}, ${address.state} - ${address.pincode}\n${address.phone}',
                    style: const TextStyle(height: 1.4),
                  ),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (address.isDefault) const OfferBadge(text: 'Default'),
                    IconButton(
                      tooltip: 'Delete address',
                      onPressed: () => context.read<AppState>().deleteAddress(address.id),
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.errorRed.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  bool _default = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Address')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_name, 'Full name', Icons.person_outline),
          _field(
            _phone,
            'Phone for delivery only',
            Icons.call_outlined,
            keyboard: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          _field(_line1, 'House / building / street', Icons.home_outlined),
          _field(_line2, 'Area / landmark', Icons.map_outlined),
          Row(
            children: [
              Expanded(child: _field(_city, 'City', Icons.location_city_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _field(_state, 'State', Icons.map_outlined)),
            ],
          ),
          _field(
            _pincode,
            'Pincode',
            Icons.pin_drop_outlined,
            keyboard: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          SwitchListTile(
            value: _default,
            onChanged: (value) => setState(() => _default = value),
            title: const Text('Make default address'),
          ),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: () async {
              final error = _validateAddress();
              if (error != null) {
                setState(() => _error = error);
                return;
              }
              try {
                await context.read<AppState>().addAddress(
                      ShippingAddress(
                        id: const Uuid().v4(),
                        name: _name.text.trim().isEmpty ? 'MOSPL Customer' : _name.text.trim(),
                        phone: _phone.text.trim(),
                        line1: _line1.text.trim(),
                        line2: _line2.text.trim(),
                        city: _city.text.trim(),
                        state: _state.text.trim(),
                        pincode: _pincode.text.trim(),
                        isDefault: _default,
                      ),
                    );
                if (context.mounted) context.pop();
              } catch (error) {
                setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
              }
            },
            child: const Text('Save Address'),
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      ),
    );
  }

  String? _validateAddress() {
    if (_name.text.trim().isEmpty) return 'Enter your full name.';
    
    final phone = _phone.text.trim();
    if (phone.isEmpty) return 'Enter a delivery contact number.';
    if (phone.length != 10 || !RegExp(r'^\d+$').hasMatch(phone)) {
      return 'Invalid phone number';
    }
    
    if (_line1.text.trim().isEmpty) return 'Enter house, building, or street details.';
    if (_city.text.trim().isEmpty) return 'Enter your city.';
    if (_state.text.trim().isEmpty) return 'Enter your state.';
    
    final pincode = _pincode.text.trim();
    if (pincode.isEmpty) return 'Enter your pincode.';
    if (pincode.length != 6 || !RegExp(r'^\d+$').hasMatch(pincode)) {
      return 'Invalid pincode';
    }
    
    return null;
  }
}

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedMethod = 'Razorpay';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final address = _selectedAddress(state);
    if (address == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Method')),
        body: EmptyState(
          icon: Icons.location_on_outlined,
          title: 'Add delivery address',
          subtitle: 'Please add your address before selecting payment.',
          actionLabel: 'Add Address',
          onAction: () => context.push('/add-address'),
        ),
      );
    }

    final isRazorpay = _selectedMethod == 'Razorpay';
    final isCOD = _selectedMethod == 'COD';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select how you want to pay',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Razorpay Card
            GestureDetector(
              onTap: () => setState(() => _selectedMethod = 'Razorpay'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRazorpay ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    width: isRazorpay ? 2.5 : 1,
                  ),
                  color: isRazorpay
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: isRazorpay
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        isRazorpay ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isRazorpay ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Razorpay Test Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isRazorpay ? Theme.of(context).colorScheme.primary : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use INR only. Test card: 4111 1111 1111 1111',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.payment_outlined,
                        color: isRazorpay ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // COD Card
            GestureDetector(
              onTap: () => setState(() => _selectedMethod = 'COD'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCOD ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    width: isCOD ? 2.5 : 1,
                  ),
                  color: isCOD
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: isCOD
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        isCOD ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isCOD ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash on Delivery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCOD ? Theme.of(context).colorScheme.primary : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pay with cash upon delivery of your order.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.local_shipping_outlined,
                        color: isCOD ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: state.cart.isEmpty
                  ? null
                  : () async {
                      try {
                        if (_selectedMethod == 'Razorpay') {
                          final order = await context.read<AppState>().placeOrder(address: address, paymentMethod: 'Razorpay');
                          if (context.mounted) context.push('/razorpay-payment/${order.orderId}');
                        } else {
                          // Cash on Delivery
                          final order = await context.read<AppState>().placeOrder(address: address, paymentMethod: 'COD');
                          if (context.mounted) {
                            context.go('/track-order/${order.orderId}');
                          }
                        }
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
                        );
                      }
                    },
              child: Text(
                _selectedMethod == 'Razorpay'
                    ? 'Continue to Razorpay • ${inr(state.cartTotal)}'
                    : 'Confirm COD Order • ${inr(state.cartTotal)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RazorpayPaymentScreen extends StatefulWidget {
  const RazorpayPaymentScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<RazorpayPaymentScreen> createState() => _RazorpayPaymentScreenState();
}

class _RazorpayPaymentScreenState extends State<RazorpayPaymentScreen>
    with SingleTickerProviderStateMixin {
  late RazorpayService _service;
  final _cardNumberCtrl = TextEditingController(text: '4111 1111 1111 1111');
  final _expiryCtrl = TextEditingController(text: '12/27');
  final _cvvCtrl = TextEditingController(text: '123');
  final _nameCtrl = TextEditingController(text: 'Test User');
  bool _processing = false;
  bool _success = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _service = RazorpayService(
      onSuccess: (PaymentSuccessResponse response) async {
        final state = context.read<AppState>();
        final order = state.orders.firstWhere((item) => item.orderId == widget.orderId, orElse: () => _paymentFallbackOrder(state, widget.orderId));
        await state.verifyRazorpayPayment(
          orderId: widget.orderId, amount: order.total,
          razorpayOrderId: response.orderId ?? order.razorpayOrderId ?? 'order_test_local',
          razorpayPaymentId: response.paymentId ?? 'pay_local_',
          razorpaySignature: response.signature ?? 'local-signature',
        );
        if (mounted) _showSuccessAndNavigate();
      },
      onError: (PaymentFailureResponse response) {
        if (!mounted) return;
        context.read<AppState>().markPaymentFailed(widget.orderId);
        context.go('/track-order/${widget.orderId}');
      },
      onExternalWallet: (ExternalWalletResponse response) {},
    );
  }

  @override
  void dispose() {
    _service.dispose(); _scaleCtrl.dispose();
    _cardNumberCtrl.dispose(); _expiryCtrl.dispose();
    _cvvCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _processing = true);
    try {
      final state = context.read<AppState>();
      final order = state.orders.firstWhere((item) => item.orderId == widget.orderId, orElse: () => _paymentFallbackOrder(state, widget.orderId));
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      await state.verifyRazorpayPayment(
        orderId: widget.orderId, amount: order.total,
        razorpayOrderId: order.razorpayOrderId ?? 'order_test_local',
        razorpayPaymentId: 'pay_',
        razorpaySignature: 'local-signature',
      );
      if (mounted) _showSuccessAndNavigate();
    } catch (e) {
      if (mounted) { setState(() => _processing = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment error: '))); }
    }
  }

  void _showSuccessAndNavigate() {
    setState(() { _processing = false; _success = true; });
    _scaleCtrl.forward();
    Future<void>.delayed(const Duration(seconds: 2), () { if (mounted) context.go('/track-order/${widget.orderId}'); });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = state.orders.firstWhere((item) => item.orderId == widget.orderId, orElse: () => _paymentFallbackOrder(state, widget.orderId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_success) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(scale: _scaleAnim, child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(color: Colors.green.shade600, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 8)]),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 72),
          )),
          const SizedBox(height: 28),
          Text('Order Placed!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.green.shade700)),
          const SizedBox(height: 8),
          Text('Payment successful', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(order.orderId, style: theme.textTheme.bodySmall?.copyWith(color: cs.outline)),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text('Taking you to order tracking…', style: theme.textTheme.bodySmall),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Secure Payment'), elevation: 0),
      body: ListView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary, cs.primaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.totalLabel, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
              Text('Order ', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
              child: const Text('TEST MODE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.amber.shade50, border: Border.all(color: Colors.amber.shade300), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Expanded(child: Text('Test mode: fields are pre-filled. Just tap Pay Now.', style: TextStyle(fontSize: 12, color: Colors.amber.shade900))),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          height: 160, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xff1a1a2e), Color(0xff16213e)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Icon(Icons.wifi, color: Colors.white54, size: 24),
              Row(children: [
                Container(width: 28, height: 28, decoration: const BoxDecoration(color: Color(0xffEB001B), shape: BoxShape.circle)),
                Transform.translate(offset: const Offset(-10, 0), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xffF79E1B).withValues(alpha: 0.85), shape: BoxShape.circle))),
              ]),
            ]),
            const Spacer(),
            Text(_cardNumberCtrl.text.isEmpty ? '•••• •••• •••• ••••' : _cardNumberCtrl.text,
                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CARD HOLDER', style: TextStyle(color: Colors.white54, fontSize: 9)),
                Text(_nameCtrl.text.isEmpty ? 'FULL NAME' : _nameCtrl.text.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 9)),
                Text(_expiryCtrl.text.isEmpty ? 'MM/YY' : _expiryCtrl.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        Text('Card Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Cardholder Name', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true), onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        TextField(controller: _cardNumberCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Card Number', prefixIcon: const Icon(Icons.credit_card), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true), onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _expiryCtrl, keyboardType: TextInputType.datetime, decoration: InputDecoration(labelText: 'Expiry (MM/YY)', prefixIcon: const Icon(Icons.calendar_month_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true), onChanged: (_) => setState(() {}))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _cvvCtrl, keyboardType: TextInputType.number, obscureText: true, decoration: InputDecoration(labelText: 'CVV', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true))),
        ]),
        const SizedBox(height: 28),
        SizedBox(height: 54, child: ElevatedButton(
          onPressed: _processing ? null : _pay,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 4),
          child: _processing
              ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 12),
                  Text('Processing Payment…', style: TextStyle(fontSize: 16)),
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock, size: 20),
                  const SizedBox(width: 8),
                  Text('Pay Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
        )),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.verified_user_outlined, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text('256-bit SSL Encrypted', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700)),
          const SizedBox(width: 16),
          const Icon(Icons.security, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text('Powered by Razorpay', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700)),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Order placed successfully',
        subtitle: '$orderId is confirmed. You can track it from My Orders.',
        actionLabel: 'Track Order',
        onAction: () => context.go('/track-order/$orderId'),
      ),
    );
  }
}

class OrderFailedScreen extends StatelessWidget {
  const OrderFailedScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.error_outline,
        title: 'Payment failed',
        subtitle: 'Your Razorpay test payment did not complete for $orderId.',
        actionLabel: 'Track Order',
        onAction: () => context.go('/track-order/$orderId'),
      ),
    );
  }
}

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppState>().orders;
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your MOSPL purchases will appear here.',
              actionLabel: 'Start Shopping',
              onAction: () => context.go('/home'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    leading: SizedBox(width: 52, height: 52, child: ProductImage(url: order.items.first.product.thumbnail, fit: BoxFit.contain)),
                    title: Text(order.orderId),
                    subtitle: Text('${order.items.length} items • ${order.status} • ${order.paymentStatus}'),
                    trailing: Text(order.totalLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
                    onTap: () => context.push('/order-details/${order.orderId}'),
                  ),
                );
              },
            ),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = state.orders.firstWhere((item) => item.orderId == orderId, orElse: () => state.orders.isEmpty ? _emptyOrder(state) : state.orders.first);
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(order.orderId),
              subtitle: Text('${order.status} • ${order.paymentMethod} • ${order.paymentStatus}'),
              trailing: Text(order.totalLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(order.address.name),
              subtitle: Text(order.address.shortLabel),
            ),
          ),
          const SectionHeader(title: 'Items'),
          ...order.items.map((line) => _CartLineCard(line: line)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => context.push('/track-order/${order.orderId}'),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Track Order'),
          ),
        ],
      ),
    );
  }

  AppOrder _emptyOrder(AppState state) {
    final product = state.allProducts.first;
    return AppOrder(
      orderId: orderId,
      items: [CartLine(product: product, quantity: 1)],
      address: _selectedAddress(state) ?? _placeholderAddress,
      status: 'Draft',
      paymentStatus: 'Pending',
      paymentMethod: 'Razorpay',
      total: product.price,
      createdAt: DateTime.now(),
    );
  }
}

ShippingAddress? _selectedAddress(AppState state) {
  if (state.addresses.isEmpty) return null;
  return state.addresses.firstWhere((item) => item.isDefault, orElse: () => state.addresses.first);
}

const _placeholderAddress = ShippingAddress(
  id: 'address-placeholder',
  name: 'Address not added',
  phone: 'Not Specified',
  line1: 'Not Specified',
  line2: '',
  city: 'Not Specified',
  state: 'Not Specified',
  pincode: 'Not Specified',
);

AppOrder _paymentFallbackOrder(AppState state, String orderId) {
  final product = state.allProducts.first;
  return AppOrder(
    orderId: orderId,
    items: [CartLine(product: product, quantity: 1)],
    address: _selectedAddress(state) ?? _placeholderAddress,
    status: 'Draft',
    paymentStatus: 'Pending',
    paymentMethod: 'Razorpay',
    total: product.price,
    createdAt: DateTime.now(),
  );
}

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final state = context.watch<AppState>();
    final order = state.orders.firstWhere((item) => item.orderId == orderId, orElse: () => _paymentFallbackOrder(state, orderId));
    final steps = const [
      ('Confirmed', 'Order received'),
      ('Packed', 'Leather product quality checked'),
      ('Shipped', 'Picked up by delivery partner'),
      ('Delivered', 'Arriving in 5 days'),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Track Order'),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Go to Home'),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(order.orderId),
                subtitle: Text('${order.status} - ${order.paymentMethod} - ${order.paymentStatus}'),
                trailing: Text(order.totalLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(steps.length, (index) {
              final isPaymentPaid = order.paymentStatus == 'Paid';
              final isPaymentFailed = order.paymentStatus == 'Failed';
              
              final statusOrder = ['Confirmed', 'Packed', 'Shipped', 'Delivered'];
              final currentStatusIndex = statusOrder.indexOf(order.status);
              
              bool done = false;
              bool failed = false;
              
              if (order.status == 'Cancelled') {
                if (index == 0) {
                  failed = true;
                }
              } else if (index == 0) {
                if (isPaymentFailed) {
                  failed = true;
                } else {
                  done = true;
                }
              } else {
                if (isPaymentPaid && currentStatusIndex >= index) {
                  done = true;
                }
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: failed
                            ? const Color(0xffd32f2f)
                            : (done ? const Color(0xff12833b) : Colors.grey.shade300),
                        child: Icon(
                          failed
                              ? Icons.close
                              : (done ? Icons.check : Icons.circle),
                          size: 14,
                          color: (failed || done) ? Colors.white : Colors.grey,
                        ),
                      ),
                      if (index != steps.length - 1)
                        Container(
                          width: 2,
                          height: 58,
                          color: done ? const Color(0xff12833b) : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[index].$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(order.status == 'Cancelled'
                              ? 'Order Cancelled - $orderId'
                              : (failed
                                  ? 'Payment failed for this order - $orderId'
                                  : '${steps[index].$2} - $orderId')),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
