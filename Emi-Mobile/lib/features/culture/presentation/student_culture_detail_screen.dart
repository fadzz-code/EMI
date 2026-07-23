import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _CultureMediaCard extends ConsumerStatefulWidget {
  const _CultureMediaCard({required this.item});

  final CultureItem item;

  @override
  ConsumerState<_CultureMediaCard> createState() => _CultureMediaCardState();
}

class _CultureMediaCardState extends ConsumerState<_CultureMediaCard> {
  final _player = AudioPlayer();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.contentUrl?.isNotEmpty != true) {
      return const EmiCard(child: Text('Konten belum tersedia.'));
    }
    if (item.contentType == 'image' && item.media?.visibility != 'private') {
      return EmiCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(EmiRadii.card),
          child: Image.network(
            item.contentUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Text('Gambar gagal dimuat.'),
          ),
        ),
      );
    }
    if (item.contentType == 'audio') {
      return EmiCard(
        child: StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, snapshot) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: IconButton.filled(
              onPressed: _loading
                  ? null
                  : () => _toggleAudio(snapshot.data?.playing == true),
              icon: _loading
                  ? const CircularProgressIndicator()
                  : Icon(
                      snapshot.data?.playing == true
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
            ),
            title: Text(_error ?? 'Putar audio'),
          ),
        ),
      );
    }
    return EmiCard(
      child: FilledButton.icon(
        onPressed: _loading ? null : _openExternal,
        icon: Icon(
          item.contentType == 'pdf' ? Icons.picture_as_pdf : Icons.open_in_new,
        ),
        label: Text(
          item.contentType == 'video'
              ? 'Putar video'
              : item.contentType == 'pdf'
              ? 'Buka PDF'
              : 'Buka tautan',
        ),
      ),
    );
  }

  Future<String> _url() =>
      ref.read(cultureRepositoryProvider).playbackUrl(widget.item);

  Future<void> _toggleAudio(bool playing) async {
    if (playing) return _player.pause();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _player.setUrl(await _url());
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _error = 'Audio gagal diputar.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openExternal() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.tryParse(await _url());
      if (uri == null || !{'https', 'http'}.contains(uri.scheme)) {
        throw const FormatException();
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const FormatException();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Konten gagal dibuka.');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Konten gagal dibuka.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
