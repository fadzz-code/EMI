import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../data/dictionary_entry.dart';
import '../data/dictionary_providers.dart';

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

    return EmiScaffold(
      title: 'Kamus Mekongga',
      currentIndex: 2,
      onNavTap: (index) => _go(context, index),
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(dictionaryListProvider(query).future),
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(dictionaryListProvider(query)),
          ),
          data: (page) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              Text(
                'Kamus Mekongga',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: EmiSpacing.xs),
              const Text(
                'Cari arti kata dalam bahasa Indonesia, Inggris, atau Mekongga.',
              ),
              const SizedBox(height: EmiSpacing.lg),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari kata (Mekongga / Indo / Eng)...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
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
              const SizedBox(height: EmiSpacing.lg),
              if (page.items.isEmpty)
                const EmiCard(child: Text('Kata tidak ditemukan.'))
              else
                ...page.items.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
                    child: _DictionaryCard(entry: entry),
                  ),
                ),
              Text(
                'Halaman ${page.currentPage} dari ${page.lastPage} · ${page.total} kata',
                textAlign: TextAlign.center,
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
        selectedColor: EmiColors.primary,
        backgroundColor: EmiColors.surface,
        side: const BorderSide(color: EmiColors.border, width: 1.5),
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
    return InkWell(
      onTap: () => context.push('/student/dictionary/${entry.id}'),
      child: EmiCard(
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
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(entry.indonesia),
                    ],
                  ),
                ),
                if (entry.hasAudio)
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing == true;
                      return IconButton.filled(
                        key: Key('dictionaryAudio-${entry.id}'),
                        onPressed: _loading ? null : () => _toggle(playing),
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(playing ? Icons.pause : Icons.play_arrow),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: EmiSpacing.sm),
            Text(entry.english),
            if (_error != null) ...[
              const SizedBox(height: EmiSpacing.xs),
              Text(_error!, style: const TextStyle(color: EmiColors.error)),
            ],
            if (entry.category != null) ...[
              const SizedBox(height: EmiSpacing.sm),
              Text(
                entry.category!.name,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ],
        ),
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
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        EmiCard(
          child: Column(
            children: [
              Text(message),
              const SizedBox(height: EmiSpacing.md),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
