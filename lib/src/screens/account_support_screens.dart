import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                child: Text((user?.name ?? 'M').substring(0, 1).toUpperCase()),
              ),
              title: Text(user?.name ?? 'Guest Shopper'),
              subtitle: Text(user?.email ?? 'Sign in with email/password'),
              trailing: TextButton(onPressed: () => context.push('/edit-profile'), child: const Text('Edit')),
            ),
          ),
          const SizedBox(height: 12),
          _menu(context, Icons.receipt_long_outlined, 'My Orders', '/my-orders'),
          _menu(context, Icons.favorite_border, 'Wishlist', '/wishlist'),
          _menu(context, Icons.location_on_outlined, 'Addresses', '/addresses'),
          _menu(context, Icons.notifications_none, 'Notifications', '/notifications'),
          _menu(context, Icons.local_offer_outlined, 'Offers', '/offers'),
          _menu(context, Icons.confirmation_number_outlined, 'Coupons', '/coupons'),
          _menu(context, Icons.smart_toy_outlined, 'AI Chatbot', '/ai-chatbot'),
          _menu(context, Icons.history, 'Recently Viewed', '/recently-viewed'),
          _menu(context, Icons.compare_arrows, 'Product Comparison', '/comparison'),
          _menu(context, Icons.assignment_return_outlined, 'Returns', '/returns'),
          _menu(context, Icons.support_agent, 'Support Tickets', '/support-tickets'),
          _menu(context, Icons.settings_outlined, 'Settings', '/settings'),
          _menu(context, Icons.help_outline, 'Help Center', '/help-center'),
          if (user?.isAdmin == true)
            _menu(context, Icons.admin_panel_settings_outlined, 'Admin Dashboard', '/admin/dashboard'),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AppState>().logout();
              if (context.mounted) context.go('/signin');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, IconData icon, String title, String route) {
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
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), labelText: 'Email')),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () async {
              await context.read<AppState>().updateProfile(name: _name.text, email: _email.text);
              if (context.mounted) context.pop();
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              labelText: 'New password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _confirm, obscureText: _obscure, decoration: const InputDecoration(prefixIcon: Icon(Icons.verified_outlined), labelText: 'Confirm password')),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () async {
              if (_password.text != _confirm.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              final appState = context.read<AppState>();
              final ok = await appState.changePassword(_password.text);
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(appState.authError ?? 'Password could not be updated.')),
                );
                return;
              }
              context.pop();
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            value: state.darkMode,
            onChanged: (_) => context.read<AppState>().toggleDarkMode(),
            title: const Text('Dark mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          SwitchListTile(
            value: state.notificationsEnabled,
            onChanged: context.read<AppState>().toggleNotifications,
            title: const Text('Notifications'),
            secondary: const Icon(Icons.notifications_none),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/change-password'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/terms'),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<AppState>().notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.isEmpty
          ? const EmptyState(icon: Icons.notifications_none, title: 'No notifications', subtitle: 'Offer and order updates will appear here.')
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Card(
                  child: ListTile(
                    leading: Icon(item.read ? Icons.notifications_none : Icons.notifications_active_outlined),
                    title: Text(item.title),
                    subtitle: Text(item.body),
                    trailing: Text('${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}'),
                    onTap: () => context.read<AppState>().markNotificationRead(item.id),
                  ),
                );
              },
            ),
    );
  }
}

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          _OfferCard(title: '30% OFF leather products', subtitle: 'Wallets, belts, passport holders and women wallets.'),
          _OfferCard(title: 'Free shipping', subtitle: 'Delivered by 5 days for all MOSPL products.'),
          _OfferCard(title: 'Women wallet savings', subtitle: 'Current women wallet listings at 30% off reference pricing.'),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.local_offer_outlined, color: Color(0xffff9800)),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coupons = context.watch<AppState>().coupons;
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: coupons.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('${coupon.description}\nMinimum order ${inr(coupon.minimumAmount)}'),
              isThreeLine: true,
              trailing: OfferBadge(text: '${coupon.discountPercent}% OFF'),
            ),
          );
        },
      ),
    );
  }
}

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Shopping Assistant'),
        actions: [
          IconButton(onPressed: () => context.push('/chat-history'), icon: const Icon(Icons.history)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: state.chatMessages.length + (_sending ? 1 : 0),
              itemBuilder: (context, rawIndex) {
                if (_sending && rawIndex == 0) return const _TypingBubble();
                final index = state.chatMessages.length - 1 - (rawIndex - (_sending ? 1 : 0));
                final message = state.chatMessages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: ['Recommend wallet', 'Passport holder', 'Track order', 'Return policy', 'Hand woven belt']
                  .map(
                    (prompt) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(label: Text(prompt), onPressed: () => _send(prompt)),
                    ),
                  )
                  .toList(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Ask for product or order help'),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() => _sending = true);
    await context.read<AppState>().sendChat(text);
    if (mounted) setState(() => _sending = false);
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = message.recommendedProductIds.map(state.productById).toList();
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor;
    final textColor = message.isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Text(message.text, style: TextStyle(color: textColor)),
        ),
        if (products.isNotEmpty)
          SizedBox(
            height: 158,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final product = products[index];
                return SizedBox(
                  width: 132,
                  child: Card(
                    child: InkWell(
                      onTap: () => context.push('/product/${product.productId}'),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Expanded(child: ProductImage(url: product.thumbnail, fit: BoxFit.contain)),
                            Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(product.priceLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
        child: const Text('MOSPL assistant is typing...'),
      ),
    );
  }
}

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<AppState>().chatMessages;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: messages.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final item = messages[index];
          return ListTile(
            leading: Icon(item.isUser ? Icons.person_outline : Icons.smart_toy_outlined),
            title: Text(item.text, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(item.createdAt.toString()),
          );
        },
      ),
    );
  }
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<AppState>().reviews;
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => const _ReviewDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Review'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().loadReviews(),
        child: reviews.isEmpty
            ? const EmptyState(
                icon: Icons.rate_review_outlined,
                title: 'No reviews yet',
                subtitle: 'Customer reviews will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: reviews.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.rate_review_outlined),
                      title: Text('${review.userName} - ${review.rating.toStringAsFixed(1)} stars'),
                      subtitle: Text(review.comment),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _comment = TextEditingController();
  String? _productId;
  double _rating = 5;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<AppState>().allProducts;
    _productId ??= products.first.productId;
    return AlertDialog(
      title: const Text('Add Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _productId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Product'),
              items: products
                  .take(60)
                  .map(
                    (product) => DropdownMenuItem(
                      value: product.productId,
                      child: Text(product.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _productId = value),
            ),
            const SizedBox(height: 12),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              allowHalfRating: true,
              itemSize: 30,
              itemBuilder: (context, _) => const Icon(Icons.star, color: Color(0xffff9800)),
              onRatingUpdate: (value) => _rating = value,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Review comment'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_comment.text.trim().isEmpty) {
              setState(() => _error = 'Enter your review comment.');
              return;
            }
            try {
              await context.read<AppState>().submitReview(
                    productId: _productId!,
                    rating: _rating,
                    comment: _comment.text.trim(),
                  );
              if (context.mounted) context.pop();
            } catch (error) {
              setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final products = app.allProducts.take(20).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Ratings')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final product = products[index];
          final liveRating = app.getProductLiveRating(product.productId);
          final liveReviewCount = app.getProductLiveReviewCount(product.productId);
          return Card(
            child: ListTile(
              leading: SizedBox(width: 54, height: 54, child: ProductImage(url: product.thumbnail, fit: BoxFit.contain)),
              title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${liveRating.toStringAsFixed(1)} stars • $liveReviewCount reviews'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/product/${product.productId}'),
            ),
          );
        },
      ),
    );
  }
}

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Returns')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.orders.isEmpty
            ? null
            : () => showDialog<void>(
                  context: context,
                  builder: (context) => const _ReturnDialog(),
                ),
        icon: const Icon(Icons.assignment_return_outlined),
        label: const Text('Request Return'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().loadReturns(),
        child: state.returnRequests.isEmpty
            ? EmptyState(
                icon: Icons.assignment_return_outlined,
                title: 'No return requests',
                subtitle: state.orders.isEmpty
                    ? 'Place an order first, then return requests can be raised here.'
                    : 'Tap Request Return to create one for an order.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: state.returnRequests.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = state.returnRequests[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment_return_outlined),
                      title: Text(item.orderId),
                      subtitle: Text(item.reason),
                      trailing: OfferBadge(text: item.status),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ReturnDialog extends StatefulWidget {
  const _ReturnDialog();

  @override
  State<_ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends State<_ReturnDialog> {
  final _reason = TextEditingController();
  String? _orderId;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppState>().orders;
    _orderId ??= orders.first.orderId;
    return AlertDialog(
      title: const Text('Request Return'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _orderId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Order'),
            items: orders
                .map(
                  (order) => DropdownMenuItem(
                    value: order.orderId,
                    child: Text('${order.orderId} - ${order.totalLabel}', overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _orderId = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_reason.text.trim().isEmpty) {
              setState(() => _error = 'Enter return reason.');
              return;
            }
            try {
              await context.read<AppState>().createReturnRequest(orderId: _orderId!, reason: _reason.text.trim());
              if (context.mounted) context.pop();
            } catch (error) {
              setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = context.watch<AppState>().supportTickets;
    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => const _SupportTicketDialog(),
        ),
        icon: const Icon(Icons.support_agent),
        label: const Text('New Ticket'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().loadSupportTickets(),
        child: tickets.isEmpty
            ? const EmptyState(
                icon: Icons.support_agent,
                title: 'No support tickets',
                subtitle: 'Create a ticket for order, return, payment, or product help.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: tickets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.support_agent),
                      title: Text(ticket.subject),
                      subtitle: Text(ticket.reply == null ? ticket.message : '${ticket.message}\nReply: ${ticket.reply}'),
                      isThreeLine: ticket.reply != null,
                      trailing: OfferBadge(text: ticket.status),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _SupportTicketDialog extends StatefulWidget {
  const _SupportTicketDialog();

  @override
  State<_SupportTicketDialog> createState() => _SupportTicketDialogState();
}

class _SupportTicketDialogState extends State<_SupportTicketDialog> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Support Ticket'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 12),
          TextField(controller: _message, maxLines: 3, decoration: const InputDecoration(labelText: 'Message')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
              setState(() => _error = 'Enter subject and message.');
              return;
            }
            try {
              await context.read<AppState>().createSupportTicket(
                    subject: _subject.text.trim(),
                    message: _message.text.trim(),
                  );
              if (context.mounted) context.pop();
            } catch (error) {
              setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class SimpleInfoScreen extends StatelessWidget {
  const SimpleInfoScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(icon, size: 70, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(line),
            ),
          ),
        ],
      ),
    );
  }
}
