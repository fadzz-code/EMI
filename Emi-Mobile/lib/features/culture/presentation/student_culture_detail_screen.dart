import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../data/culture_models.dart';
import '../data/culture_providers.dart';

class StudentCultureDetailScreen extends ConsumerWidget {
  const StudentCultureDetailScreen({
    super.key,
    required this.cultureId,
    this.item,
  });

  final String cultureId;
  final CultureItem? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providedItem = item;
    if (providedItem != null) {
      return EmiScaffold(
        title: 'Detail Budaya',
        child: _CultureDetail(item: providedItem),
      );
    }

    final page = ref.watch(_cultureDetailFallbackProvider);
    return EmiScaffold(
      title: 'Detail Budaya',
      child: page.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [EmiCard(child: Text(error.toString()))],
        ),
        data: (data) {
          final found = data.items.where((item) => item.id == cultureId);
          if (found.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: const [EmiCard(child: Text('Budaya tidak ditemukan.'))],
            );
          }
          return _CultureDetail(item: found.first);
        },
      ),
    );
  }
}

final _cultureDetailFallbackProvider = FutureProvider.autoDispose<CulturePage>((
  ref,
) {
  return ref.watch(cultureRepositoryProvider).list(perPage: 100);
});

class _CultureDetail extends StatelessWidget {
  const _CultureDetail({required this.item});

  final CultureItem item;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        EmiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: EmiSpacing.sm),
              Text('Kelas: ${item.schoolClass?.name ?? item.classId}'),
              const SizedBox(height: EmiSpacing.sm),
              Text('Tipe: ${item.contentType}'),
            ],
          ),
        ),
        const SizedBox(height: EmiSpacing.md),
        EmiCard(
          child: Text(item.description ?? 'Deskripsi budaya belum tersedia.'),
        ),
        const SizedBox(height: EmiSpacing.md),
        _CultureMediaCard(item: item),
        const SizedBox(height: EmiSpacing.md),
        OutlinedButton.icon(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/student/culture'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Kembali'),
        ),
      ],
    );
  }
}

class _CultureMediaCard extends StatelessWidget {
  const _CultureMediaCard({required this.item});

  final CultureItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.contentUrl;
    if (url == null || url.isEmpty) {
      return const EmiCard(child: Text('Konten belum memiliki URL publik.'));
    }

    if (item.contentType == 'image') {
      return EmiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(EmiRadii.card),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Text('Gambar gagal dimuat.'),
              ),
            ),
            const SizedBox(height: EmiSpacing.sm),
            SelectableText(url),
          ],
        ),
      );
    }

    return EmiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_openLabel(item.contentType)),
          const SizedBox(height: EmiSpacing.sm),
          SelectableText(url),
        ],
      ),
    );
  }

  String _openLabel(String type) {
    return switch (type) {
      'pdf' => 'Buka PDF di URL berikut:',
      'video' => 'Buka video di URL berikut:',
      'audio' => 'Buka audio di URL berikut:',
      _ => 'Buka konten di URL berikut:',
    };
  }
}
