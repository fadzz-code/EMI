import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/network/network_status_controller.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_connectivity_banner.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../data/culture_models.dart';
import '../data/culture_providers.dart';

class StudentCultureListScreen extends ConsumerStatefulWidget {
  const StudentCultureListScreen({super.key});

  @override
  ConsumerState<StudentCultureListScreen> createState() =>
      _StudentCultureListScreenState();
}

class _StudentCultureListScreenState
    extends ConsumerState<StudentCultureListScreen> {
  static const _perPage = 15;
  var _page = 1;
  var _items = <CultureItem>[];
  var _hasNextPage = false;
  var _loadingMore = false;
  final _loadedPages = <int>{};

  @override
  Widget build(BuildContext context) {
    final query = CultureQuery(page: _page, perPage: _perPage);
    final page = ref.watch(cultureListProvider(query));
    final networkMode = ref.watch(networkStatusControllerProvider).mode;

    return EmiScaffold(
      title: 'Budaya Mekongga',
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _page = 1;
            _items = [];
            _loadedPages.clear();
            _hasNextPage = false;
          });
          ref.invalidate(cultureListProvider(query));
        },
        child: page.when(
          loading: () => _items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _CultureList(
                  items: _items,
                  hasNextPage: _hasNextPage,
                  loadingMore: _loadingMore,
                  onLoadMore: _loadMore,
                ),
          error: (error, _) => _items.isEmpty
              ? _CultureError(
                  onRetry: () => ref.invalidate(cultureListProvider(query)),
                )
              : _CultureList(
                  items: _items,
                  hasNextPage: _hasNextPage,
                  loadingMore: _loadingMore,
                  onLoadMore: _loadMore,
                  error: error.toString(),
                ),
          data: (data) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _loadedPages.contains(data.currentPage)) return;
              final byId = <String, CultureItem>{
                if (data.currentPage != 1)
                  for (final item in _items) item.id: item,
                for (final item in data.items) item.id: item,
              };
              setState(() {
                _items = byId.values.toList();
                _loadedPages.add(data.currentPage);
                _hasNextPage = data.hasNextPage;
                _loadingMore = false;
              });
            });
            final visibleItems = _page == 1 ? data.items : _items;
            return _CultureList(
              items: visibleItems,
              hasNextPage: data.hasNextPage,
              loadingMore: _loadingMore,
              onLoadMore: _loadMore,
            );
          },
        ),
      ),
    );
  }

  void _loadMore() {
    if (_loadingMore || !_hasNextPage) return;
    setState(() {
      _loadingMore = true;
      _page += 1;
    });
  }
}

class _CultureList extends StatelessWidget {
  const _CultureList({
    required this.items,
    required this.hasNextPage,
    required this.loadingMore,
    required this.onLoadMore,
    this.error,
  });

  final List<CultureItem> items;
  final bool hasNextPage;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          const StudentPageHeader(
            icon: Icons.public_outlined,
            title: 'Budaya Mekongga',
            subtitle: 'Jelajahi kekayaan budaya Mekongga.',
          ),
          const SizedBox(height: EmiSpacing.md),
          StudentPlaceholder(
            icon: Icons.public_off_outlined,
            title: 'Belum Ada Budaya',
            message: 'Materi budaya untuk kelasmu belum tersedia.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(EmiSpacing.md),
      itemCount: items.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: EmiSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const StudentPageHeader(
            icon: Icons.public_outlined,
            title: 'Budaya Mekongga',
            subtitle: 'Jelajahi kekayaan budaya Mekongga.',
          );
        }
        if (index == items.length + 1) {
          return Column(
            children: [
              if (error != null)
                StudentPlaceholder(
                  icon: Icons.cloud_off_outlined,
                  title: 'Sebagian Belum Dimuat',
                  message: 'Beberapa materi belum bisa dimuat.',
                ),
              if (hasNextPage)
                OutlinedButton.icon(
                  onPressed: loadingMore ? null : onLoadMore,
                  icon: loadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: const Text('Muat lagi'),
                ),
            ],
          );
        }
        final item = items[index - 1];
        return _CultureCard(
          item: item,
          onTap: () => context.push('/student/culture/${item.id}', extra: item),
        );
      },
    );
  }
}

class _CultureCard extends StatelessWidget {
  const _CultureCard({required this.item, required this.onTap});

  final CultureItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StudentCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: StudentStyle.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(item.contentType),
                  color: EmiColors.primary,
                ),
              ),
              const SizedBox(width: EmiSpacing.sm),
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
                ),
              ),
              StudentStatusChip(label: _typeLabel(item.contentType)),
            ],
          ),
          const SizedBox(height: EmiSpacing.sm),
          Text(
            item.description ?? 'Deskripsi budaya belum tersedia.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: StudentStyle.inkMuted),
          ),
          const SizedBox(height: EmiSpacing.sm),
          Text(
            'Kelas: ${item.schoolClass?.name ?? item.classId}',
            style: const TextStyle(color: StudentStyle.inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(String type) => switch (type) {
  'image' => Icons.image_outlined,
  'audio' => Icons.audiotrack_outlined,
  'video' || 'youtube' => Icons.play_circle_outline,
  'pdf' => Icons.picture_as_pdf_outlined,
  'article' => Icons.article_outlined,
  _ => Icons.link_outlined,
};

String _typeLabel(String type) => switch (type) {
  'image' => 'Gambar',
  'audio' => 'Audio',
  'video' => 'Video',
  'youtube' => 'YouTube',
  'pdf' => 'PDF',
  'article' => 'Artikel',
  _ => 'Tautan',
};

class _CultureError extends StatelessWidget {
  const _CultureError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        StudentPlaceholder(
          icon: Icons.cloud_off_outlined,
          title: 'Budaya Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}
