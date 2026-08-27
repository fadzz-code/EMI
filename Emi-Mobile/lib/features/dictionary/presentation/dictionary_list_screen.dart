import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/network/network_status_controller.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_connectivity_banner.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../data/dictionary_entry.dart';
import '../data/dictionary_providers.dart';
import 'dictionary_offline_providers.dart';

class DictionaryListScreen extends ConsumerStatefulWidget {
  const DictionaryListScreen({super.key});

  @override
  ConsumerState<DictionaryListScreen> createState() =>
      _DictionaryListScreenState();
}

class _DictionaryListScreenState extends ConsumerState<DictionaryListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _search;
  String _language = 'all';
  String? _categoryId;
  int _page = 1;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = DictionaryQuery(
      search: _search,
      language: _language,
      categoryId: _categoryId,
      page: _page,
    );
    final entries = ref.watch(integratedDictionaryListProvider(query));
    final categories = ref.watch(dictionaryCategoriesProvider);
    final networkMode = ref.watch(dictionaryNetworkModeProvider);

    return EmiScaffold(
      title: 'Kamus Mekongga',
      currentIndex: 2,
      onNavTap: (index) => _go(context, index),
      child: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(integratedDictionaryListProvider(query).future),
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            onRetry: () =>
                ref.invalidate(integratedDictionaryListProvider(query)),
          ),
          data: (page) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              StudentConnectivityBanner(mode: networkMode),
              const StudentPageHeader(
                icon: Icons.translate_outlined,
                title: 'Kamus Mekongga',
                subtitle: 'Cari arti kata Indonesia, Inggris, atau Mekongga.',
              ),
              const SizedBox(height: EmiSpacing.md),
              StudentConnectivityBanner(mode: networkMode),
              if (networkMode != NetworkMode.online)
                const SizedBox(height: EmiSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: StudentStyle.tint,
                  borderRadius: BorderRadius.circular(EmiRadii.pill),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: StudentStyle.ink),
                  decoration: const InputDecoration(
                    hintText: 'Cari kata (Mekongga / Indo / Eng)...',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: EmiSpacing.md,
                      vertical: EmiSpacing.sm,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: StudentStyle.inkMuted,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: EmiSpacing.md),
              _LanguageChips(
                active: _language,
                onChanged: (language) => setState(() {
                  _language = language;
                  _page = 1;
                }),
              ),
              const SizedBox(height: EmiSpacing.sm),
              _CategoryChips(
                categories:
                    categories.valueOrNull ?? _categoriesFrom(page.items),
                activeId: _categoryId,
                onChanged: (id) => setState(() {
                  _categoryId = id;
                  _page = 1;
                }),
                controller: ref.watch(dictionaryPackageControllerProvider),
              ),
              const SizedBox(height: EmiSpacing.md),
              if (page.items.isEmpty)
                StudentPlaceholder(
                  icon: Icons.search_off_outlined,
                  title: 'Kata Tidak Ditemukan',
                  message: networkMode == NetworkMode.online
                      ? 'Coba kata kunci atau kategori lain.'
                      : 'Kata tidak ditemukan di kamus yang tersimpan.',
                )
              else
                ...page.items.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
                    child: _DictionaryCard(entry: entry),
                  ),
                ),
              const SizedBox(height: EmiSpacing.xs),
              Text(
                'Halaman ${page.currentPage} dari ${page.lastPage} · ${page.total} kata',
                textAlign: TextAlign.center,
                style: const TextStyle(color: StudentStyle.inkMuted),
              ),
              const SizedBox(height: EmiSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('dictionaryPreviousPage'),
                      onPressed: page.currentPage > 1
                          ? () => setState(() => _page = page.currentPage - 1)
                          : null,
                      child: const Text('Sebelumnya'),
                    ),
                  ),
                  const SizedBox(width: EmiSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('dictionaryNextPage'),
                      onPressed: page.hasNextPage
                          ? () => setState(() => _page = page.currentPage + 1)
                          : null,
                      child: const Text('Berikutnya'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _search = value.trim().isEmpty ? null : value.trim();
        _page = 1;
      });
    });
  }

  void _go(BuildContext context, int index) {
    if (index == 0) context.go('/student/dashboard');
    if (index == 1) context.go('/student/modules');
    if (index == 2) context.go('/student/dictionary');
    if (index == 3) context.go('/student/quizzes');
    if (index == 4) context.go('/student/profile');
  }
}

class _LanguageChips extends StatelessWidget {
  const _LanguageChips({required this.active, required this.onChanged});

  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const languages = {
      'all': 'Semua bahasa',
      'indonesia': 'Indonesia',
      'english': 'Inggris',
      'mekongga': 'Mekongga',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: languages.entries
            .map(
              (language) => _Chip(
                label: language.value,
                selected: active == language.key,
                onTap: () => onChanged(language.key),
              ),
            )
            .toList(),
      ),
    );
  }
}

List<DictionaryCategory> _categoriesFrom(List<DictionaryEntry> entries) {
  final values = <String, DictionaryCategory>{};
  for (final entry in entries) {
    final category = entry.category;
    if (category != null && category.id.isNotEmpty) {
      values[category.id] = category;
    }
  }
  return values.values.toList();
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.activeId,
    required this.onChanged,
    required this.controller,
  });

  final List<DictionaryCategory> categories;
  final String? activeId;
  final ValueChanged<String?> onChanged;
  final DictionaryPackageController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _Chip(
            label: 'Semua',
            selected: activeId == null,
            onTap: () => onChanged(null),
          ),
        ),
        ...categories.map(
          (category) => Consumer(
            builder: (context, ref, _) {
              final package = ref.watch(
                dictionaryPackageStateProvider(category.id),
              );
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Flexible(
                      child: _Chip(
                        label: category.name,
                        selected: activeId == category.id,
                        onTap: () => onChanged(category.id),
                      ),
                    ),
                    if (package.valueOrNull?.isNew == true)
                      const StudentStatusChip(label: 'BARU'),
                    if (package.valueOrNull?.status ==
                        DictionaryPackageStatus.updateAvailable)
                      const StudentStatusChip(label: 'Pembaruan'),
                  ],
                ),
                trailing: _PackageAction(
                  state:
                      package.valueOrNull ??
                      const DictionaryPackageState(
                        DictionaryPackageStatus.download,
                      ),
                  onDownload: category.entriesCount == 0
                      ? null
                      : () => _showDownload(context, category, controller),
                  onRemove: () => controller.remove(category.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Future<void> _showDownload(
    BuildContext context,
    DictionaryCategory category,
    DictionaryPackageController controller,
  ) async {
    var audio = await controller.includeAudioDefault(category.id);
    if (!context.mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Unduh ${category.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kata dan arti wajib diunduh agar kategori dapat dicari tanpa internet.',
              ),
              const SizedBox(height: EmiSpacing.sm),
              const Text('Contoh kalimat ikut diunduh.'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: audio,
                title: const Text('Sertakan audio'),
                onChanged: (value) =>
                    setDialogState(() => audio = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Download'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      try {
        await controller.download(category.id, includeAudio: audio);
      } catch (e) {
        if (!context.mounted) return;
        if (e.toString().contains('berubah saat diunduh')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kategori gagal diunduh karena versi telah berubah di server. Kategori lama tetap tersimpan. Daftar kategori telah dimuat ulang, silakan coba unduh lagi.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }
  }
}

class _PackageAction extends StatelessWidget {
  const _PackageAction({
    required this.state,
    required this.onDownload,
    required this.onRemove,
  });

  final DictionaryPackageState state;
  final VoidCallback? onDownload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case DictionaryPackageStatus.downloading:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: EmiSpacing.xs),
            Text('MENGUNDUH'),
          ],
        );
      case DictionaryPackageStatus.availableOffline:
        return PopupMenuButton<void>(
          tooltip: 'Tersedia offline',
          onSelected: (_) => _showRemove(context, onRemove),
          itemBuilder: (_) => const [
            PopupMenuItem(value: null, child: Text('Hapus dari Perangkat')),
          ],
          child: const Chip(label: Text('Tersedia offline')),
        );
      case DictionaryPackageStatus.updateAvailable:
        return TextButton(
          onPressed: onDownload,
          child: const Text('Pembaruan tersedia'),
        );
      case DictionaryPackageStatus.retry:
        return TextButton(
          onPressed: onDownload,
          child: const Text('GAGAL MENGUNDUH'),
        );
      case DictionaryPackageStatus.download:
        return TextButton(
          onPressed: onDownload,
          child: const Text('BELUM DIUNDUH'),
        );
    }
  }

  Future<void> _showRemove(BuildContext context, VoidCallback onRemove) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kamus'),
        content: const Text(
          'Kategori ini tidak bisa dicari saat offline jika dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (accepted == true) onRemove();
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: EmiSpacing.sm),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: EmiColors.primary,
        backgroundColor: StudentStyle.tint,
        labelStyle: TextStyle(
          color: selected ? Colors.white : StudentStyle.inkMuted,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmiRadii.pill),
        ),
      ),
    );
  }
}

class _DictionaryCard extends ConsumerStatefulWidget {
  const _DictionaryCard({required this.entry});

  final DictionaryEntry entry;

  @override
  ConsumerState<_DictionaryCard> createState() => _DictionaryCardState();
}

class _DictionaryCardState extends ConsumerState<_DictionaryCard> {
  late final DictionaryAudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = ref.read(dictionaryAudioPlayerFactoryProvider)();
  }

  bool _loading = false;
  String? _error;

  DictionaryEntry get entry => widget.entry;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = entry.audio == null
        ? const AsyncValue<String?>.data(null)
        : ref.watch(
            dictionaryAudioSourceProvider(
              DictionaryAudioQuery(
                id: entry.audio!.id,
                remoteUrl: entry.audio!.url,
              ),
            ),
          );
    return StudentCard(
      onTap: () => context.push('/student/dictionary/${entry.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.mekongga,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: StudentStyle.ink),
                    ),
                    Text(
                      entry.indonesia,
                      style: const TextStyle(color: StudentStyle.inkMuted),
                    ),
                  ],
                ),
              ),
              if (entry.hasAudio && source.valueOrNull != null)
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing == true;
                    return IconButton.filled(
                      key: Key('dictionaryAudio-${entry.id}'),
                      tooltip: playing ? 'Jeda audio' : 'Putar audio',
                      onPressed: _loading
                          ? null
                          : () => _toggle(playing, source.valueOrNull!),
                      style: IconButton.styleFrom(
                        backgroundColor: StudentStyle.tint,
                        foregroundColor: EmiColors.primary,
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(playing ? Icons.pause : Icons.play_arrow),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: EmiSpacing.sm),
          Text(entry.english, style: const TextStyle(color: StudentStyle.ink)),
          if (entry.hasAudio &&
              source.hasValue &&
              source.valueOrNull == null) ...[
            const SizedBox(height: EmiSpacing.xs),
            const Text(
              'Audio belum diunduh untuk penggunaan offline.',
              style: TextStyle(color: StudentStyle.inkMuted),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: EmiSpacing.xs),
            Text(_error!, style: const TextStyle(color: EmiColors.error)),
          ],
          if (entry.category != null) ...[
            const SizedBox(height: EmiSpacing.sm),
            StudentStatusChip(label: entry.category!.name),
          ],
        ],
      ),
    );
  }

  Future<void> _toggle(bool playing, String source) async {
    if (_loading) return;
    if (playing) {
      await _player.pause();
      return;
    }
    try {
      if (!_player.hasSource) {
        setState(() {
          _loading = true;
          _error = null;
        });
        await _player.setUrl(source);
        if (!mounted) return;
        setState(() => _loading = false);
      }
      await _player.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Audio gagal diputar. Coba lagi.';
        });
      }
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        StudentPlaceholder(
          icon: Icons.cloud_off_outlined,
          title: 'Kamus Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}
