import 'dart:io'; // Mengimpor pustaka dart:io untuk mendukung pengecekan platform sistem operasi
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
  bool _canGoBack = false;

  // Mendefinisikan daftar 'whitelist' domain yang aman dan berizin untuk diakses di dalam WebView
  final List<String> _allowedDomains = [
    'elok.ugm.ac.id',
    'simaster.ugm.ac.id', // Domain otentikasi/sistem terintegrasi
    'sso.ugm.ac.id', // Single Sign-On otentikasi UGM
    // Domain sekunder terverifikasi dari UGM dapat ditambahkan ke sini
  ];

  /// Memverifikasi pakah alamat URI (Uniform Resource Identifier) termasuk dalam daftar domain sah.
  bool _isAllowedUrl(Uri? uri) {
    if (uri == null) return false;

    // Memastikan kecocokan domain utama maupun sub-domain terkait
    return _allowedDomains.any(
      (domain) => uri.host == domain || uri.host.endsWith('.$domain'),
    );
  }

  Future<void> _updateCanGoBack() async {
    if (!mounted) return;
    final controller = _webViewController;
    if (controller == null) return;
    final canGoBack = await controller.canGoBack();
    if (!mounted) return;
    if (canGoBack == _canGoBack) return;
    setState(() {
      _canGoBack = canGoBack;
    });
  }

  Future<void> _handleBackPressed() async {
    final controller = _webViewController;
    if (controller != null && _canGoBack) {
      await controller.goBack();
      await _updateCanGoBack();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux || Platform.isWindows) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Portal eLOK"),
          backgroundColor: const Color(0xFF4A00E0),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            "WebView eLOK nggak disupport di Linux/Windows.\nHarus di-run di Emulator Android atau HP asli ya!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Portal eLOK UGM"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: _handleBackPressed,
        ),
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

              // Mengamankan WebView dengan memblokir izin akses sistem berkas (file system) dari URL
              allowFileAccessFromFileURLs: false,
              allowUniversalAccessFromFileURLs: false,

              // Menyesuaikan kebijakan konten campuran (HTTP/HTTPS) agar berjalan pada mode kompatibilitas penuh
              mixedContentMode:
                  MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,

              // Memastikan cache WebView berfungsi dengan optimal tanpa interupsi
              clearCache: false,
              cacheEnabled: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              _updateCanGoBack();
            },
            onLoadStop: (controller, url) {
              _updateCanGoBack();
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              _updateCanGoBack();
            },

            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var uri = navigationAction.request.url;

              // Mengamankan arus lalu lintas navigasi: Mencegat dan mengevaluasi akses URL ke luar domain UGM
              if (uri != null && !_isAllowedUrl(uri)) {
                // Menampilkan dialog keamanan apabila tujuan navigasi berada di luar whitelist
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
                    // Meneruskan peluncuran URL berisiko eksternal ke dalam mesin peramban bawaan sistem
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

              // Menangani penangkapan URL berakhiran PDF untuk diarahkan ke layar internal (PdfViewerScreen)
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

            // Tangkapan eksekusi dan penanganan galat (error handling) bilamana terjadi masalah pemuatan
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
