import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/session_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_settings_providers.dart';
import '../data/admin_settings_repository.dart';
import 'admin_shell.dart';

typedef AdminSettingsFilePicker = Future<PlatformFile?> Function();

final adminSettingsFilePickerProvider = Provider<AdminSettingsFilePicker>(
  (_) => () async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    return result?.files.single;
  },
);

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _subtitle = TextEditingController();
  final _year = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  ApplicationSettings? _applicationBaseline;
  SessionUser? _profileBaseline;
  bool _newLoginAlert = false;
  bool _weeklyReportEmail = false;
  bool _bannerEnabled = false;
  SecuritySettings? _securityBaseline;
  BannerSettings? _bannerBaseline;
  String _timezone = 'Asia/Jakarta';
  PlatformFile? _bannerFile;
  bool _hydrated = false;
  bool _saving = false;
  AppError? _error;
  String? _success;

  bool get _passwordDirty =>
      _currentPassword.text.isNotEmpty ||
      _password.text.isNotEmpty ||
      _passwordConfirmation.text.isNotEmpty;

  bool get _dirty {
    final app = _applicationBaseline;
    final profile = _profileBaseline;
    final security = _securityBaseline;
    final banner = _bannerBaseline;
    if (!_hydrated ||
        app == null ||
        profile == null ||
        security == null ||
        banner == null) {
      return false;
    }
    return _name.text.trim() != app.name ||
        _subtitle.text.trim() != app.subtitle ||
        _year.text.trim() != app.activeAcademicYear ||
        _timezone != app.timezone ||
        _fullName.text.trim() != profile.fullName ||
        _phone.text.trim() != (profile.phone ?? '') ||
        _newLoginAlert != security.newLoginAlert ||
        _weeklyReportEmail != security.weeklyReportEmail ||
        _bannerEnabled != banner.enabled ||
        _bannerFile != null ||
        _passwordDirty;
  }

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _name,
      _subtitle,
      _year,
      _fullName,
      _phone,
      _currentPassword,
      _password,
      _passwordConfirmation,
    ]) {
      controller.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _subtitle,
      _year,
      _fullName,
      _phone,
      _currentPassword,
      _password,
      _passwordConfirmation,
    ]) {
      controller.removeListener(_changed);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adminSettingsProvider);
    final user = ref.watch(authControllerProvider).user;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() == true && context.mounted) context.pop();
      },
      child: AdminShell(
        title: 'Pengaturan',
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: settings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                Text(_friendlyError(error)),
                const SizedBox(height: EmiSpacing.md),
                OutlinedButton(
                  onPressed: () => ref.invalidate(adminSettingsProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
            data: (data) {
              if (!_hydrated && user != null) _hydrate(data, user);
              return _content(data, user);
            },
          ),
        ),
      ),
    );
  }

  Widget _content(AdminSettings data, SessionUser? user) => Form(
    key: _formKey,
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(EmiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_success != null) _message(_success!, Colors.green),
          if (_error != null) _message(_friendlyError(_error!), Colors.red),
          _section('Pengaturan Aplikasi', [
            _field(_name, 'Nama Aplikasi', required: true),
            _field(_subtitle, 'Subtitle / Slogan'),
            _field(_year, 'Tahun Ajaran Aktif', required: true),
            DropdownButtonFormField<String>(
              initialValue: _timezone,
              decoration: const InputDecoration(labelText: 'Zona Waktu'),
              items:
                  {_timezone, 'Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura'}
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _timezone = value ?? _timezone),
            ),
          ]),
          _section('Profil Admin', [
            _field(_fullName, 'Nama Lengkap', required: true),
            _field(_phone, 'Telepon Admin', keyboardType: TextInputType.phone),
            TextFormField(
              initialValue: user?.email ?? '',
              enabled: false,
              decoration: const InputDecoration(labelText: 'Email Kantor'),
            ),
            TextFormField(
              initialValue: user?.status ?? '',
              enabled: false,
              decoration: const InputDecoration(labelText: 'Status Akun'),
            ),
          ]),
          _section('Pengaturan Banner Login', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _bannerEnabled,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _bannerEnabled = value),
              title: const Text('Aktifkan Banner'),
            ),
            if (_bannerFile != null)
              Image.file(
                File(_bannerFile!.path!),
                height: 140,
                fit: BoxFit.cover,
              )
            else if (data.banner.imageUrl?.isNotEmpty == true)
              Image.network(
                data.banner.imageUrl!,
                height: 140,
                fit: BoxFit.cover,
              )
            else
              const Text('Banner belum diunggah.'),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickBanner,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Pilih Gambar Banner'),
            ),
          ]),
          _section('Keamanan', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _newLoginAlert,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _newLoginAlert = value),
              title: const Text('Peringatan Login Baru'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _weeklyReportEmail,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _weeklyReportEmail = value),
              title: const Text('Email Laporan Mingguan'),
            ),
          ]),
          _section('Ubah Password', [
            const Text('Kosongkan jika tidak ingin mengubah password.'),
            _secret(_currentPassword, 'Password Lama'),
            _secret(_password, 'Password Baru'),
            _secret(_passwordConfirmation, 'Konfirmasi Password Baru'),
          ]),
          _section('Aktivitas', [
            if (data.activityLogs.isEmpty)
              const Text('Aktivitas belum tersedia.'),
            for (final log in data.activityLogs) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(log.title),
                subtitle: Text(
                  '${log.admin} • ${log.createdAt ?? '-'} • ${log.status ? 'aktif' : 'nonaktif'}',
                ),
              ),
              const Divider(height: 1),
            ],
          ]),
          SafeArea(
            top: false,
            child: FilledButton(
              key: const Key('saveAdminSettings'),
              onPressed: !_dirty || _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan Pengaturan'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EmiSpacing.md),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: EmiSpacing.md),
        ],
        const SizedBox(height: EmiSpacing.md),
        const Divider(height: 1),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label),
    validator: required ? _required : null,
  );

  Widget _secret(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(labelText: label),
      );

  Widget _message(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: Text(text, style: TextStyle(color: color)),
  );

  void _hydrate(AdminSettings settings, SessionUser user) {
    _applicationBaseline = settings.application;
    _securityBaseline = settings.security;
    _bannerBaseline = settings.banner;
    _profileBaseline = user;
    _name.text = settings.application.name;
    _subtitle.text = settings.application.subtitle;
    _year.text = settings.application.activeAcademicYear;
    _timezone = settings.application.timezone;
    _fullName.text = user.fullName;
    _phone.text = user.phone ?? '';
    _newLoginAlert = settings.security.newLoginAlert;
    _weeklyReportEmail = settings.security.weeklyReportEmail;
    _bannerEnabled = settings.banner.enabled;
    _hydrated = true;
  }

  Future<void> _refresh() async {
    if (_dirty && await _confirmLeave() != true) return;
    setState(() => _hydrated = false);
    ref.invalidate(adminSettingsProvider);
    await ref.read(adminSettingsProvider.future);
  }

  Future<void> _pickBanner() async {
    final file = await ref.read(adminSettingsFilePickerProvider)();
    if (file?.path == null || !mounted) return;
    setState(() => _bannerFile = file);
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;

  String? _passwordValidation() {
    if (!_passwordDirty) return null;
    if (_currentPassword.text.isEmpty ||
        _password.text.isEmpty ||
        _passwordConfirmation.text.isEmpty) {
      return 'Lengkapi semua kolom password.';
    }
    if (_password.text.length < 8) return 'Password baru minimal 8 karakter.';
    if (_password.text != _passwordConfirmation.text) {
      return 'Konfirmasi password tidak cocok.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || !_dirty || !_formKey.currentState!.validate()) return;
    final passwordError = _passwordValidation();
    if (passwordError != null) {
      setState(
        () => _error = AppError(
          type: AppErrorType.validation,
          message: passwordError,
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      final settingsRepository = ref.read(adminSettingsRepositoryProvider);
      final authRepository = ref.read(authRepositoryProvider);
      var profile = _profileBaseline!;
      if (_fullName.text.trim() != profile.fullName ||
          _phone.text.trim() != (profile.phone ?? '')) {
        profile = await authRepository.updateProfile(
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        );
      }
      var application = _applicationBaseline!;
      if (_name.text.trim() != application.name ||
          _subtitle.text.trim() != application.subtitle ||
          _year.text.trim() != application.activeAcademicYear ||
          _timezone != application.timezone) {
        application = await settingsRepository.updateApplication(
          ApplicationSettings(
            name: _name.text.trim(),
            subtitle: _subtitle.text.trim(),
            activeAcademicYear: _year.text.trim(),
            timezone: _timezone,
          ),
        );
      }
      var banner = _bannerBaseline!;
      if (_bannerEnabled != banner.enabled || _bannerFile != null) {
        banner = await settingsRepository.updateBanner(
          enabled: _bannerEnabled,
          path: _bannerFile?.path,
          fileName: _bannerFile?.name,
        );
      }
      var security = _securityBaseline!;
      if (_newLoginAlert != security.newLoginAlert ||
          _weeklyReportEmail != security.weeklyReportEmail) {
        security = await settingsRepository.updateSecurity(
          SecuritySettings(
            newLoginAlert: _newLoginAlert,
            weeklyReportEmail: _weeklyReportEmail,
          ),
        );
      }
      if (_passwordDirty) {
        profile = await authRepository.updatePassword(
          currentPassword: _currentPassword.text,
          password: _password.text,
          passwordConfirmation: _passwordConfirmation.text,
        );
      }
      if (!mounted) return;
      _currentPassword.clear();
      _password.clear();
      _passwordConfirmation.clear();
      setState(() {
        _applicationBaseline = application;
        _profileBaseline = profile;
        _bannerBaseline = banner;
        _securityBaseline = security;
        _bannerFile = null;
        _success = 'Pengaturan berhasil disimpan.';
      });
      ref.invalidate(adminSettingsProvider);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AppError
              ? error
              : AppError(type: AppErrorType.unknown, message: error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmLeave() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Batalkan perubahan?'),
      content: const Text('Perubahan yang belum disimpan akan hilang.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Tetap di Halaman'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );

  String _friendlyError(Object error) {
    if (error is AppError) {
      return switch (error.type) {
        AppErrorType.networkUnavailable || AppErrorType.timeout =>
          'Koneksi bermasalah. Periksa internet lalu coba lagi.',
        AppErrorType.unauthorized => 'Sesi berakhir. Silakan masuk kembali.',
        AppErrorType.forbidden =>
          'Anda tidak memiliki akses untuk mengubah pengaturan.',
        AppErrorType.validation => error.message,
        _ =>
          error.message.isEmpty
              ? 'Pengaturan gagal diproses. Coba lagi.'
              : error.message,
      };
    }
    return 'Pengaturan gagal diproses. Coba lagi.';
  }
}
