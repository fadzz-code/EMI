import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_providers.dart';
import '../data/admin_repository.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final summary = ref.watch(adminDashboardProvider);
    return AdminShell(
      title: 'Beranda Admin',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(adminDashboardProvider.future),
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => FriendlyState(
            icon: Icons.wifi_off_outlined,
            title: 'Data belum bisa dimuat',
            message: 'Periksa koneksi internetmu, lalu coba lagi.',
            onRetry: () => ref.invalidate(adminDashboardProvider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              RoleHeroHeader(
                greeting: 'Selamat datang,',
                name: user?.fullName ?? 'Admin EMI',
                message: 'Mari periksa kegiatan EMI hari ini.',
                icon: Icons.admin_panel_settings_outlined,
                action: IconButton(
                  tooltip: 'Profil',
                  onPressed: () => context.go('/admin/profile'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ),
              const SizedBox(height: EmiSpacing.xl),
              if (data.items.isEmpty)
                const FriendlyState(
                  icon: Icons.inbox_outlined,
                  title: 'Belum Ada Data',
                  message:
                      'Ringkasan akan muncul setelah data sekolah tersedia.',
                )
              else ...[
                Text(
                  'Ringkasan Utama',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: EmiSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: EmiSpacing.md,
                  mainAxisSpacing: EmiSpacing.md,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisExtent: 150,
                  children: [
                    for (final item in data.items)
                      SimpleStatItem(
                        label: item.label,
                        value: item.value,
                        icon: _metricIcon(item),
                        highlight: item.highlight,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: EmiSpacing.xl),
              Text(
                'Menu Cepat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: EmiSpacing.md),
              Wrap(
                spacing: EmiSpacing.sm,
                runSpacing: EmiSpacing.sm,
                children: [
                  for (final feature in AdminFeature.values.where(
                    (feature) => feature.isMobileImplemented,
                  ))
                    QuickActionItem(
                      label: feature.label,
                      icon: _featureIcon(feature),
                      onTap: () => context.go(feature.route),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _metricIcon(AdminMetric metric) => switch (metric.iconName) {
    'approval' => Icons.how_to_reg_outlined,
    'school' => Icons.apartment_outlined,
    'class' => Icons.school_outlined,
    'users' => Icons.people_outline,
    _ => Icons.insights_outlined,
  };

  IconData _featureIcon(AdminFeature feature) => switch (feature) {
    AdminFeature.approvals => Icons.how_to_reg_outlined,
    AdminFeature.schools => Icons.apartment_outlined,
    AdminFeature.dictionary => Icons.translate_outlined,
    AdminFeature.quizzes => Icons.quiz_outlined,
    AdminFeature.reports => Icons.bar_chart_outlined,
    AdminFeature.settings => Icons.settings_outlined,
    _ => Icons.apps_outlined,
  };
}

class AdminListScreen extends ConsumerWidget {
  const AdminListScreen({super.key, required this.feature});

  final AdminFeature feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (feature == AdminFeature.users) return const AdminUsersScreen();
    if (feature == AdminFeature.schools) return const AdminSchoolsScreen();
    final query = AdminFeatureQuery(feature: feature);
    final page = ref.watch(adminListProvider(query));
    return AdminShell(
      title: feature.label,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(adminListProvider(query).future),
        child: page.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => FriendlyState(
            icon: Icons.wifi_off_outlined,
            title: 'Data belum bisa dimuat',
            message: 'Periksa koneksi internetmu, lalu coba lagi.',
            onRetry: () => ref.invalidate(adminListProvider(query)),
          ),
          data: (data) => data.items.isEmpty
              ? const FriendlyState(
                  icon: Icons.inbox_outlined,
                  title: 'Belum Ada Data',
                  message: 'Data akan muncul setelah kegiatan EMI dimulai.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(EmiSpacing.md),
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: EmiSpacing.md),
                  itemBuilder: (context, index) {
                    final item = data.items[index];
                    return EmiCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title),
                        subtitle: item.subtitle == null
                            ? null
                            : Text(_simpleLabel(item.subtitle!)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('${feature.route}/${item.id}'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class AdminDetailScreen extends ConsumerWidget {
  const AdminDetailScreen({super.key, required this.feature, required this.id});

  final AdminFeature feature;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (feature == AdminFeature.users) return AdminUserDetailScreen(id: id);
    if (feature == AdminFeature.schools) return AdminSchoolDetailScreen(id: id);
    final detail = ref.watch(
      adminDetailProvider(AdminDetailQuery(feature: feature, id: id)),
    );
    return AdminShell(
      title: feature.label,
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Data belum bisa dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: () => ref.invalidate(
            adminDetailProvider(AdminDetailQuery(feature: feature, id: id)),
          ),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            EmiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (item.subtitle != null) Text(_simpleLabel(item.subtitle!)),
                  if (item.status != null) Text(_simpleLabel(item.status!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSchoolsScreen extends ConsumerStatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  ConsumerState<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends ConsumerState<AdminSchoolsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(adminSchoolsProvider);
    final query = ref.read(adminSchoolsProvider.notifier).query;
    return AdminShell(
      title: 'Sekolah',
      child: RefreshIndicator(
        onRefresh: () => ref.read(adminSchoolsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/admin/schools/create'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Sekolah'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari nama sekolah',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _showSchoolFilter(context, query),
                  icon: Badge(
                    isLabelVisible: query.status != null,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  ref.read(adminSchoolsProvider.notifier).search(value);
                });
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            page.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Data belum bisa dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(adminSchoolsProvider),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  final hasSearch = _search.text.trim().isNotEmpty;
                  return FriendlyState(
                    icon: Icons.apartment_outlined,
                    title: hasSearch
                        ? 'Sekolah Tidak Ditemukan'
                        : 'Belum Ada Sekolah',
                    message: hasSearch
                        ? 'Coba gunakan nama sekolah atau filter yang berbeda.'
                        : 'Tambahkan sekolah agar kelas dan pengguna dapat dikelola.',
                  );
                }
                return Column(
                  children: [
                    for (final school in data.items) ...[
                      _AdminSchoolTile(school: school),
                      const SizedBox(height: EmiSpacing.sm),
                    ],
                    if (data.hasMore)
                      FilledButton(
                        onPressed: () =>
                            ref.read(adminSchoolsProvider.notifier).loadMore(),
                        child: const Text('Muat Lagi'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSchoolFilter(
    BuildContext context,
    AdminListQuery query,
  ) async {
    String? status = query.status;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(EmiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: EmiSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'active', child: Text('Aktif')),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Tidak Aktif'),
                  ),
                ],
                onChanged: (value) => setSheetState(() => status = value),
              ),
              const SizedBox(height: EmiSpacing.lg),
              FilledButton(
                onPressed: () {
                  ref
                      .read(adminSchoolsProvider.notifier)
                      .filter(status: status);
                  Navigator.pop(context);
                },
                child: const Text('Terapkan'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(adminSchoolsProvider.notifier).filter();
                  Navigator.pop(context);
                },
                child: const Text('Hapus Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSchoolTile extends StatelessWidget {
  const _AdminSchoolTile({required this.school});

  final AdminSchool school;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const CircleAvatar(child: Icon(Icons.apartment_outlined)),
    title: Text(school.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      [
        _schoolStatusLabel(school.status),
        school.address ?? 'Alamat belum diisi',
        '${school.classesCount} kelas',
      ].join('\n'),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.go('/admin/schools/${school.id}'),
  );
}

class AdminSchoolDetailScreen extends ConsumerWidget {
  const AdminSchoolDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminSchoolDetailProvider(id));
    return AdminShell(
      title: 'Detail Sekolah',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Data belum bisa dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
          onRetry: () => ref.invalidate(adminSchoolDetailProvider(id)),
        ),
        data: (school) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            EmiCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.apartment_outlined),
                  ),
                  const SizedBox(width: EmiSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(_schoolStatusLabel(school.status)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Informasi Sekolah',
              rows: {
                'Alamat': school.address ?? 'Belum diisi',
                'Status': _schoolStatusLabel(school.status),
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Kontak',
              rows: {'Nomor Telepon': school.phone ?? '-'},
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Ringkasan',
              rows: {'Jumlah Kelas': '${school.classesCount} kelas'},
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton(
              onPressed: () => context.go('/admin/schools/${school.id}/edit'),
              child: const Text('Edit Sekolah'),
            ),
            const SizedBox(height: EmiSpacing.sm),
            OutlinedButton(
              onPressed: () => _confirmSchoolStatus(context, ref, school),
              child: Text(
                school.status == 'active'
                    ? 'Nonaktifkan Sekolah'
                    : 'Aktifkan Sekolah',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSchoolStatus(
    BuildContext context,
    WidgetRef ref,
    AdminSchool school,
  ) async {
    final activate = school.status != 'active';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          activate ? 'Aktifkan sekolah ini?' : 'Nonaktifkan sekolah ini?',
        ),
        content: Text(
          activate
              ? 'Sekolah dapat digunakan kembali untuk pengelolaan kelas dan pengguna.'
              : 'Sekolah tidak dapat digunakan untuk kegiatan baru sampai diaktifkan kembali. Data yang sudah ada tidak akan langsung dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(activate ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (activate) {
      await ref
          .read(adminRepositoryProvider)
          .saveSchool(
            id: school.id,
            name: school.name,
            address: school.address,
            phone: school.phone,
            status: 'active',
          );
    } else {
      await ref.read(adminRepositoryProvider).deactivateSchool(school.id);
    }
    if (!context.mounted) return;
    ref.invalidate(adminSchoolDetailProvider(school.id));
    ref.invalidate(adminSchoolsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          activate
              ? 'Sekolah berhasil diaktifkan.'
              : 'Sekolah berhasil dinonaktifkan.',
        ),
      ),
    );
  }
}

class AdminSchoolFormScreen extends ConsumerWidget {
  const AdminSchoolFormScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = id == null
        ? null
        : ref.watch(adminSchoolDetailProvider(id!));
    return AdminShell(
      title: id == null ? 'Tambah Sekolah' : 'Edit Sekolah',
      child: id == null
          ? const _AdminSchoolForm()
          : detail!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Data belum bisa dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(adminSchoolDetailProvider(id!)),
              ),
              data: (school) => _AdminSchoolForm(school: school),
            ),
    );
  }
}

class _AdminSchoolForm extends ConsumerStatefulWidget {
  const _AdminSchoolForm({this.school});

  final AdminSchool? school;

  @override
  ConsumerState<_AdminSchoolForm> createState() => _AdminSchoolFormState();
}

class _AdminSchoolFormState extends ConsumerState<_AdminSchoolForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.school?.name ?? '');
    _address = TextEditingController(text: widget.school?.address ?? '');
    _phone = TextEditingController(text: widget.school?.phone ?? '');
    _status = widget.school?.status == 'inactive' ? 'inactive' : 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(EmiSpacing.md),
    children: [
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama Sekolah'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama sekolah wajib diisi.'
                  : null,
            ),
            const SizedBox(height: EmiSpacing.md),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Nomor Telepon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: EmiSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Aktif')),
                DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _status = value ?? 'active'),
            ),
            const SizedBox(height: EmiSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(adminRepositoryProvider)
          .saveSchool(
            id: widget.school?.id,
            name: _name.text.trim(),
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            status: _status,
          );
      ref.invalidate(adminSchoolsProvider);
      ref.invalidate(adminSchoolDetailProvider(saved.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.school == null
                ? 'Sekolah berhasil ditambahkan.'
                : 'Sekolah berhasil disimpan.',
          ),
        ),
      );
      context.go('/admin/schools/${saved.id}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data belum bisa disimpan.')),
      );
      setState(() => _saving = false);
    }
  }
}

String _schoolStatusLabel(String value) => switch (value) {
  'active' => 'Aktif',
  'inactive' => 'Tidak Aktif',
  _ => 'Status Tidak Dikenal',
};

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(adminUsersProvider);
    final query = ref.read(adminUsersProvider.notifier).query;
    return AdminShell(
      title: 'Guru dan Siswa',
      child: RefreshIndicator(
        onRefresh: () => ref.read(adminUsersProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _showUserFilter(context, query),
                  icon: Badge(
                    isLabelVisible: query.role != null || query.status != null,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  ref.read(adminUsersProvider.notifier).search(value);
                });
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            page.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Data belum bisa dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(adminUsersProvider),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  final hasSearch = _search.text.trim().isNotEmpty;
                  return FriendlyState(
                    icon: Icons.people_outline,
                    title: hasSearch
                        ? 'Pengguna Tidak Ditemukan'
                        : 'Belum Ada Pengguna',
                    message: hasSearch
                        ? 'Coba gunakan nama, email, atau filter yang berbeda.'
                        : 'Data Guru dan Siswa akan muncul setelah akun dibuat atau disetujui.',
                  );
                }
                return Column(
                  children: [
                    for (final user in data.items) ...[
                      _AdminUserTile(user: user),
                      const SizedBox(height: EmiSpacing.sm),
                    ],
                    if (data.hasMore)
                      FilledButton(
                        onPressed: () =>
                            ref.read(adminUsersProvider.notifier).loadMore(),
                        child: const Text('Muat Lagi'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserFilter(
    BuildContext context,
    AdminListQuery query,
  ) async {
    String? role = query.role;
    String? status = query.status;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(EmiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: EmiSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'teacher', child: Text('Guru')),
                  DropdownMenuItem(value: 'student', child: Text('Siswa')),
                ],
                onChanged: (value) => setSheetState(() => role = value),
              ),
              const SizedBox(height: EmiSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'approved', child: Text('Aktif')),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Tidak Aktif'),
                  ),
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('Menunggu Persetujuan'),
                  ),
                  DropdownMenuItem(
                    value: 'rejected',
                    child: Text('Belum Disetujui'),
                  ),
                ],
                onChanged: (value) => setSheetState(() => status = value),
              ),
              const SizedBox(height: EmiSpacing.lg),
              FilledButton(
                onPressed: () {
                  ref
                      .read(adminUsersProvider.notifier)
                      .filter(role: role, status: status);
                  Navigator.pop(context);
                },
                child: const Text('Terapkan'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(adminUsersProvider.notifier).filter();
                  Navigator.pop(context);
                },
                child: const Text('Hapus Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminUserTile extends StatelessWidget {
  const _AdminUserTile({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      child: Icon(user.role == 'teacher' ? Icons.school : Icons.person),
    ),
    title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      [
        '${_roleLabel(user.role)} • ${_statusLabel(user.status)}',
        user.schoolName ?? 'Belum Ada Sekolah',
        user.className ?? 'Belum Ditempatkan ke Kelas',
      ].join('\n'),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.go('/admin/users/${user.id}'),
  );
}

class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminUserDetailProvider(id));
    return AdminShell(
      title: 'Guru dan Siswa',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Data belum bisa dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
          onRetry: () => ref.invalidate(adminUserDetailProvider(id)),
        ),
        data: (user) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            _AdminUserHeader(user: user),
            const SizedBox(height: EmiSpacing.lg),
            _InfoSection(
              title: 'Data Akun',
              rows: {
                'Email': user.email,
                'Role': _roleLabel(user.role),
                'Status': _statusLabel(user.status),
                'Nomor Telepon': user.phone ?? '-',
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Sekolah dan Kelas',
              rows: {
                'Sekolah': user.schoolName ?? 'Belum Ada Sekolah',
                'Kelas': user.className ?? 'Belum Ditempatkan ke Kelas',
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton(
              onPressed: () => _showEditUser(context, ref, user),
              child: const Text('Edit Data'),
            ),
            const SizedBox(height: EmiSpacing.sm),
            OutlinedButton(
              onPressed: () => _confirmStatus(context, ref, user),
              child: Text(
                user.status == 'approved'
                    ? 'Nonaktifkan Akun'
                    : 'Aktifkan Akun',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUser(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EditUserForm(user: user),
    );
    if (updated == true) {
      ref.invalidate(adminUserDetailProvider(user.id));
      ref.invalidate(adminUsersProvider);
    }
  }

  Future<void> _confirmStatus(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final activate = user.status != 'approved';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activate ? 'Aktifkan akun ini?' : 'Nonaktifkan akun ini?'),
        content: Text(
          activate
              ? 'Pengguna dapat masuk kembali setelah akun diaktifkan.'
              : 'Pengguna tidak dapat masuk sampai akun diaktifkan kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(activate ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(adminRepositoryProvider)
        .updateUserStatus(
          user.id,
          status: activate ? 'approved' : 'inactive',
          reason: activate ? null : 'Dinonaktifkan dari aplikasi mobile',
        );
    if (!context.mounted) return;
    ref.invalidate(adminUserDetailProvider(user.id));
    ref.invalidate(adminUsersProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          activate
              ? 'Akun berhasil diaktifkan.'
              : 'Akun berhasil dinonaktifkan.',
        ),
      ),
    );
  }
}

class _EditUserForm extends ConsumerStatefulWidget {
  const _EditUserForm({required this.user});

  final AdminUser user;

  @override
  ConsumerState<_EditUserForm> createState() => _EditUserFormState();
}

class _EditUserFormState extends ConsumerState<_EditUserForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        EmiSpacing.lg,
        EmiSpacing.lg,
        EmiSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + EmiSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Data', style: Theme.of(context).textTheme.titleLarge),
            Text('Email: ${widget.user.email}'),
            const SizedBox(height: EmiSpacing.md),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama wajib diisi.'
                  : null,
            ),
            const SizedBox(height: EmiSpacing.md),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Nomor Telepon'),
            ),
            const SizedBox(height: EmiSpacing.lg),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                try {
                  await ref
                      .read(adminRepositoryProvider)
                      .updateUser(
                        widget.user.id,
                        name: _name.text.trim(),
                        email: widget.user.email,
                        phone: _phone.text.trim().isEmpty
                            ? null
                            : _phone.text.trim(),
                      );
                  if (context.mounted) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data pengguna berhasil disimpan.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data belum bisa disimpan.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUserHeader extends StatelessWidget {
  const _AdminUserHeader({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          child: Icon(user.role == 'teacher' ? Icons.school : Icons.person),
        ),
        const SizedBox(width: EmiSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text('${_roleLabel(user.role)} • ${_statusLabel(user.status)}'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EmiSpacing.sm),
        for (final row in rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: EmiSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 120, child: Text(row.key)),
                Expanded(
                  child: Text(
                    row.value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

String _roleLabel(String value) => switch (value) {
  'teacher' => 'Guru',
  'student' => 'Siswa',
  'admin' => 'Admin',
  _ => 'Pengguna',
};

String _statusLabel(String value) => switch (value) {
  'approved' => 'Aktif',
  'active' => 'Aktif',
  'inactive' => 'Tidak Aktif',
  'pending' => 'Menunggu Persetujuan',
  'rejected' => 'Belum Disetujui',
  _ => 'Status Tidak Dikenal',
};

String _simpleLabel(String value) => switch (value) {
  'teacher' => 'Guru',
  'student' => 'Siswa',
  'admin' => 'Admin',
  'active' => 'Aktif',
  'inactive' => 'Tidak Aktif',
  _ => value,
};
