import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'strings.dart';
import 'ui/theme.dart';

/// How the Payment Web App closed. Either way, ask `IncomingPaymentsApi.getPayin` where the payment stands.
sealed class PaymentAppResult {
  const PaymentAppResult();
}

/// The Payment Web App sent the payer to `returnUrl`, with whatever it added to it.
final class PaymentAppReturned extends PaymentAppResult {
  const PaymentAppReturned(this.url);

  final Uri url;
}

/// The payer closed it first, or the app popped it.
final class PaymentAppClosed extends PaymentAppResult {
  const PaymentAppClosed();
}

/// True when [url] is the return URL, whatever query the Payment Web App added; a longer path is not.
bool isReturn(Uri url, Uri returnUrl) =>
    url.scheme == returnUrl.scheme &&
    url.host == returnUrl.host &&
    url.port == returnUrl.port &&
    url.path == returnUrl.path;

/// The link an Android `intent:` URL stands for, such as `upi://pay?pa=x` for `intent://pay?pa=x#Intent;scheme=upi;end`,
/// as url_launcher cannot open `intent:` itself. Null when it names no scheme.
// shortcut: drops the intent's package and extras, so any app claiming the scheme can take it, where native Android
// targets the package; add a platform channel with Intent.parseUri if a bank's link only works in its own app.
Uri? intentUrl(String url) {
  final hash = url.indexOf('#Intent;');
  if (!url.startsWith('intent:') || hash < 0) return null;
  final scheme = RegExp(
    r'(?:^|;)scheme=([A-Za-z][A-Za-z0-9+.-]*)(?=;|$)',
  ).firstMatch(url.substring(hash + 8))?.group(1);
  if (scheme == null ||
      const {'http', 'https', 'intent', 'javascript', 'file', 'content'}.contains(scheme.toLowerCase())) {
    return null;
  }
  return Uri.tryParse('$scheme:${url.substring('intent:'.length, hash)}');
}

/// Shows [url] full screen with a Close button, and completes when the payer reaches [returnUrl] or closes it.
Future<PaymentAppResult> showPaymentApp(
  BuildContext context,
  Uri url,
  Uri returnUrl, {
  VoidCallback? onPresented,
}) async {
  // A keyboard left open by the app would sit over the page.
  FocusManager.instance.primaryFocus?.unfocus();
  final result = await Navigator.of(context).push<PaymentAppResult>(
    MaterialPageRoute(
      fullscreenDialog: true, // a whole web checkout, so it gets the whole screen
      builder: (_) => _PaymentAppPage(url: url, returnUrl: returnUrl, onPresented: onPresented),
    ),
  );
  return result ?? const PaymentAppClosed();
}

class _PaymentAppPage extends StatefulWidget {
  const _PaymentAppPage({required this.url, required this.returnUrl, this.onPresented});

  final Uri url;
  final Uri returnUrl;
  final VoidCallback? onPresented;

  @override
  State<_PaymentAppPage> createState() => _PaymentAppPageState();
}

class _PaymentAppPageState extends State<_PaymentAppPage> {
  late final WebViewController _web;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            if (target == null) return NavigationDecision.prevent;
            if (isReturn(target, widget.returnUrl)) {
              _finish(PaymentAppReturned(target));
              return NavigationDecision.prevent;
            }
            if (const {'https', 'http', 'about'}.contains(target.scheme)) return NavigationDecision.navigate;
            // Bank and payment apps open outside the web view. If no app takes the link, the payer stays on the page.
            final outside = target.scheme == 'intent' ? intentUrl(request.url) : target;
            if (outside != null) {
              unawaited(launchUrl(outside, mode: LaunchMode.externalApplication).catchError((_) => false));
            }
            return NavigationDecision.prevent;
          },
          // Some platforms do not ask about every navigation (redirects, history changes), so the URL is checked again here.
          onUrlChange: (change) {
            final target = Uri.tryParse(change.url ?? '');
            if (target != null && isReturn(target, widget.returnUrl)) _finish(PaymentAppReturned(target));
          },
        ),
      )
      ..loadRequest(widget.url);
    // iOS: swiping from the edge steps back a page, as Back does on Android.
    final platform = _web.platform;
    if (platform is WebKitWebViewController) unawaited(platform.setAllowsBackForwardNavigationGestures(true));
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onPresented?.call());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A web view is opaque white by default, which shows around the page in dark mode.
    unawaited(_web.setBackgroundColor(SynqtColors.of(context).surface));
  }

  void _finish(PaymentAppResult result) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    return PopScope(
      canPop: false,
      // Back steps back through the web app's pages, and closes it from the first one.
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _web.canGoBack()) {
          await _web.goBack();
        } else {
          _finish(const PaymentAppClosed());
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          foregroundColor: colors.text,
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () => _finish(const PaymentAppClosed()),
              child: Text(
                text('synqt_sheet_close'),
                style: synqtFont(16, weight: FontWeight.w500, color: colors.action),
              ),
            ),
          ],
        ),
        body: WebViewWidget(controller: _web),
      ),
    );
  }
}
