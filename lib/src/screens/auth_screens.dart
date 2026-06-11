import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final state = context.read<AppState>();
      if (!state.hasOnboarded) {
        context.go('/onboarding/0');
      } else if (state.currentUser == null) {
        context.go('/signin');
      } else {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MosplLogo(size: 76),
            SizedBox(height: 14),
            Text('Leather shopping made simple'),
            SizedBox(height: 28),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.index});

  final int index;

  static const _items = [
    ('Shop MOSPL leather', 'Wallets, belts, passport holders, and women wallets.'),
    ('Fast Indian ecommerce flow', 'Search, filters, wishlist, cart, free shipping labels, offers and simple checkout.'),
    ('AI shopping help', 'Ask for product suggestions, order support, returns, and leather care tips.'),
  ];

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, _items.length - 1);
    final item = _items[safeIndex];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await context.read<AppState>().completeOnboarding();
                    if (context.mounted) context.go('/signin');
                  },
                  child: const Text('Skip'),
                ),
              ),
              const Spacer(),
              Image.asset('assets/banners/sale_banner.png', height: 210, fit: BoxFit.contain),
              const SizedBox(height: 28),
              Text(
                item.$1,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(item.$2, textAlign: TextAlign.center),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (dot) => Container(
                    width: dot == safeIndex ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: dot == safeIndex
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (safeIndex == _items.length - 1) {
                    await context.read<AppState>().completeOnboarding();
                    if (context.mounted) context.go('/signin');
                  } else {
                    context.go('/onboarding/${safeIndex + 1}');
                  }
                },
                child: Text(safeIndex == _items.length - 1 ? 'Start Shopping' : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.adminMode = false});

  final bool adminMode;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.adminMode ? 'Admin Login' : 'Sign In')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const MosplLogo(size: 50),
            const SizedBox(height: 24),
            Text(
              widget.adminMode ? 'Sign in to manage store' : 'Sign in with email and password',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), labelText: 'Email / Gmail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: (value) => setState(() => _remember = value ?? true),
                ),
                const Text('Remember me'),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            if (state.authError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(state.authError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ElevatedButton(
              onPressed: state.authLoading
                  ? null
                  : () async {
                      final appState = context.read<AppState>();
                      final ok = await appState.signIn(
                            email: _email.text,
                            password: _password.text,
                            remember: _remember,
                          );
                      if (!context.mounted || !ok) return;
                      if (widget.adminMode && appState.currentUser?.isAdmin != true) {
                        await appState.logout();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This account does not have admin access.')),
                        );
                        return;
                      }
                      context.go(widget.adminMode ? '/admin/dashboard' : '/home');
                    },
              child: state.authLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign In'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/signup'),
              child: const Text('Create new account'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const MosplLogo(size: 46),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), labelText: 'Email / Gmail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.verified_user_outlined), labelText: 'Confirm password'),
            ),
            CheckboxListTile(
              value: _remember,
              onChanged: (value) => setState(() => _remember = value ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('Remember me on this device'),
            ),
            if (state.authError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(state.authError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ElevatedButton(
              onPressed: state.authLoading
                  ? null
                  : () async {
                      final ok = await context.read<AppState>().signUp(
                            name: _name.text,
                            email: _email.text,
                            password: _password.text,
                            confirmPassword: _confirm.text,
                            remember: _remember,
                          );
                      if (!context.mounted || !ok) return;
                      context.go('/account-created');
                    },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 70),
          const SizedBox(height: 18),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), labelText: 'Email / Gmail'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final message = await context.read<AppState>().sendPasswordReset(_email.text);
              setState(() => _message = message);
            },
            child: const Text('Send Reset Link'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}

class AccountCreatedSuccessScreen extends StatelessWidget {
  const AccountCreatedSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Account created',
        subtitle: 'Your MOSPL account is ready for leather shopping.',
        actionLabel: 'Continue',
        onAction: () => context.go('/home'),
      ),
    );
  }
}
