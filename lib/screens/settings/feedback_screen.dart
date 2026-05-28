import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // ── Your SickleCare email ──────────────────────────────────────────────────
  static const _kRecipientEmail = 'sicklecare.cameroon@gmail.com';

  // ── Theme ──────────────────────────────────────────────────────────────────
  static const _kBlue       = Color(0xFF1E40AF);
  static const _kBlueMid    = Color(0xFF2563EB);
  static const _kRed        = Color(0xFFE53935);
  static const _kRedGlow    = Color(0x4DE53935);
  static const _kBg         = Color(0xFFF0F4FF);
  static const _kWhite      = Color(0xFFFFFFFF);
  static const _kTextDark   = Color(0xFF1A237E);
  static const _kGrey       = Color(0xFF90A4AE);
  static const _kShadowSm   = Color(0x10000000);
  static const _kShadowMd   = Color(0x14000000);

  final _formKey           = GlobalKey<FormState>();
  final _subjectCtrl       = TextEditingController();
  final _feedbackCtrl      = TextEditingController();

  int  _rating    = 0;
  bool _launching = false;

  // Feedback category chips
  final _categories = [
    '🐛 Bug Report',
    '💡 Feature Request',
    '💙 General Feedback',
    '🩺 Medical Content',
    '⚡ Performance',
  ];
  String _selectedCategory = '💙 General Feedback';

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ── Launch mail app ────────────────────────────────────────────────────────

  Future<void> _sendViaEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      _snack('Please select a star rating ⭐', isError: true);
      return;
    }

    setState(() => _launching = true);

    final user    = FirebaseAuth.instance.currentUser;
    final stars   = '⭐' * _rating;
    final subject = Uri.encodeComponent(
        '[SickleCare Feedback] ${_subjectCtrl.text.trim()}');

    final body = Uri.encodeComponent(
      '--- SickleCare App Feedback ---\n\n'
      'Category : $_selectedCategory\n'
      'Rating   : $stars ($_rating/5)\n'
      'User     : ${user?.email ?? "Not logged in"}\n'
      'User ID  : ${user?.uid ?? "N/A"}\n\n'
      '--- Message ---\n'
      '${_feedbackCtrl.text.trim()}\n\n'
      '--- Sent from SickleCare Cameroon App ---',
    );

    final uri = Uri.parse(
        'mailto:$_kRecipientEmail?subject=$subject&body=$body');

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri);
        _subjectCtrl.clear();
        _feedbackCtrl.clear();
        setState(() { _rating = 0; _selectedCategory = '💙 General Feedback'; });
        _snack('Mail app opened — just tap Send! 💙');
      } else {
        _showNoMailDialog();
      }
    } catch (e) {
      _showNoMailDialog();
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  void _showNoMailDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.mail_outline_rounded, color: Color(0xFF1E40AF)),
            const SizedBox(width: 10),
            Text('No Mail App Found',
                style: GoogleFonts.sora(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No mail app is set up on this device. '
              'You can email us directly at:',
              style: GoogleFonts.dmSans(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _kRecipientEmail,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E40AF)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _snack('Email address copied! 📋');
                    },
                    child: const Icon(Icons.copy_rounded,
                        color: Color(0xFF1E40AF), size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please install Gmail or another mail app, then try again.',
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF90A4AE),
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.sora(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E40AF))),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _kRed : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Feedback & Support',
            style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kWhite)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildCategorySection(),
              const SizedBox(height: 22),
              _buildLabel('Subject'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _subjectCtrl,
                hint: 'e.g. App crashes on tracker screen',
                icon: Icons.subject_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null,
              ),
              const SizedBox(height: 22),
              _buildLabel('Your Feedback'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _feedbackCtrl,
                hint: 'Describe your experience, issue or suggestion...',
                icon: Icons.feedback_outlined,
                maxLines: 6,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your feedback';
                  if (v.trim().length < 10) return 'Feedback is too short';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              _buildLabel('Rate Your Experience'),
              const SizedBox(height: 12),
              _buildStarRating(),
              const SizedBox(height: 32),
              _buildSendButton(),
              const SizedBox(height: 24),
              _buildMailInfoCard(),
              const SizedBox(height: 20),
              _buildPrivacyCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() => Center(
        child: Column(
          children: [
            Container(
              width: 100, height: 100,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                      color: _kShadowMd, blurRadius: 16, offset: Offset(0, 5))
                ],
              ),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 18),
            Text('We Value Your Feedback',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            Text(
              'Help us improve SickleCare by sharing your experience, '
              'reporting issues, or suggesting new features.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: _kGrey, height: 1.6),
            ),
          ],
        ),
      );

  // ── Category Chips ─────────────────────────────────────────────────────────

  Widget _buildCategorySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Category'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final selected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _kBlue : _kWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _kBlue : const Color(0xFFDDE4FF),
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: _kShadowSm,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? _kWhite : _kTextDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  // ── Star Rating ────────────────────────────────────────────────────────────

  Widget _buildStarRating() => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: _kShadowSm, blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: AnimatedScale(
                    scale: _rating >= star ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 10),
              Text(
                _ratingLabel(_rating),
                style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark),
              ),
            ],
          ],
        ),
      );

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return '😞 Very Poor';
      case 2: return '😕 Poor';
      case 3: return '😐 Average';
      case 4: return '😊 Good';
      case 5: return '🤩 Excellent!';
      default: return '';
    }
  }

  // ── Send Button ────────────────────────────────────────────────────────────

  Widget _buildSendButton() => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kRed,
            foregroundColor: _kWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            shadowColor: _kRedGlow,
          ).copyWith(elevation: WidgetStateProperty.all(4)),
          onPressed: _launching ? null : _sendViaEmail,
          icon: _launching
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: _kWhite, strokeWidth: 2.5))
              : const Icon(Icons.mail_rounded, size: 20),
          label: Text(
            _launching ? 'Opening Mail...' : 'Send via Email',
            style: GoogleFonts.sora(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );

  // ── Mail Info Card ─────────────────────────────────────────────────────────

  Widget _buildMailInfoCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x331E40AF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.mail_outline_rounded,
                color: _kBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sends directly to our inbox',
                      style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark)),
                  const SizedBox(height: 3),
                  Text(
                    'Tapping "Send via Email" will open your mail app '
                    'pre-filled with your feedback. Just hit send!',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: _kGrey, height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _kRecipientEmail,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: _kBlue,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Privacy Card ───────────────────────────────────────────────────────────

  Widget _buildPrivacyCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: _kShadowSm, blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kBlue, _kBlueMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x301E40AF),
                      blurRadius: 8,
                      offset: Offset(0, 3))
                ],
              ),
              child: const Icon(Icons.security_rounded,
                  color: _kWhite, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Your feedback is sent directly to the SickleCare team '
                'and used only to improve the app experience.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: _kGrey, height: 1.5),
              ),
            ),
          ],
        ),
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.sora(
          fontSize: 14, fontWeight: FontWeight.w700, color: _kTextDark));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.dmSans(fontSize: 14, color: _kTextDark),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _kGrey),
          prefixIcon: Icon(icon, color: _kBlue, size: 20),
          filled: true,
          fillColor: _kWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kRed, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kRed, width: 1.5),
          ),
        ),
      );
}
