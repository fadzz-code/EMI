import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../data/admin_settings_providers.dart';
import '../data/admin_settings_repository.dart';
import 'admin_shell.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _appKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _subtitle = TextEditingController();
  final _year = TextEditingController();
  final _timezone = TextEditingController();
  bool _newLoginAlert = false;
  bool _weeklyReportEmail = false;
  bool _hydrated = false;
  bool _savingApp = false;
  bool _savingSecurity = false;
  AppError? _error;
  String? _success;

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    _year.dispose();
    _timezone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adminSettingsProvider);
    return AdminShell(
      title: 'Pengaturan',
      child: RefreshIndicator(
        onRefresh: () async {
          _hydrated = false;
          ref.invalidate(adminSettingsProvider);
        },
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              EmiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.toString()),
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
            if (!_hydrated) _hydrate(data);
            return ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                if (_success != null)
                  EmiCard(
                    child: Text(
                      _success!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                if (_error != null)
                  EmiCard(
                    child: Text(
                      _error!.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                EmiCard(
                  child: Form(
                    key: _appKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengaturan Aplikasi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Nama Aplikasi',
                          ),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _subtitle,
                          decoration: const InputDecoration(
                            labelText: 'Subtitle / Slogan',
                          ),
                        ),
                        TextFormField(
                          controller: _year,
                          decoration: const InputDecoration(
                            labelText: 'Tahun Ajaran Aktif',
                          ),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _timezone,
                          decoration: const InputDecoration(
                            labelText: 'Zona Waktu',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: EmiSpacing.sm),
                        FilledButton(
                          onPressed: _savingApp ? null : _saveApplication,
                          child: Text(
                            _savingApp
                                ? 'Menyimpan...'
                                : 'Simpan Pengaturan Aplikasi',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: EmiSpacing.md),
                EmiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Banner Login',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SwitchListTile(
                        value: data.banner.enabled,
                        onChanged: null,
                        title: const Text('Aktifkan Banner'),
                        subtitle: const Text(
                          'Upload banner belum tersedia di mobile.',
                        ),
                      ),
                      if (data.banner.imageUrl?.isNotEmpty == true)
                        Image.network(
                          data.banner.imageUrl!,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: EmiSpacing.md),
                EmiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keamanan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SwitchListTile(
                        value: _newLoginAlert,
                        onChanged: _savingSecurity
                            ? null
                            : (v) => setState(() => _newLoginAlert = v),
                        title: const Text('Peringatan Login Baru'),
                      ),
                      SwitchListTile(
                        value: _weeklyReportEmail,
                        onChanged: _savingSecurity
                            ? null
                            : (v) => setState(() => _weeklyReportEmail = v),
                        title: const Text('Email Laporan Mingguan'),
                      ),
                      FilledButton(
                        onPressed: _savingSecurity ? null : _saveSecurity,
                        child: Text(
                          _savingSecurity ? 'Menyimpan...' : 'Simpan Keamanan',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: EmiSpacing.md),
                EmiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (data.activityLogs.isEmpty)
                        const Text('Aktivitas belum tersedia.'),
                      for (final log in data.activityLogs)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(log.title),
                          subtitle: Text(
                            '${log.admin} • ${log.createdAt ?? '-'}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _hydrate(AdminSettings settings) {
    _name.text = settings.application.name;
    _subtitle.text = settings.application.subtitle;
    _year.text = settings.application.activeAcademicYear;
    _timezone.text = settings.application.timezone;
    _newLoginAlert = settings.security.newLoginAlert;
    _weeklyReportEmail = settings.security.weeklyReportEmail;
    _hydrated = true;
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;

  Future<void> _saveApplication() async {
    if (!_appKey.currentState!.validate()) return;
    setState(() {
      _savingApp = true;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(adminSettingsRepositoryProvider)
          .updateApplication(
            ApplicationSettings(
              name: _name.text.trim(),
              subtitle: _subtitle.text.trim(),
              activeAcademicYear: _year.text.trim(),
              timezone: _timezone.text.trim(),
            ),
          );
      ref.invalidate(adminSettingsProvider);
      if (mounted) {
        setState(() => _success = 'Pengaturan aplikasi berhasil disimpan.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _asError(e));
    } finally {
      if (mounted) setState(() => _savingApp = false);
    }
  }

  Future<void> _saveSecurity() async {
    setState(() {
      _savingSecurity = true;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(adminSettingsRepositoryProvider)
          .updateSecurity(
            SecuritySettings(
              newLoginAlert: _newLoginAlert,
              weeklyReportEmail: _weeklyReportEmail,
            ),
          );
      ref.invalidate(adminSettingsProvider);
      if (mounted) {
        setState(() => _success = 'Preferensi keamanan berhasil disimpan.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = _asError(e));
    } finally {
      if (mounted) setState(() => _savingSecurity = false);
    }
  }

  AppError _asError(Object e) => e is AppError
      ? e
      : AppError(type: AppErrorType.unknown, message: e.toString());
}
