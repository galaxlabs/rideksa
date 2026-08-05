import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserRole? _purpose;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_purpose == null) {
      final extra = GoRouterState.of(context).extra;
      _purpose = extra is UserRole ? extra : null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.white,
            selectionColor: AppColors.accentLight,
            selectionHandleColor: Colors.white,
          ),
          textTheme: Theme.of(context).textTheme,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                AppColors.darkBackground,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withAlpha(46),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryLight.withAlpha(36),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Ride',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'KSA',
                                style: TextStyle(
                                  color: AppColors.accentLight,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Travel, captain, or grow your transport company',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 26),

                          _PurposeBanner(
                            purpose: _purpose,
                            onChange: () => context.go('/auth/role-select'),
                          ),
                          const SizedBox(height: 16),

                          if (auth.errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(28),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.error.withAlpha(90),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => auth.clearError(),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(16),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withAlpha(22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.white60,
                                    indicator: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.accent,
                                          AppColors.accentLight,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    dividerColor: Colors.transparent,
                                    labelStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    tabs: const [
                                      Tab(text: 'Sign In', height: 44),
                                      Tab(text: 'Sign Up', height: 44),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: auth.state == AuthState.loading
                                      ? 340
                                      : (_tabController.index == 1 ? 600 : 320),
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _LoginTab(auth: auth, purpose: _purpose),
                                      _SignUpTab(auth: auth, purpose: _purpose),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (auth.state == AuthState.loading)
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),
                          _GoogleButton(auth: auth, purpose: _purpose),
                          const SizedBox(height: 14),
                          Text(
                            'By continuing you agree to our Terms & Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withAlpha(110),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(70),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: const Icon(Icons.directions_car, color: Colors.white, size: 38),
      ),
    );
  }
}

class _PurposeBanner extends StatelessWidget {
  final UserRole? purpose;
  final VoidCallback onChange;
  const _PurposeBanner({required this.purpose, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final label = _roleLabel(purpose);
    return Material(
      color: Colors.white.withAlpha(15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onChange,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.accentLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Change',
                style: TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginTab extends StatefulWidget {
  final AuthProvider auth;
  final UserRole? purpose;
  const _LoginTab({required this.auth, this.purpose});
  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _resetting = false;

  bool get _isPhone =>
      !_emailController.text.trim().contains('@') &&
      _emailController.text.trim().replaceAll(RegExp(r'\D'), '').length >= 9;

  void _login() {
    final identifier = _emailController.text.trim();
    final pass = _passwordController.text;
    if (identifier.isEmpty || pass.isEmpty) return;
    widget.auth.loginWithEmail(identifier, pass);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _resetting) return;
    setState(() => _resetting = true);
    try {
      await widget.auth.requestPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If the account exists, a Frappe password reset email was sent.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset request failed. Try again later.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => setState(() {}),
            decoration: _input(
              _isPhone ? 'Mobile Number' : 'Email or Mobile Number',
              _isPhone ? Icons.phone_outlined : Icons.email_outlined,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: _input(
              'Password',
              Icons.lock_outlined,
              suffix: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withAlpha(150),
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetting ? null : _resetPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFFD9BC7A)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.auth.state == AuthState.loading
                    ? null
                    : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpTab extends StatefulWidget {
  final AuthProvider auth;
  final UserRole? purpose;
  const _SignUpTab({required this.auth, this.purpose});
  @override
  State<_SignUpTab> createState() => _SignUpTabState();
}

class _SignUpTabState extends State<_SignUpTab> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _vatController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _crController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _licenseController = TextEditingController();
  final _idController = TextEditingController();
  final _companyController = TextEditingController();
  final _companyTaxController = TextEditingController();
  final _companyArController = TextEditingController();
  bool _showPassword = false;
  String? _error;
  late String _purpose;
  String _partnerType = 'Taxi Service';
  String _serviceContractType = 'School / Staff Transport';

  @override
  void initState() {
    super.initState();
    _purpose = _purposeFromRole(widget.purpose);
  }

  void _signUp() {
    setState(() => _error = null);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    final companyName = _companyController.text.trim();
    if ((_purpose == 'partner_company' || _purpose == 'customer_company') &&
        companyName.isEmpty) {
      setState(() => _error = 'Enter your company or business name');
      return;
    }
    if ((_purpose == 'partner_company' || _purpose == 'customer_company') &&
        _vatController.text.trim().isEmpty) {
      setState(
        () => _error =
            'VAT number is required and is used as the company identity',
      );
      return;
    }

    widget.auth.signUp(
      email,
      pass,
      displayName: name,
      purpose: _purpose,
      partnerType: _purpose == 'partner_company' ? _partnerType : null,
      serviceContractType: _partnerType == 'Service Contract'
          ? _serviceContractType
          : null,
      companyName:
          (_purpose == 'partner_company' || _purpose == 'customer_company' || _purpose == 'captain')
          ? companyName
          : null,
      legalName: _legalNameController.text.trim(),
      vatNo: _vatController.text.trim(),
      taxId: _taxIdController.text.trim(),
      crNo: _crController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      licenseNo: _licenseController.text.trim(),
      idNumber: _idController.text.trim(),
      companyTaxId: _companyTaxController.text.trim(),
      companyNameAr: _companyArController.text.trim(),
      serviceTypes: 'All transport services',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _legalNameController.dispose();
    _vatController.dispose();
    _taxIdController.dispose();
    _crController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _licenseController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyRole =
        _purpose == 'customer_company' || _purpose == 'partner_company';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          DropdownButtonFormField<String>(
            value: _purpose,
            dropdownColor: AppColors.primaryDark,
            style: const TextStyle(color: Colors.white),
            decoration: _input('Onboarding purpose', Icons.explore_outlined),
            items: const [
              DropdownMenuItem(value: 'passenger', child: Text('Passenger')),
              DropdownMenuItem(
                value: 'captain',
                child: Text('Captain / Driver'),
              ),
              DropdownMenuItem(
                value: 'customer_company',
                child: Text('Customer Company'),
              ),
              DropdownMenuItem(
                value: 'partner_company',
                child: Text('Partner / Transport Company'),
              ),
            ],
            onChanged: (value) =>
                setState(() => _purpose = value ?? 'passenger'),
          ),
          if (_purpose == 'partner_company') ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _partnerType,
              dropdownColor: AppColors.primaryDark,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'Primary business type',
                Icons.business_center_outlined,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Taxi Service',
                  child: Text('Transport Company / All Services'),
                ),
                DropdownMenuItem(
                  value: 'Travel Agent',
                  child: Text('Travel Agent'),
                ),
                DropdownMenuItem(
                  value: 'Fleet Owner',
                  child: Text('Fleet Owner'),
                ),
                DropdownMenuItem(
                  value: 'Rent A Car Service',
                  child: Text('Vehicle Rental'),
                ),
                DropdownMenuItem(
                  value: 'Service Contract',
                  child: Text('School / Staff Transport'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _partnerType = value ?? 'Taxi Service'),
            ),
          ],
          if (companyRole) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _companyController,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'Registered company name',
                Icons.apartment_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _legalNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _input('Legal name', Icons.gavel_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vatController,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'VAT number (unique company ID)',
                Icons.verified_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _taxIdController,
              style: const TextStyle(color: Colors.white),
              decoration: _input('Tax ID (optional)', Icons.badge_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _crController,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'Commercial registration (optional)',
                Icons.description_outlined,
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _input(
              'Full name / contact person',
              Icons.person_outline,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.white),
            decoration: _input('Mobile phone', Icons.phone_outlined),
            keyboardType: TextInputType.phone,
          ),
          if (_purpose == 'captain') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _idController,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'National ID / Iqama number',
                Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _licenseController,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'Driving license number',
                Icons.drive_eta_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _companyController,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'Company name (creates new if not found)',
                Icons.apartment_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _companyTaxController,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'Company Tax ID / VAT',
                Icons.verified_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _companyArController,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'Company name (Arabic)',
                Icons.translate,
              ),
            ),
          ],
          if (companyRole || _purpose == 'captain') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _cityController,
              style: const TextStyle(color: Colors.white),
              decoration: _input('City', Icons.location_city_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              decoration: _input(
                'Address / location',
                Icons.location_on_outlined,
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: _input('Email', Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: _input(
              'Password',
              Icons.lock_outlined,
              suffix: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withAlpha(150),
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: _input('Confirm Password', Icons.lock_outline),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(70),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.auth.state == AuthState.loading
                    ? null
                    : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final AuthProvider auth;
  final UserRole? purpose;
  const _GoogleButton({required this.auth, this.purpose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => auth.loginWithGoogle(),
        icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
        label: Text(
          purpose == null
              ? 'Continue with Google'
              : 'Continue with Google as ${_roleLabel(purpose)}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withAlpha(70)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white.withAlpha(8),
        ),
      ),
    );
  }
}

String _roleLabel(UserRole? role) {
  switch (role) {
    case UserRole.driver:
      return 'Driver / Captain';
    case UserRole.customerCompany:
      return 'Customer Company';
    case UserRole.partnerCompany:
      return 'Partner / Transport Company';
    case UserRole.travelAgent:
      return 'Travel Agent';
    case UserRole.admin:
      return 'Company Admin';
    case UserRole.superAdmin:
      return 'Super Admin';
    case UserRole.passenger:
      return 'Passenger';
    case null:
      return 'Choose your purpose of use';
  }
}

String _purposeFromRole(UserRole? role) {
  switch (role) {
    case UserRole.driver:
      return 'captain';
    case UserRole.customerCompany:
      return 'customer_company';
    case UserRole.partnerCompany:
      return 'partner_company';
    case UserRole.travelAgent:
      return 'partner_company';
    default:
      return 'passenger';
  }
}

InputDecoration _input(String label, IconData icon, {Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13),
    prefixIcon: Icon(icon, color: Colors.white.withAlpha(150), size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white.withAlpha(10),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
  );
}
