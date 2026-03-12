import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class SellerSignUpScreen extends StatefulWidget {
  const SellerSignUpScreen({super.key});
  @override
  State<SellerSignUpScreen> createState() => _SellerSignUpScreenState();
}

class _SellerSignUpScreenState extends State<SellerSignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _businessName = TextEditingController();
  final _businessDesc = TextEditingController();
  final _businessAddr = TextEditingController();
  final _nationalId = TextEditingController();

  File? _idFront;
  File? _idBack;
  File? _selfie;
  bool _loading = false;
  bool _obscure = true;
  int _step = 0; // 0=account, 1=business, 2=verification

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose();
    _businessName.dispose(); _businessDesc.dispose();
    _businessAddr.dispose(); _nationalId.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, int type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      switch (type) {
        case 0: _idFront = File(picked.path);
        case 1: _idBack = File(picked.path);
        case 2: _selfie = File(picked.path);
      }
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_idFront == null) {
      showSnack(context, 'National ID front photo is required', error: true);
      return;
    }
    setState(() => _loading = true);

    try {
      // 1. Create auth user
      final res = await SupabaseService.signUp(
        _email.text.trim(), _password.text, _name.text.trim());
      if (res.user == null) throw Exception('Signup failed');
      final userId = res.user!.id;

      // 2. Upload ID documents
      final frontPath = await SupabaseService.uploadSellerDocument(
          userId, _idFront!, 'id_front');
      String? backPath;
      String? selfiePath;
      if (_idBack != null) {
        backPath = await SupabaseService.uploadSellerDocument(
            userId, _idBack!, 'id_back');
      }
      if (_selfie != null) {
        selfiePath = await SupabaseService.uploadSellerDocument(
            userId, _selfie!, 'selfie');
      }

      // 3. Create seller profile
      await SupabaseService.createSellerProfile({
        'user_id': userId,
        'business_name': _businessName.text.trim(),
        'business_description': _businessDesc.text.trim().isNotEmpty
            ? _businessDesc.text.trim() : null,
        'business_address': _businessAddr.text.trim().isNotEmpty
            ? _businessAddr.text.trim() : null,
        'national_id_number': _nationalId.text.trim(),
        'national_id_front_url': frontPath,
        if (backPath != null) 'national_id_back_url': backPath,
        if (selfiePath != null) 'selfie_with_id_url': selfiePath,
        'verification_status': 'pending',
      });

      // 4. Sign out and redirect to login
      await SupabaseService.signOut();
      if (mounted) {
        showSnack(context,
            'Application submitted! We\'ll review and notify you within 2-3 business days.');
        context.go('/auth/login');
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _step == 0 ? context.pop() : setState(() => _step--),
        ),
        title: Text(['Account', 'Business Info', 'Verification'][_step]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Row(
            children: List.generate(3, (i) => Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= _step ? AppColors.accent : AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _step == 0
                  ? _StepAccount(
                      key: const ValueKey(0),
                      name: _name, email: _email,
                      password: _password, obscure: _obscure,
                      onToggleObscure: () => setState(() => _obscure = !_obscure),
                      onNext: () {
                        if (_name.text.isEmpty || _email.text.isEmpty || _password.text.length < 6) {
                          showSnack(context, 'Fill all fields correctly', error: true);
                          return;
                        }
                        setState(() => _step = 1);
                      },
                    )
                  : _step == 1
                      ? _StepBusiness(
                          key: const ValueKey(1),
                          businessName: _businessName,
                          desc: _businessDesc, addr: _businessAddr,
                          onNext: () {
                            if (_businessName.text.isEmpty) {
                              showSnack(context, 'Business name required', error: true);
                              return;
                            }
                            setState(() => _step = 2);
                          },
                        )
                      : _StepVerification(
                          key: const ValueKey(2),
                          nationalId: _nationalId,
                          idFront: _idFront, idBack: _idBack, selfie: _selfie,
                          onPickFront: () => _pickImage(ImageSource.camera, 0),
                          onPickBack: () => _pickImage(ImageSource.camera, 1),
                          onPickSelfie: () => _pickImage(ImageSource.camera, 2),
                          onSubmit: _submit, loading: _loading,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step 1: Account ───────────────────────────────────────────
class _StepAccount extends StatelessWidget {
  final TextEditingController name, email, password;
  final bool obscure;
  final VoidCallback onToggleObscure, onNext;

  const _StepAccount({
    super.key,
    required this.name, required this.email, required this.password,
    required this.obscure, required this.onToggleObscure, required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Create your account', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
        const SizedBox(height: 8),
        const Text('Basic information to get started', style: TextStyle(
          fontSize: 14, color: AppColors.textSecondary,
        )),
        const SizedBox(height: 32),
        VTextField(controller: name, label: 'Full name',
            prefixIcon: Icons.person_outline_rounded),
        const SizedBox(height: 16),
        VTextField(controller: email, label: 'Email address',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        VTextField(
          controller: password, label: 'Password',
          prefixIcon: Icons.lock_outline_rounded,
          obscure: obscure,
          suffix: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.textMuted, size: 20,
            ),
            onPressed: onToggleObscure,
          ),
        ),
        const SizedBox(height: 32),
        VButton(label: 'Continue', onPressed: onNext, icon: Icons.arrow_forward_rounded),
      ],
    );
  }
}

// ── Step 2: Business ──────────────────────────────────────────
class _StepBusiness extends StatelessWidget {
  final TextEditingController businessName, desc, addr;
  final VoidCallback onNext;

  const _StepBusiness({
    super.key,
    required this.businessName, required this.desc, required this.addr, required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business information', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
        const SizedBox(height: 8),
        const Text('Tell us about your business', style: TextStyle(
          fontSize: 14, color: AppColors.textSecondary,
        )),
        const SizedBox(height: 32),
        VTextField(controller: businessName, label: 'Business / Store name',
            prefixIcon: Icons.store_outlined),
        const SizedBox(height: 16),
        VTextField(
          controller: desc, label: 'Business description (optional)',
          prefixIcon: Icons.notes_rounded, maxLines: 3,
        ),
        const SizedBox(height: 16),
        VTextField(controller: addr, label: 'Business address (optional)',
            prefixIcon: Icons.location_on_outlined),
        const SizedBox(height: 32),
        VButton(label: 'Continue', onPressed: onNext, icon: Icons.arrow_forward_rounded),
      ],
    );
  }
}

// ── Step 3: Verification ──────────────────────────────────────
class _StepVerification extends StatelessWidget {
  final TextEditingController nationalId;
  final File? idFront, idBack, selfie;
  final VoidCallback onPickFront, onPickBack, onPickSelfie, onSubmit;
  final bool loading;

  const _StepVerification({
    super.key,
    required this.nationalId,
    required this.idFront, required this.idBack, required this.selfie,
    required this.onPickFront, required this.onPickBack, required this.onPickSelfie,
    required this.onSubmit, required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identity verification', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
        const SizedBox(height: 8),
        const Text(
          'We need to verify your identity to protect all users on the platform. Your documents are stored securely.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your application will be reviewed within 2-3 business days.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        VTextField(
          controller: nationalId,
          label: 'National ID number',
          prefixIcon: Icons.badge_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'ID number required' : null,
        ),
        const SizedBox(height: 24),

        _DocUploadTile(
          label: 'National ID - Front',
          subtitle: 'Required',
          icon: Icons.credit_card_rounded,
          file: idFront,
          onPick: onPickFront,
          required: true,
        ),
        const SizedBox(height: 12),
        _DocUploadTile(
          label: 'National ID - Back',
          subtitle: 'Optional but recommended',
          icon: Icons.credit_card_outlined,
          file: idBack,
          onPick: onPickBack,
        ),
        const SizedBox(height: 12),
        _DocUploadTile(
          label: 'Selfie holding ID',
          subtitle: 'Optional but speeds up review',
          icon: Icons.face_rounded,
          file: selfie,
          onPick: onPickSelfie,
        ),
        const SizedBox(height: 32),
        VButton(
          label: 'Submit Application',
          onPressed: onSubmit,
          isLoading: loading,
          icon: Icons.send_rounded,
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'By submitting, you agree to our Terms of Service\nand Seller Agreement.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _DocUploadTile extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final File? file;
  final VoidCallback onPick;
  final bool required;

  const _DocUploadTile({
    required this.label, required this.subtitle, required this.icon,
    required this.file, required this.onPick, this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.success.withOpacity(0.08)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? AppColors.success.withOpacity(0.4) : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: hasFile
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(file!, fit: BoxFit.cover),
                    )
                  : Icon(icon, color: AppColors.textMuted, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label, style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14,
                        color: AppColors.textPrimary,
                      )),
                      if (required) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Required', style: TextStyle(
                            fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600,
                          )),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    hasFile ? 'Photo selected' : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile ? AppColors.success : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
              color: hasFile ? AppColors.success : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
