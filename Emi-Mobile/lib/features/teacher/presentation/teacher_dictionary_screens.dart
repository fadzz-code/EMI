import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../../dictionary/data/dictionary_entry.dart';
import '../../dictionary/data/dictionary_providers.dart';
import 'teacher_shell.dart';
import 'teacher_style.dart';
import 'teacher_widgets.dart';

/// Teacher's read-only Dictionary browse. Same backend contract and data
/// models as the Student dictionary feature (`GET /dictionary`,
/// `GET /dictionary/:id` are shared, non-role-scoped endpoints) — this
/// screen reuses `dictionaryListProvider`/`dictionaryDetailProvider`
/// as-is, only the presentation layer (shell/style) differs to match the
/// Teacher role's visual language.
class TeacherDictionaryListScreen extends ConsumerStatefulWidget {
  const TeacherDictionaryListScreen({super.key});

  @override
  ConsumerState<TeacherDictionaryListScreen> createState() =>
      _TeacherDictionaryListScreenState();
}

class _TeacherDictionaryListScreenState
    extends ConsumerState<TeacherDictionaryListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _search;
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
      categoryId: _categoryId,
      page: _page,
    );
    final entries = ref.watch(dictionaryListProvider(query));

    return TeacherShell(
      title: 'Kamus Mekongga',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(dictionaryListProvider(query).future),
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            onRetry: () => ref.invalidate(dictionaryListProvider(query)),
          ),
          data: (page) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              const TeacherPageHeader(
                icon: Icons.translate_outlined,
                title: 'Kamus Mekongga',
                subtitle: 'Cari arti kata Indonesia, Inggris, atau Mekongga.',
              ),
              const SizedBox(height: EmiSpacing.md),
              TeacherSearchField(
                controller: _searchController,
                label: 'Cari kata (Mekongga / Indo / Eng)...',
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _search = null;
                    _page = 1;
                  });
                },
              ),
              const SizedBox(height: EmiSpacing.md),
              _CategoryChips(
                entries: page.items,
                activeId: _categoryId,
                onChanged: (id) => setState(() {
                  _categoryId = id;
                  _page = 1;
                }),
              ),
              const SizedBox(height: EmiSpacing.md),
              if (page.items.isEmpty)
                const FriendlyState(
                  icon: Icons.search_off_outlined,
                  title: 'Kata Tidak Ditemukan',
                  message: 'Coba kata kunci atau kategori lain.',
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
                style: const TextStyle(color: TeacherStyle.inkMuted),
              ),
              const SizedBox(height: EmiSpacing.sm),
              TeacherPaginationBar(
                currentPage: page.currentPage,
                lastPage: page.lastPage,
                previousKey: const Key('teacherDictionaryPreviousPage'),
                nextKey: const Key('teacherDictionaryNextPage'),
                onPrevious: page.currentPage > 1
                    ? () => setState(() => _page = page.currentPage - 1)
                    : null,
                onNext: page.hasNextPage
                    ? () => setState(() => _page = page.currentPage + 1)
                    : null,
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
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.entries,
    required this.activeId,
    required this.onChanged,
  });

  final List<DictionaryEntry> entries;
  final String? activeId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = <String, DictionaryCategory>{};
    for (final entry in entries) {
      final category = entry.category;
      if (category != null && category.id.isNotEmpty) {
        categories[category.id] = category;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'Semua',
            selected: activeId == null,
            onTap: () => onChanged(null),
          ),
          ...categories.values.map(
            (category) => _Chip(
              label: category.name,
              selected: activeId == category.id,
              onTap: () => onChanged(category.id),
            ),
          ),
        ],
      ),
    );
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
        backgroundColor: TeacherStyle.tint,
        labelStyle: TextStyle(
          color: selected ? Colors.white : TeacherStyle.inkMuted,
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
    return TeacherListCard(
      onTap: () => context.push('/teacher/dictionary/${entry.id}'),
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
                      ).textTheme.titleLarge?.copyWith(color: TeacherStyle.ink),
                    ),
                    Text(
                      entry.indonesia,
                      style: const TextStyle(color: TeacherStyle.inkMuted),
                    ),
                  ],
                ),
              ),
              if (entry.hasAudio)
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing == true;
                    return IconButton.filled(
                      key: Key('teacherDictionaryAudio-${entry.id}'),
                      tooltip: playing ? 'Jeda audio' : 'Putar audio',
                      onPressed: _loading ? null : () => _toggle(playing),
                      style: IconButton.styleFrom(
                        backgroundColor: TeacherStyle.tint,
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
          Text(entry.english, style: const TextStyle(color: TeacherStyle.ink)),
          if (_error != null) ...[
            const SizedBox(height: EmiSpacing.xs),
            Text(_error!, style: const TextStyle(color: EmiColors.error)),
          ],
          if (entry.category != null) ...[
            const SizedBox(height: EmiSpacing.sm),
            TeacherStatusChip(label: entry.category!.name),
          ],
        ],
      ),
    );
  }

  Future<void> _toggle(bool playing) async {
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
        await _player.setUrl(entry.audio!.url);
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
        FriendlyState(
          icon: Icons.cloud_off_outlined,
          title: 'Kamus Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}

/// Teacher's read-only Dictionary entry detail.
class TeacherDictionaryDetailScreen extends ConsumerWidget {
  const TeacherDictionaryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(dictionaryDetailProvider(entryId));

    return TeacherShell(
      title: 'Kamus Mekongga',
      fallbackRoute: '/teacher/dictionary',
      child: entry.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailErrorState(
          onRetry: () => ref.invalidate(dictionaryDetailProvider(entryId)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            _HeroCard(entry: data),
            const SizedBox(height: EmiSpacing.md),
            if (data.hasAudio) _DetailAudioPlayer(audio: data.audio!),
            if (data.hasAudio) const SizedBox(height: EmiSpacing.md),
            _ExamplesCard(entry: data),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.entry});

  final DictionaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return TeacherListCard(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.category != null)
            TeacherStatusChip(label: entry.category!.name),
          const SizedBox(height: EmiSpacing.md),
          Text(
            entry.mekongga,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: TeacherStyle.ink),
          ),
          const Divider(
            color: EmiColors.divider,
            thickness: 1,
            height: EmiSpacing.xl,
          ),
          _MeaningRow(label: 'Indonesia', value: entry.indonesia),
          const SizedBox(height: EmiSpacing.sm),
          _MeaningRow(label: 'English', value: entry.english),
        ],
      ),
    );
  }
}

class _MeaningRow extends StatelessWidget {
  const _MeaningRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: TeacherStyle.inkMuted),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: TeacherStyle.ink)),
        ),
      ],
    );
  }
}

class _DetailAudioPlayer extends StatefulWidget {
  const _DetailAudioPlayer({required this.audio});

  final DictionaryAudio audio;

  @override
  State<_DetailAudioPlayer> createState() => _DetailAudioPlayerState();
}

class _DetailAudioPlayerState extends State<_DetailAudioPlayer> {
  late final AudioPlayer _player;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EmiSpacing.md),
      decoration: BoxDecoration(
        color: TeacherStyle.tint,
        borderRadius: BorderRadius.circular(TeacherStyle.cardRadius),
        boxShadow: TeacherStyle.softShadow(),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing == true;
              return IconButton.filled(
                tooltip: playing ? 'Jeda audio' : 'Putar audio',
                onPressed: _loading ? null : () => _toggle(playing),
                style: IconButton.styleFrom(
                  backgroundColor: EmiColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(playing ? Icons.pause : Icons.play_arrow),
              );
            },
          ),
          const SizedBox(width: EmiSpacing.md),
          Expanded(
            child: Text(
              _error ?? 'Putar pelafalan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _error != null ? EmiColors.error : TeacherStyle.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(bool playing) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (playing) {
        await _player.pause();
      } else {
        if (_player.audioSource == null) await _player.setUrl(widget.audio.url);
        await _player.play();
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Audio gagal diputar.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ExamplesCard extends StatelessWidget {
  const _ExamplesCard({required this.entry});

  final DictionaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final examples = [
      if (entry.exampleMekongga != null || entry.exampleIndonesia != null)
        DictionaryExample(
          id: 'primary',
          mekongga: entry.exampleMekongga,
          indonesia: entry.exampleIndonesia,
        ),
      ...entry.examples,
    ];

    if (examples.isEmpty) return const SizedBox.shrink();

    return TeacherListCard(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TeacherSectionHeader(
            'Contoh Kalimat',
            icon: Icons.format_quote_outlined,
            leading: false,
          ),
          const SizedBox(height: EmiSpacing.sm),
          ...examples.map(
            (example) => Padding(
              padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EmiSpacing.md),
                decoration: BoxDecoration(
                  color: TeacherStyle.tint,
                  borderRadius: BorderRadius.circular(EmiRadii.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (example.mekongga != null)
                      Text(
                        example.mekongga!,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: TeacherStyle.ink),
                      ),
                    if (example.indonesia != null)
                      Text(
                        example.indonesia!,
                        style: const TextStyle(color: TeacherStyle.inkMuted),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        FriendlyState(
          icon: Icons.cloud_off_outlined,
          title: 'Kata Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}
