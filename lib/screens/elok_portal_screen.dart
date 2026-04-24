import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_screen.dart';

class ElokPortalScreen extends StatefulWidget {
  const ElokPortalScreen({super.key});

  @override
  State<ElokPortalScreen> createState() => _ElokPortalScreenState();
}

class _ElokPortalScreenState extends State<ElokPortalScreen> {
  double _progress = 0;
  InAppWebViewController? _webViewController;

  // Whitelist domain yang allowed
  final List<String> _allowedDomains = [
    'elok.ugm.ac.id',
    'simaster.ugm.ac.id', // kalo ada integration
    'sso.ugm.ac.id', // single sign-on UGM
    // tambahin domain UGM lain yang trusted
  ];

  bool _isAllowedUrl(Uri? uri) {
    if (uri == null) return false;

    // Check kalo domain ada di whitelist
    return _allowedDomains.any(
      (domain) => uri.host == domain || uri.host.endsWith('.$domain'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Portal eLOK UGM"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri("https://elok.ugm.ac.id"),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              javaScriptCanOpenWindowsAutomatically: true,
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              useOnDownloadStart: true,
              supportZoom: true,
              builtInZoomControls: true,
              displayZoomControls: false,

              // FIX: Matiin file access
              allowFileAccessFromFileURLs: false,
              allowUniversalAccessFromFileURLs: false,

              // FIX: Lebih strict di mixed content
              mixedContentMode:
                  MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,

              // Tambahin security features
              clearCache: false,
              cacheEnabled: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },

            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var uri = navigationAction.request.url;

              // VALIDASI URL DULU!
              if (uri != null && !_isAllowedUrl(uri)) {
                // Kalo bukan domain yang diallow, kasih warning
                if (context.mounted) {
                  final shouldOpen = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('⚠️ Link Eksternal'),
                      content: Text(
                        'Link ini mengarah ke ${uri.host} yang bukan bagian dari portal UGM.\n\n'
                        'Tetap buka?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Buka di Browser'),
                        ),
                      ],
                    ),
                  );

                  if (shouldOpen == true) {
                    // Buka di browser eksternal, jangan di WebView
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                }
                return NavigationActionPolicy.CANCEL;
              }

              // PDF handling (tetap sama)
              if (uri != null && uri.path.toLowerCase().endsWith(".pdf")) {
                CookieManager cookieManager = CookieManager.instance();
                List<Cookie> cookies = await cookieManager.getCookies(
                  url: WebUri("https://elok.ugm.ac.id"),
                );

                String cookieString = cookies
                    .map((c) => "${c.name}=${c.value}")
                    .join("; ");

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(
                        pdfUrl: uri.toString(),
                        cookie: cookieString,
                      ),
                    ),
                  );
                }
                return NavigationActionPolicy.CANCEL;
              }

              return NavigationActionPolicy.ALLOW;
            },

            // Tambahin error handling!
            onLoadError: (controller, url, code, message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading page: $message'),
                  backgroundColor: Colors.red,
                ),
              );
            },

            onDownloadStartRequest: (controller, downloadStartRequest) async {
              var url = downloadStartRequest.url;

              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Gak bisa buka link download-nya!"),
                    ),
                  );
                }
              }
            },

            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
          ),
          if (_progress < 1.0)
            LinearProgressIndicator(value: _progress, color: Colors.orange),
        ],
      ),
    );
  }
}
