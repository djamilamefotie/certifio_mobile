import 'package:flutter/material.dart';

class CertifioColors {
  static const fondVertFonce = Color(0xFF0A2E24);
  static const or = Color(0xFFD9A93E);
  static const orClair = Color(0xFFF0C868);
  static const texteClair = Color(0xFFFFF8E7);
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String sectionActive = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(sectionActive, style: const TextStyle(color: Colors.black87)),
      ),
      drawer: Drawer(
        backgroundColor: CertifioColors.fondVertFonce,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Text("Certifio", style: TextStyle(color: CertifioColors.texteClair, fontSize: 22)),
              ),
              _item(context, 'Dashboard', Icons.home_outlined),
              _item(context, 'Base de référence', Icons.school_outlined),
              _item(context, 'Clients', Icons.person_outline),
              _item(context, 'Institutions', Icons.business_outlined),
              _item(context, 'Offres abonnements', Icons.attach_money),
              _item(context, 'Vérifications ambiguës', Icons.warning_amber_rounded),
            ],
          ),
        ),
      ),
      body: Center(
        child: Text("Contenu : $sectionActive", style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _item(BuildContext context, String titre, IconData icone) {
    return ListTile(
      leading: Icon(icone, color: CertifioColors.orClair),
      title: Text(titre, style: const TextStyle(color: CertifioColors.texteClair)),
      onTap: () {
        setState(() => sectionActive = titre);
        Navigator.pop(context);
      },
    );
  }
}