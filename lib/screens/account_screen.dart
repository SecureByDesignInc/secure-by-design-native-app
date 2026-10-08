import 'package:flutter/material.dart';

import '../data/account.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.account});
  final AccountStore account;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.account.signIn(_email.text, _password.text);
    if (mounted) _password.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your account')),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: widget.account,
            builder: (context, _) {
              final account = widget.account;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Kicker('Stay curious. Keep learning.'),
                      const SizedBox(height: 16),
                      Text(
                        account.signedIn
                            ? 'Good to see you.'
                            : 'A familiar place to sign in.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Use your Secure By Design website account. Learning and saved progress remain available without signing in.',
                        style: TextStyle(color: SbdColors.muted, height: 1.6),
                      ),
                      const SizedBox(height: 24),
                      if (!account.signedIn) ...[
                        FilledButton.icon(
                          key: const ValueKey('browser-sign-in'),
                          onPressed: account.busy
                              ? null
                              : () => account.signInWithBrowser(),
                          icon: const Icon(Icons.key_outlined),
                          label: const Text(
                            'Continue with Apple, Google, Microsoft, or a passkey',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Opens a secure Secure By Design sign-in page, then returns here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: SbdColors.muted, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        const Row(children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or use your email and password',
                                style: TextStyle(color: SbdColors.muted, fontSize: 13)),
                          ),
                          Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 20),
                      ],
                      if (!account.signedIn)
                        Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _email,
                                enabled: !account.busy,
                                decoration: const InputDecoration(
                                  labelText: 'Email address',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    value != null && value.trim().contains('@')
                                        ? null
                                        : 'Enter your email address.',
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _password,
                                enabled: !account.busy,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    tooltip: _hidePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword,
                                    ),
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                obscureText: _hidePassword,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) {
                                  if (!account.busy) _signIn();
                                },
                                validator: (value) =>
                                    value != null && value.isNotEmpty
                                        ? null
                                        : 'Enter your password.',
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton(
                                onPressed: account.busy ? null : _signIn,
                                child: Text(
                                  account.busy ? 'Signing in…' : 'Sign in',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: account.busy
                                    ? null
                                    : () => openResource(
                                          context,
                                          'https://securebydesigninc.com/my-progress',
                                        ),
                                child: const Text(
                                  'Create an account or reset your password',
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (account.signedIn) ...[
                        Text(
                          account.email!,
                          style: const TextStyle(color: SbdColors.cyan),
                        ),
                        const SizedBox(height: 24),
                        const Panel(
                          child: Text(
                            'Welcome messages, learning tips, and feedback prompts appear inside the app. Email is reserved for account verification and password resets. Manage in-app reminders in My Account → Learning preferences.',
                            style: TextStyle(height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: account.busy
                              ? null
                              : () async {
                                  await account.signOut();
                                },
                          child: const Text('Sign out'),
                        ),
                      ],
                      if (account.error != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            account.error!,
                            style: const TextStyle(
                              color: SbdColors.cyan,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'This preview signs you out when you close the app or after 12 hours. Connect progress in My Account to sync your lessons and bookmarks. Device-only records are kept separately.',
                        style: TextStyle(
                          color: SbdColors.muted,
                          fontSize: 13,
                          height: 1.6,
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

