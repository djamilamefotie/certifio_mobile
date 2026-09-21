import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ⚠ Adresse de ton serveur Laravel, SANS "/api" à la fin.
// C'est la même que dans auth_service.dart, mais sans /api
// (ex : http://192.168.11.56:8000). Ne pas mettre 127.0.0.1 : sur le téléphone,
// cette adresse désigne le téléphone lui-même.
const String kWebBase = 'http://192.168.11.56:8000';

const _kGreenDark = Color(0xFF0B2D24);
const _kGreen = Color(0xFF0E9F6E);
const _kGold = Color(0xFFC49A3A);

class _Section {
  final String label;
  final IconData icon;
  final String path; // page Filament correspondante
  const _Section(this.label, this.icon, this.path);
}

const _sections = [
  _Section('Dashboard', Icons.dashboard_outlined, '/admin'),
  _Section('Base de référence', Icons.library_books_outlined,
      '/admin/base-references'),
  _Section('Clients', Icons.people_outline, '/admin/clients'),
  _Section('Institutions', Icons.account_balance_outlined,
      '/admin/institutions'),
  _Section('Offres abonnements', Icons.workspace_premium_outlined,
      '/admin/offre-abonnements'),
  _Section('Vérifications ambiguës', Icons.rule_folder_outlined,
      '/admin/verifications'),
];

/// Espace admin : menu latéral Certifio + dashboard Filament dans l'app.
class AdminShell extends StatefulWidget {
  final String adminName;
  final String adminEmail;
  final String token; // token Sanctum de l'app, sert à ouvrir la session Filament
  final VoidCallback onLogout;

  const AdminShell({
    super.key,
    required this.adminName,
    required this.adminEmail,
    required this.token,
    required this.onLogout,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WebViewController _controller;

  int _index = 0;
  bool _loading = true;
  bool _error = false;
  int _tentativesAuto = 0; // évite une boucle si la connexion auto échoue

  Uri _uri(int i) => Uri.parse('$kWebBase${_sections[i].path}');

  /// Ouvre la session Filament à partir du token Sanctum de l'app.
  /// Laravel (route mobile-admin-login) crée la session puis redirige vers /admin.
  Future<void> _connexionAuto() {
    _tentativesAuto++;
    return _controller.loadRequest(
      Uri.parse('$kWebBase/mobile-admin-login'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
  }

  String get _initials {
    final n = widget.adminName.trim();
    if (n.isEmpty) return 'AD';
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (url) {
          if (!mounted) return;
          final chemin = Uri.tryParse(url)?.path ?? '';
          final surLogin = chemin == '/admin/login' || chemin == '/login';
          if (surLogin && _tentativesAuto < 2) {
            // Session Filament absente ou expirée : on la rouvre automatiquement
            _connexionAuto();
            return;
          }
          if (!surLogin) _tentativesAuto = 0;
          setState(() => _loading = false);
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted) {
            setState(() {
              _error = true;
              _loading = false;
            });
          }
        },
      ));

    // Premier affichage : connexion automatique puis arrivée sur le Dashboard
    _connexionAuto();
  }

  void _open(int i) {
    setState(() {
      _index = i;
      _error = false;
    });
    _controller.loadRequest(_uri(i));
    Navigator.pop(context); // ferme le menu
  }

  Future<void> _logout() async {
    // Ferme aussi la session Filament dans la WebView
    await WebViewCookieManager().clearCookies();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          _scaffoldKey.currentState?.closeDrawer();
        } else if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          title: Text(
            _sections[_index].label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: 'Actualiser',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _error = false);
                _controller.reload();
              },
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            Positioned.fill(child: WebViewWidget(controller: _controller)),
            if (_loading && !_error)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: _kGold,
                  backgroundColor: Colors.transparent,
                ),
              ),
            if (_error)
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.black38),
                      const SizedBox(height: 16),
                      const Text(
                        'Impossible de joindre le serveur.\n'
                        'Vérifie que le serveur Laravel est lancé et que '
                        'le téléphone est sur le même Wi-Fi que le PC.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style:
                            FilledButton.styleFrom(backgroundColor: _kGold),
                        onPressed: () {
                          setState(() => _error = false);
                          _controller.loadRequest(_uri(_index));
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: _kGreenDark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _kGreen,
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Certifio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.adminEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _sections.length,
                itemBuilder: (_, i) {
                  final s = _sections[i];
                  final selected = i == _index;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: ListTile(
                      selected: selected,
                      // blanc à 8 % d'opacité (évite withOpacity, déprécié)
                      selectedTileColor: const Color(0x14FFFFFF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: Icon(s.icon,
                          color: selected ? _kGold : Colors.white70),
                      title: Text(
                        s.label,
                        style: TextStyle(
                          color: selected ? _kGold : Colors.white,
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      onTap: () => _open(i),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: const Text('Déconnexion',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}