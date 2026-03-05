import 'package:flutter/material.dart';
import 'package:klarna_flutter/klarna_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klarna Flutter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const KlarnaPaymentScreen(),
    );
  }
}

/// Example screen demonstrating Klarna payment integration.
class KlarnaPaymentScreen extends StatefulWidget {
  const KlarnaPaymentScreen({super.key});

  @override
  State<KlarnaPaymentScreen> createState() => _KlarnaPaymentScreenState();
}

class _KlarnaPaymentScreenState extends State<KlarnaPaymentScreen> {
  final _clientTokenController = TextEditingController();

  // Return URL for Klarna - must match AndroidManifest.xml intent-filter
  static const String _returnUrl = 'klarna-flutter-example://klarna-return';

  @override
  void dispose() {
    _clientTokenController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openPaymentScreen() {
    final clientToken = _clientTokenController.text.trim();
    if (clientToken.isEmpty) {
      _showSnackBar('Please enter a client token');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KlarnaFullScreenPaymentView(
          clientToken: clientToken,
          returnUrl: _returnUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Klarna Payment Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Create a payment session on your server using Klarna\'s API\n'
                      '2. Copy the client_token from the response\n'
                      '3. Paste it below and tap Continue to Payment\n'
                      '4. The Klarna view will load in a new full screen\n'
                      '5. Authorize to complete the payment test',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Client token input
            TextField(
              controller: _clientTokenController,
              decoration: const InputDecoration(
                labelText: 'Client Token',
                hintText: 'Enter the client token from your server',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Action button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: _openPaymentScreen,
              child: const Text('Continue to Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class KlarnaFullScreenPaymentView extends StatefulWidget {
  final String clientToken;
  final String returnUrl;

  const KlarnaFullScreenPaymentView({
    super.key,
    required this.clientToken,
    required this.returnUrl,
  });

  @override
  State<KlarnaFullScreenPaymentView> createState() => _KlarnaFullScreenPaymentViewState();
}

class _KlarnaFullScreenPaymentViewState extends State<KlarnaFullScreenPaymentView> {
  final _paymentViewKey = GlobalKey<KlarnaPaymentViewState>();
  
  String _status = 'Initializing...';
  bool _isLoading = true;
  String? _authToken;

  void _updateStatus(String status) {
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _authorize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _paymentViewKey.currentState?.authorize();
      _updateStatus('Authorizing...');
    } catch (e) {
      _updateStatus('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             color: Colors.grey[200],
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Status: $_status', style: const TextStyle(fontWeight: FontWeight.bold)),
                 if (_authToken != null) ...[
                   const SizedBox(height: 4),
                   Text('Auth Token: ${_authToken!.substring(0, 15)}...', style: const TextStyle(fontSize: 12)),
                 ]
               ]
             )
          ),
          
          Expanded(
            child: Stack(
              children: [
                KlarnaPaymentView(
                  key: _paymentViewKey,
                  category: 'klarna',
                  returnUrl: widget.returnUrl,
                  onCreated: (state) {
                    _updateStatus('Creating payment view...');
                    state.initialize(widget.clientToken);
                  },
                  onInitialized: () {
                    debugPrint('>>> onInitialized callback fired');
                    _updateStatus('Initialized. Loading view...');
                    // Auto load after init
                    _paymentViewKey.currentState?.load();
                  },
                  onLoaded: () {
                    debugPrint('>>> onLoaded callback fired');
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                    _updateStatus('Payment view ready');
                  },
                  onLoadPaymentReview: (showForm) {
                    _updateStatus('Payment review loaded');
                  },
                  onAuthorized: (result) {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _authToken = result.authToken;
                      });
                    }
                    if (result.approved) {
                      _updateStatus('Authorization approved!');
                      _showSnackBar('Payment authorized successfully');
                      // In a real app, you might pop back to the previous screen here
                      // Navigator.pop(context, result.authToken);
                    } else {
                      _updateStatus('Authorization not approved');
                      _showSnackBar('Payment was not approved');
                    }
                  },
                  onReauthorized: (result) {
                    _updateStatus('Reauthorization: ${result.approved ? 'approved' : 'failed'}');
                  },
                  onFinalized: (result) {
                    _updateStatus('Finalization: ${result.approved ? 'approved' : 'failed'}');
                  },
                  onError: (error) {
                    debugPrint('>>> onError callback: ${error.name} - ${error.message}');
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                    _updateStatus('Error: ${error.message}');
                    _showSnackBar('Error: ${error.message}');
                  },
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            onPressed: _isLoading ? null : _authorize,
            child: const Text('Authorize Payment'),
          ),
        ),
      ),
    );
  }
}

