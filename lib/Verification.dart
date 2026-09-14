import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/Accueil.dart'; // pour CertifioColors
import 'services/Verification_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  // Clé utilisée pour capturer le widget d'export (photo + résultat)
  // sous forme d'image, sans que ce widget soit visible à l'écran.
  final GlobalKey _cleExport = GlobalKey();

  XFile? _imageSelectionnee;
  bool _isExporting = false;
  String? _messageStatut;

  bool _verificationEnCours = false;
  ResultatVerification? _resultatVerification;

  // Fonction complexe : gestion asynchrone des permissions et
  // lancement de l'UI native de capture. Important de gérer
  // le refus de permission proprement pour éviter un état
  // incohérent dans l'interface.
  Future<void> _scannerAvecCamera() async {
    final statutCamera = await Permission.camera.request();
    if (!statutCamera.isGranted) {
      setState(() => _messageStatut = "Permission caméra refusée.");
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image != null) {
        setState(() {
          _imageSelectionnee = image;
          _messageStatut = null;
          _resultatVerification = null;
        });
      }
    } catch (e) {
      setState(() => _messageStatut = "Erreur caméra : $e");
    }
  }

  Future<void> _importerImage() async {
    // Ouvre la galerie pour sélectionner une image. La qualité
    // est limitée avec `imageQuality` pour réduire la taille
    // des fichiers envoyés au serveur et générés dans les exports.
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image != null) {
        setState(() {
          _imageSelectionnee = image;
          _messageStatut = null;
          _resultatVerification = null;
        });
      }
    } catch (e) {
      setState(() => _messageStatut = "Erreur import : $e");
    }
  }

  Future<void> _lancerVerification() async {
    // Lance l'appel au service de vérification en fournissant
    // le chemin du fichier image. L'opération est asynchrone
    // et peut durer plusieurs secondes — on verrouille l'UI
    // via `_verificationEnCours` pour informer l'utilisateur.
    if (_imageSelectionnee == null) return;

    setState(() {
      _verificationEnCours = true;
      _resultatVerification = null;
    });

    final resultat = await VerificationService.verifierDiplome(_imageSelectionnee!.path);

    if (!mounted) return;

    setState(() {
      _verificationEnCours = false;
      _resultatVerification = resultat;
    });
  }

  void _reprendre() {
    setState(() {
      _imageSelectionnee = null;
      _messageStatut = null;
      _resultatVerification = null;
    });
  }

  // ----------------------------------------------------------
  // Capture le widget hors-écran (_buildContenuExport) sous forme
  // d'image PNG en mémoire, pour l'export Image et pour intégrer
  // le résultat dans un PDF proprement mis en page.
  //
  // Important : on attend deux frames complets (via
  // addPostFrameCallback) pour être sûr que le RepaintBoundary a
  // réellement été peint au moins une fois avant de l'capturer.
  // Sans ça, "debugNeedsPaint is not true" peut se déclencher,
  // en particulier juste après le setState qui fait apparaître
  // ce widget dans l'arbre (résultat de vérification tout juste
  // reçu).
  // ----------------------------------------------------------
  Future<Uint8List> _capturerContenuExport() async {
    // Force un nouveau frame si besoin, puis attend qu'il soit
    // effectivement peint avant de tenter la capture.
    // Détail : `WidgetsBinding.instance.endOfFrame` attend la fin
    // de la passe de rendu en cours — sans cela `toImage()` peut
    // échouer car le RepaintBoundary n'a pas encore été peint.
    if (mounted) {
      setState(() {});
    }
    await WidgetsBinding.instance.endOfFrame;

    final renderObject = _cleExport.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw Exception("Widget d'export introuvable ou pas encore peint.");
    }

    if (renderObject.debugNeedsPaint) {
      // Si l'objet a encore besoin d'être peint, attend encore
      // une frame pour éviter l'exception liée au paint manquant.
      await WidgetsBinding.instance.endOfFrame;
    }

    // `pixelRatio` élève la résolution de l'image capturée.
    // Valeurs élevées améliorent la netteté mais consomment
    // plus de mémoire : 3.0 est un compromis courant.
    final image = await renderObject.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _exporterEnImage() async {
    // Prépare et partage une image PNG représentant le widget
    // d'export (photo + bandeau résultat). On écrit d'abord le
    // fichier dans le répertoire temporaire puis on utilise
    // `share_plus` pour afficher le dialogue natif de partage.
    if (_imageSelectionnee == null) return;

    setState(() => _isExporting = true);
    try {
      final bytesImage = await _capturerContenuExport();

      final Directory tempDir = await getTemporaryDirectory();
      final String nomFichier = 'certifio_${DateTime.now().millisecondsSinceEpoch}.png';
      final String cheminImage = '${tempDir.path}/$nomFichier';
      final File fichierImage = File(cheminImage);
      await fichierImage.writeAsBytes(bytesImage);

      await Share.shareXFiles(
        [XFile(fichierImage.path)],
        text: 'Diplôme et résultat - Certifio',
        subject: 'Export du résultat de vérification',
      );
      setState(() => _messageStatut = "Image exportée avec succès.");
    } catch (e) {
      setState(() => _messageStatut = "Erreur lors de l'export image : $e");
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exporterEnPdf() async {
    // Génère un PDF contenant l'image composite capturée.
    // On convertit le `Uint8List` en `pw.MemoryImage` puis on
    // insère l'image sur une page A4 en la centrant et en
    // la redimensionnant pour conserver la mise en page.
    if (_imageSelectionnee == null) return;

    setState(() => _isExporting = true);
    try {
      final bytesComposite = await _capturerContenuExport();
      final pdfImage = pw.MemoryImage(bytesComposite);

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      final Directory tempDir = await getTemporaryDirectory();
      final String nomFichier = 'diplome_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String cheminPdf = '${tempDir.path}/$nomFichier';
      final File fichierPdf = File(cheminPdf);
      await fichierPdf.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(fichierPdf.path)],
        text: 'Diplôme et résultat - Certifio',
        subject: 'Export PDF du résultat de vérification',
      );

      setState(() => _messageStatut = "PDF exporté avec succès.");
    } catch (e) {
      setState(() => _messageStatut = "Erreur lors de l'export PDF : $e");
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Vérification",
                style: TextStyle(
                  color: CertifioColors.texteClair,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Scannez ou importez une image du diplôme à vérifier.",
                style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.6)),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: _imageSelectionnee == null
                    ? _buildEcranDepart()
                    : _buildApercuEtExport(),
              ),
            ],
          ),
        ),

        // ----------------------------------------------------
        // Widget utilisé UNIQUEMENT pour la capture d'export
        // (photo + résultat). Il n'est jamais visible pour
        // l'utilisateur car placé très loin hors de l'écran via
        // Transform.translate — contrairement à Offstage, cette
        // approche laisse Flutter le PEINDRE normalement, ce qui
        // est indispensable pour que RepaintBoundary.toImage()
        // fonctionne (Offstage empêche le paint et provoque
        // l'erreur "debugNeedsPaint is not true").
        // ----------------------------------------------------
        if (_imageSelectionnee != null && _resultatVerification != null)
          Transform.translate(
            offset: const Offset(-100000, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: OverflowBox(
                minHeight: 0,
                maxHeight: double.infinity,
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: _cleExport,
                  child: _buildContenuExport(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Contenu capturé pour l'export : la photo du diplôme suivie
  // d'un bandeau reprenant le résultat de la vérification.
  // Largeur fixe pour un rendu cohérent en image comme en PDF.
  // ----------------------------------------------------------
  Widget _buildContenuExport() {
    final resultat = _resultatVerification!;

    Color couleur;
    String texteStatut;
    switch (resultat.statut) {
      case 'authentique':
        couleur = CertifioColors.vertMedaillon;
        texteStatut = "AUTHENTIQUE";
        break;
      case 'suspect':
        couleur = CertifioColors.rouge;
        texteStatut = "SUSPECT";
        break;
      default:
        couleur = CertifioColors.or;
        texteStatut = (resultat.statut ?? "AMBIGU").toUpperCase();
    }

    // Widget destiné à l'export : largeur fixée pour garantir
    // un rendu cohérent en image et PDF (facilite l'alignement
    // et la lisibilité sur différents appareils).
    return Material(
      color: CertifioColors.fondVertFonce,
      child: Container(
        width: 900,
        padding: const EdgeInsets.all(24),
        color: CertifioColors.fondVertFonce,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                "CERTIFIO",
                style: TextStyle(
                  color: CertifioColors.or,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),

            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(_imageSelectionnee!.path),
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: couleur.withOpacity(0.6), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        texteStatut,
                        style: TextStyle(
                          color: couleur,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const Spacer(),
                      if (resultat.scoreFinal != null)
                        Text(
                          "${resultat.scoreFinal!.toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: couleur,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                    ],
                  ),
                  // Le bandeau ci-dessous contient le texte détaillé
                  // du résultat. C'est la partie la plus importante
                  // pour l'interprétation du verdict par un humain
                  // (ou pour une preuve jointe au PDF/Image).
                  if (resultat.resultatTexte != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      resultat.resultatTexte!,
                      style: const TextStyle(
                        color: CertifioColors.texteClair,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                "Document généré par Certifio — vérification de diplômes",
                style: TextStyle(
                  color: CertifioColors.texteClair.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcranDepart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_rounded,
            color: CertifioColors.texteClair.withOpacity(0.3),
            size: 72,
          ),
          const SizedBox(height: 32),
          // Ecran d'accueil minimal : invite l'utilisateur à
          // scanner ou importer un diplôme avant toute action.

          if (_messageStatut != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _messageStatut!,
                style: const TextStyle(color: CertifioColors.rouge),
                textAlign: TextAlign.center,
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _scannerAvecCamera,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text(
                "Scanner avec l'appareil photo",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CertifioColors.or,
                foregroundColor: CertifioColors.fondVertFonce,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _importerImage,
              icon: const Icon(Icons.image_rounded),
              label: const Text(
                "Importer une image",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: CertifioColors.texteClair,
                side: BorderSide(color: CertifioColors.texteClair.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApercuEtExport() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(_imageSelectionnee!.path),
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Flux utilisateur en deux étapes : aperçu puis vérification.
        // Ceci évite les envois accidentels et permet d'afficher
        // un écran de confirmation avant l'analyse.
        // Étape 1 : aperçu de l'image → l'utilisateur doit valider avant l'envoi
        if (!_verificationEnCours && _resultatVerification == null) ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _reprendre,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text("Annuler"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CertifioColors.texteClair,
                      side: BorderSide(color: CertifioColors.texteClair.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _lancerVerification,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      "Valider",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CertifioColors.or,
                      foregroundColor: CertifioColors.fondVertFonce,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        if (_verificationEnCours)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                CircularProgressIndicator(color: CertifioColors.orClair),
                SizedBox(height: 8),
                Text(
                  "Analyse en cours...",
                  style: TextStyle(color: CertifioColors.texteClair),
                ),
              ],
            ),
          ),

        if (!_verificationEnCours && _resultatVerification != null)
          _buildCarteResultat(_resultatVerification!),

        if (_messageStatut != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              _messageStatut!,
              style: TextStyle(
                color: _messageStatut!.contains('Erreur')
                    ? CertifioColors.rouge
                    : CertifioColors.orClair,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 12),

        // Étape 2 : une fois le résultat obtenu → export + reprendre
        if (_resultatVerification != null) ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exporterEnImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text("Image"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CertifioColors.vertMedaillon,
                      foregroundColor: CertifioColors.texteClair,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exporterEnPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text("PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CertifioColors.or,
                      foregroundColor: CertifioColors.fondVertFonce,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          TextButton.icon(
            onPressed: _isExporting ? null : _reprendre,
            icon: Icon(Icons.refresh_rounded, color: CertifioColors.texteClair.withOpacity(0.7)),
            label: Text(
              "Reprendre",
              style: TextStyle(color: CertifioColors.texteClair.withOpacity(0.7)),
            ),
          ),
        ],

        if (_isExporting)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: CircularProgressIndicator(color: CertifioColors.orClair),
          ),
      ],
    );
  }

  Widget _buildCarteResultat(ResultatVerification resultat) {
    if (!resultat.succes) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: CertifioColors.rouge.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CertifioColors.rouge.withOpacity(0.4)),
        ),
        child: Text(
          resultat.message,
          style: const TextStyle(color: CertifioColors.texteClair),
          textAlign: TextAlign.center,
        ),
      );
    }

    Color couleur;
    IconData icone;
    switch (resultat.statut) {
      case 'authentique':
        couleur = CertifioColors.vertMedaillon;
        icone = Icons.verified_rounded;
        break;
      case 'suspect':
        couleur = CertifioColors.rouge;
        icone = Icons.warning_amber_rounded;
        break;
      default:
        couleur = CertifioColors.or;
        icone = Icons.help_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: couleur),
              const SizedBox(width: 8),
              Text(
                (resultat.statut ?? "").toUpperCase(),
                style: TextStyle(
                  color: couleur,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (resultat.scoreFinal != null)
                Text(
                  "${resultat.scoreFinal!.toStringAsFixed(0)}%",
                  style: TextStyle(color: couleur, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (resultat.resultatTexte != null) ...[
            const SizedBox(height: 8),
            Text(
              resultat.resultatTexte!,
              style: const TextStyle(color: CertifioColors.texteClair, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}