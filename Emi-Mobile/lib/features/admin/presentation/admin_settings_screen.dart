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
import 'admin_widgets.dart';

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

enum _SettingsSection { application, profile, banner, security, password }

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _applicationFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
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
  final Set<_SettingsSection> _saving = {};
  final Map<_SettingsSection, AppError> _errors = {};
  final Map<_SettingsSection, String> _successes = {};

  bool get _passwordDirty =>
      _currentPassword.text.isNotEmpty ||
      _password.text.isNotEmpty ||
      _passwordConfirmation.text.isNotEmpty;

  bool get _applicationDirty {
    final baseline = _applicationBaseline;
    return _hydrated &&
        baseline != null &&
        (_name.text.trim() != baseline.name ||
            _subtitle.text.trim() != baseline.subtitle ||
            _year.text.trim() != baseline.activeAcademicYear ||
            _timezone != baseline.timezone);
  }

  bool get _profileDirty {
    final baseline = _profileBaseline;
    return _hydrated &&
        baseline != null &&
        (_fullName.text.trim() != baseline.fullName ||
            _phone.text.trim() != (baseline.phone ?? ''));
  }

  bool get _bannerDirty =>
      _hydrated &&
      _bannerBaseline != null &&
      (_bannerEnabled != _bannerBaseline!.enabled || _bannerFile != null);

  bool get _securityDirty {
    final baseline = _securityBaseline;
    return _hydrated &&
        baseline != null &&
        (_newLoginAlert != baseline.newLoginAlert ||
            _weeklyReportEmail != baseline.weeklyReportEmail);
  }

  bool get _dirty =>
      _applicationDirty ||
      _profileDirty ||
      _bannerDirty ||
      _securityDirty ||
      _passwordDirty;

  bool _isSaving(_SettingsSection section) => _saving.contains(section);

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
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_friendlyError(error)),
                      const SizedBox(height: EmiSpacing.sm),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(adminSettingsProvider),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
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

  Widget _content(
    AdminSettings data,
    SessionUser? user,
  ) => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(EmiSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Pengaturan Aplikasi', [
          Form(
            key: _applicationFormKey,
            child: Column(
              children: [
                _field(_name, 'Nama Aplikasi', required: true),
                const SizedBox(height: EmiSpacing.md),
                _field(_subtitle, 'Subtitle / Slogan'),
                const SizedBox(height: EmiSpacing.md),
                _field(_year, 'Tahun Ajaran Aktif', required: true),
                const SizedBox(height: EmiSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _timezone,
                  decoration: const InputDecoration(labelText: 'Zona Waktu'),
                  items:
                      {
                            _timezone,
                            'Asia/Jakarta',
                            'Asia/Makassar',
                            'Asia/Jayapura',
                          }
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: _isSaving(_SettingsSection.application)
                      ? null
                      : (value) =>
                            setState(() => _timezone = value ?? _timezone),
                ),
              ],
            ),
          ),
          _sectionStatus(_SettingsSection.application),
          _saveButton(
            key: const Key('saveApplicationSettings'),
            section: _SettingsSection.application,
            dirty: _applicationDirty,
            label: 'Simpan Pengaturan Aplikasi',
            onPressed: _saveApplication,
          ),
        ]),
        _section('Profil Admin', [
          Form(
            key: _profileFormKey,
            child: Column(
              children: [
                _field(_fullName, 'Nama Lengkap', required: true),
                const SizedBox(height: EmiSpacing.md),
                _field(
                  _phone,
                  'Telepon Admin',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  initialValue: user?.email ?? '',
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Email Kantor'),
                ),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  initialValue: user?.status ?? '',
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Status Akun'),
                ),
              ],
            ),
          ),
          _sectionStatus(_SettingsSection.profile),
          _saveButton(
            key: const Key('saveProfileSettings'),
            section: _SettingsSection.profile,
            dirty: _profileDirty,
            label: 'Simpan Profil',
            onPressed: _saveProfile,
          ),
        ]),
        _section('Pengaturan Banner Login', [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _bannerEnabled,
            onChanged: _isSaving(_SettingsSection.banner)
                ? null
                : (value) => setState(() => _bannerEnabled = value),
            title: const Text('Aktifkan Banner'),
          ),
          if (_bannerFile != null)
            Image.file(File(_bannerFile!.path!), height: 140, fit: BoxFit.cover)
          else if (data.banner.imageUrl?.isNotEmpty == true)
            Image.network(data.banner.imageUrl!, height: 140, fit: BoxFit.cover)
          else
            const Text('Banner belum diunggah.'),
          OutlinedButton.icon(
            onPressed: _isSaving(_SettingsSection.banner) ? null : _pickBanner,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Pilih Gambar Banner'),
          ),
          _sectionStatus(_SettingsSection.banner),
          _saveButton(
            key: const Key('saveBannerSettings'),
            section: _SettingsSection.banner,
            dirty: _bannerDirty,
            label: 'Simpan Banner',
            onPressed: _saveBanner,
          ),
        ]),
        _section('Keamanan', [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _newLoginAlert,
            onChanged: _isSaving(_SettingsSection.security)
                ? null
                : (value) => setState(() => _newLoginAlert = value),
            title: const Text('Peringatan Login Baru'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _weeklyReportEmail,
            onChanged: _isSaving(_SettingsSection.security)
                ? null
                : (value) => setState(() => _weeklyReportEmail = value),
            title: const Text('Email Laporan Mingguan'),
          ),
          _sectionStatus(_SettingsSection.security),
          _saveButton(
            key: const Key('saveSecuritySettings'),
            section: _SettingsSection.security,
            dirty: _securityDirty,
            label: 'Simpan Keamanan',
            onPressed: _saveSecurity,
          ),
        ]),
        _section('Ubah Password', [
          const Text('Kosongkan jika tidak ingin mengubah password.'),
          _secret(_currentPassword, 'Password Lama'),
          _secret(_password, 'Password Baru'),
          _secret(_passwordConfirmation, 'Konfirmasi Password Baru'),
          _sectionStatus(_SettingsSection.password),
          _saveButton(
            key: const Key('savePasswordSettings'),
            section: _SettingsSection.password,
            dirty: _passwordDirty,
            label: 'Ubah Password',
            onPressed: _savePassword,
          ),
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
      ],
    ),
  );

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminSectionHeader(title, leading: false),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const SizedBox(height: EmiSpacing.md),
              ],
            ],
          ),
        ),
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

  Widget _sectionStatus(_SettingsSection section) {
    final success = _successes[section];
    final error = _errors[section];
    if (error != null) return _message(_friendlyError(error), EmiColors.error);
    if (success != null) return _message(success, EmiColors.success);
    return const SizedBox.shrink();
  }

  Widget _saveButton({
    required Key key,
    required _SettingsSection section,
    required bool dirty,
    required String label,
    required VoidCallback onPressed,
  }) {
    final saving = _isSaving(section);
    return FilledButton(
      key: key,
      onPressed: !dirty || saving ? null : onPressed,
      child: Text(saving ? 'Menyimpan...' : label),
    );
  }

  Widget _message(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: Container(
      padding: const EdgeInsets.all(EmiSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(EmiRadii.card),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    ),
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

  Future<void> _runSave(
    _SettingsSection section,
    String success,
    Future<void> Function() save,
  ) async {
    if (_isSaving(section)) return;
    setState(() {
      _saving.add(section);
      _errors.remove(section);
      _successes.remove(section);
    });
    try {
      await save();
      if (mounted) setState(() => _successes[section] = success);
    } catch (error) {
      if (mounted) {
        setState(
          () => _errors[section] = error is AppError
              ? error
              : const AppError(
                  type: AppErrorType.unknown,
                  message: 'Pengaturan gagal diproses. Coba lagi.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(section));
    }
  }

  Future<void> _saveApplication() async {
    if (!_applicationDirty || !_applicationFormKey.currentState!.validate()) {
      return;
    }
    await _runSave(
      _SettingsSection.application,
      'Pengaturan aplikasi berhasil disimpan.',
      () async {
        _applicationBaseline = await ref
            .read(adminSettingsRepositoryProvider)
            .updateApplication(
              ApplicationSettings(
                name: _name.text.trim(),
                subtitle: _subtitle.text.trim(),
                activeAcademicYear: _year.text.trim(),
                timezone: _timezone,
              ),
            );
        ref.invalidate(adminSettingsProvider);
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_profileDirty || !_profileFormKey.currentState!.validate()) return;
    await _runSave(
      _SettingsSection.profile,
      'Profil admin berhasil disimpan.',
      () async {
        _profileBaseline = await ref
            .read(authRepositoryProvider)
            .updateProfile(
              fullName: _fullName.text.trim(),
              phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            );
      },
    );
  }

  Future<void> _saveBanner() async {
    if (!_bannerDirty) return;
    await _runSave(
      _SettingsSection.banner,
      'Banner login berhasil disimpan.',
      () async {
        _bannerBaseline = await ref
            .read(adminSettingsRepositoryProvider)
            .updateBanner(
              enabled: _bannerEnabled,
              path: _bannerFile?.path,
              fileName: _bannerFile?.name,
            );
        _bannerFile = null;
        ref.invalidate(adminSettingsProvider);
      },
    );
  }

  Future<void> _saveSecurity() async {
    if (!_securityDirty) return;
    await _runSave(
      _SettingsSection.security,
      'Preferensi keamanan berhasil disimpan.',
      () async {
        _securityBaseline = await ref
            .read(adminSettingsRepositoryProvider)
            .updateSecurity(
              SecuritySettings(
                newLoginAlert: _newLoginAlert,
                weeklyReportEmail: _weeklyReportEmail,
              ),
            );
        ref.invalidate(adminSettingsProvider);
      },
    );
  }

  Future<void> _savePassword() async {
    if (!_passwordDirty) return;
    final error = _passwordValidation();
    if (error != null) {
      setState(
        () => _errors[_SettingsSection.password] = AppError(
          type: AppErrorType.validation,
          message: error,
        ),
      );
      return;
    }
    await _runSave(
      _SettingsSection.password,
      'Password berhasil diperbarui.',
      () async {
        _profileBaseline = await ref
            .read(authRepositoryProvider)
            .updatePassword(
              currentPassword: _currentPassword.text,
              password: _password.text,
              passwordConfirmation: _passwordConfirmation.text,
            );
        _currentPassword.clear();
        _password.clear();
        _passwordConfirmation.clear();
      },
    );
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
