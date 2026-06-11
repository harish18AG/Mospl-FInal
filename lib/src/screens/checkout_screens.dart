import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../services/razorpay_service.dart';
import '../state/app_state.dart';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, height: 90, child: ProductImage(url: line.product.thumbnail, fit: BoxFit.contain)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${line.product.color} • ${line.product.size}'),
                  const SizedBox(height: 6),
                  PriceRow(product: line.product),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QuantityStepper(
                        quantity: line.quantity,
                        onChanged: (qty) => context.read<AppState>().setCartQuantity(line.product.productId, qty),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.read<AppState>().removeFromCart(line.product.productId),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _row('Subtotal', inr(state.cartSubtotal)),
            _row('Delivery', state.deliveryFee == 0 ? 'Free' : inr(state.deliveryFee)),
            _row('Coupon savings', '-${inr(state.cartDiscount)}', positive: true),
            const Divider(height: 24),
            _row('Total', inr(state.cartTotal), bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool positive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.normal))),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: positive ? const Color(0xff12833b) : null,
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: const Text('MOSPL30 applied'),
              subtitle: Text('You saved ${inr(state.cartDiscount)} on this order.'),
            ),
          ),
          const SizedBox(height: 10),
          ...state.cart.map((line) => _CartLineCard(line: line)),
          _PriceSummary(),
        ],
      ),
    );
  }
}

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

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
            return Card(
              child: ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(address.name),
                subtitle: Text('${address.line1}, ${address.line2}\n${address.city}, ${address.state} - ${address.pincode}\n${address.phone}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (address.isDefault) const OfferBadge(text: 'Default'),
                    IconButton(
                      tooltip: 'Delete address',
                      onPressed: () => context.read<AppState>().deleteAddress(address.id),
                      icon: const Icon(Icons.delete_outline),
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
          _field(_phone, 'Phone for delivery only', Icons.call_outlined, keyboard: TextInputType.phone),
          _field(_line1, 'House / building / street', Icons.home_outlined),
          _field(_line2, 'Area / landmark', Icons.map_outlined),
          Row(
            children: [
              Expanded(child: _field(_city, 'City', Icons.location_city_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _field(_state, 'State', Icons.map_outlined)),
            ],
          ),
          _field(_pincode, 'Pincode', Icons.pin_drop_outlined, keyboard: TextInputType.number),
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

  Widget _field(TextEditingController controller, String label, IconData icon, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      ),
    );
  }

  String? _validateAddress() {
    if (_name.text.trim().isEmpty) return 'Enter your full name.';
    if (_phone.text.trim().isEmpty) return 'Enter a delivery contact number.';
    if (_line1.text.trim().isEmpty) return 'Enter house, building, or street details.';
    if (_city.text.trim().isEmpty) return 'Enter your city.';
    if (_state.text.trim().isEmpty) return 'Enter your state.';
    if (_pincode.text.trim().isEmpty) return 'Enter your pincode.';
    return null;
  }
}

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Method')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.radio_button_checked),
              title: Text('Razorpay Test Mode'),
              subtitle: Text('Use INR only. Test card: 4111 1111 1111 1111'),
              trailing: Icon(Icons.payment_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Cash on Delivery disabled'),
              subtitle: const Text('Secure INR checkout through Razorpay.'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: state.cart.isEmpty
                ? null
                : () async {
                    try {
                      final order = await context.read<AppState>().placeOrder(address: address, paymentMethod: 'Razorpay');
                      if (context.mounted) context.push('/razorpay-payment/${order.orderId}');
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
                      );
                    }
                  },
            child: Text('Continue to Razorpay • ${inr(state.cartTotal)}'),
          ),
        ],
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

class _RazorpayPaymentScreenState extends State<RazorpayPaymentScreen> {
  late RazorpayService _service;

  @override
  void initState() {
    super.initState();
    _service = RazorpayService(
      onSuccess: (PaymentSuccessResponse response) async {
        final state = context.read<AppState>();
        final order = state.orders.firstWhere((item) => item.orderId == widget.orderId, orElse: () => _paymentFallbackOrder(state, widget.orderId));
        await state.verifyRazorpayPayment(
          orderId: widget.orderId,
          amount: order.total,
          razorpayOrderId: response.orderId ?? order.razorpayOrderId ?? 'order_test_local',
          razorpayPaymentId: response.paymentId ?? 'pay_local_${DateTime.now().millisecondsSinceEpoch}',
          razorpaySignature: response.signature ?? 'local-signature',
        );
        if (mounted) context.go('/order-success/${widget.orderId}');
      },
      onError: (PaymentFailureResponse response) {
        if (mounted) context.go('/order-failed/${widget.orderId}');
      },
      onExternalWallet: (ExternalWalletResponse response) {},
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = state.orders.firstWhere((item) => item.orderId == widget.orderId, orElse: () => _paymentFallbackOrder(state, widget.orderId));
    final user = state.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Razorpay Payment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.payments_outlined, size: 72),
          const SizedBox(height: 18),
          Text(order.totalLabel, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Order ${order.orderId} • INR only'),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Test card'),
              subtitle: Text('4111 1111 1111 1111 • Any future date • Any CVV'),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () async {
              final payment = await context.read<AppState>().createRazorpayOrder(order);
              final razorpayOrder = (payment['razorpayOrder'] as Map? ?? const {}).cast<String, dynamic>();
              _service.openCheckout(
                amountInRupees: order.total,
                orderId: (razorpayOrder['id'] ?? order.razorpayOrderId ?? 'order_test_local').toString(),
                keyId: (payment['keyId'] ?? 'rzp_test_1234567890abcdef').toString(),
                name: user?.name ?? 'MOSPL Customer',
                email: user?.email ?? 'shopper@mospl.test',
                contact: order.address.phone,
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Razorpay Test Checkout'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              await context.read<AppState>().verifyRazorpayPayment(
                    orderId: order.orderId,
                    amount: order.total,
                    razorpayOrderId: order.razorpayOrderId ?? 'order_test_local',
                    razorpayPaymentId: 'pay_sim_${DateTime.now().millisecondsSinceEpoch}',
                    razorpaySignature: 'local-signature',
                  );
              if (context.mounted) context.go('/order-success/${order.orderId}');
            },
            child: const Text('Simulate Success'),
          ),
          TextButton(
            onPressed: () => context.go('/order-failed/${order.orderId}'),
            child: const Text('Simulate Failed Payment'),
          ),
        ],
      ),
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
        actionLabel: 'View Order',
        onAction: () => context.go('/order-details/$orderId'),
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
        actionLabel: 'Retry Payment',
        onAction: () => context.go('/razorpay-payment/$orderId'),
      ),
    );
  }
}

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

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

class TrackOrderScreen extends StatelessWidget {
  const TrackOrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final steps = const [
      ('Confirmed', 'Order received'),
      ('Packed', 'Leather product quality checked'),
      ('Shipped', 'Picked up by delivery partner'),
      ('Delivered', 'Arriving in 5 days'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final done = index < 2;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: done ? const Color(0xff12833b) : Colors.grey.shade300,
                    child: Icon(done ? Icons.check : Icons.circle, size: 14, color: done ? Colors.white : Colors.grey),
                  ),
                  if (index != steps.length - 1)
                    Container(width: 2, height: 58, color: done ? const Color(0xff12833b) : Colors.grey.shade300),
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
                      Text('${steps[index].$2} • $orderId'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
