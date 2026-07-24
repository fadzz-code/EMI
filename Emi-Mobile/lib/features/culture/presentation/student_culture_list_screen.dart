import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
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
                  message: error.toString(),
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
        children: const [
          EmiCard(child: Text('Belum ada Budaya Mekongga untuk kelas Anda.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(EmiSpacing.md),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: EmiSpacing.md),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Column(
            children: [
              if (error != null) EmiCard(child: Text(error!)),
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
        final item = items[index];
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EmiRadii.card),
      child: EmiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _CultureTypeChip(type: item.contentType),
              ],
            ),
            const SizedBox(height: EmiSpacing.sm),
            Text(
              item.description ?? 'Deskripsi budaya belum tersedia.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: EmiSpacing.sm),
            Text('Kelas: ${item.schoolClass?.name ?? item.classId}'),
          ],
        ),
      ),
    );
  }
}

class _CultureError extends StatelessWidget {
  const _CultureError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        EmiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: EmiSpacing.sm),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CultureTypeChip extends StatelessWidget {
  const _CultureTypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: EmiColors.secondary,
        borderRadius: BorderRadius.circular(EmiRadii.pill),
      ),
      child: Text(type),
    );
  }
}
