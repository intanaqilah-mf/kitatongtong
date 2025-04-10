import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final Map<String, dynamic> donationData;

  const PaymentWebView({
    Key? key,
    required this.paymentUrl,
    required this.donationData,
  }) : super(key: key);

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (uri.scheme == 'myapp' && uri.host == 'payment-result') {
              final status = uri.queryParameters['status'];
              if (status == 'success') {
                Navigator.pushReplacementNamed(context, '/successPay',
                    arguments: widget.donationData);
              } else if (status == 'fail') {
                Navigator.pushReplacementNamed(context, '/failPay',
                    arguments: widget.donationData);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
