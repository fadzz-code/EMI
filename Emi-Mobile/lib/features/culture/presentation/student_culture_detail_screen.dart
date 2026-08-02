import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
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
          children: [
            StudentPlaceholder(
              icon: Icons.cloud_off_outlined,
              title: 'Budaya Belum Bisa Dimuat',
              message: 'Periksa koneksi internetmu, lalu coba lagi.',
              onRetry: () => ref.invalidate(_cultureDetailFallbackProvider),
            ),
          ],
        ),
        data: (data) {
          final found = data.items.where((item) => item.id == cultureId);
          if (found.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(EmiSpacing.md),
              children: [
                StudentPlaceholder(
                  icon: Icons.search_off_outlined,
                  title: 'Budaya Tidak Ditemukan',
                  message: 'Materi budaya ini tidak tersedia.',
                ),
              ],
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
        StudentPageHeader(
          icon: _iconFor(item.contentType),
          title: item.title,
          subtitle: 'Kelas: ${item.schoolClass?.name ?? item.classId}',
        ),
        const SizedBox(height: EmiSpacing.md),
        StudentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentStatusChip(label: _typeLabel(item.contentType)),
              const SizedBox(height: EmiSpacing.sm),
              Text(
                item.description ?? 'Deskripsi budaya belum tersedia.',
                style: const TextStyle(color: StudentStyle.ink, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: EmiSpacing.md),
        _CultureMediaCard(item: item),
        const SizedBox(height: EmiSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/student/culture'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali'),
          ),
        ),
      ],
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EmiSpacing.md),
        decoration: BoxDecoration(
          color: StudentStyle.tint,
          borderRadius: BorderRadius.circular(EmiRadii.card),
        ),
        child: const Text(
          'Konten belum tersedia.',
          style: TextStyle(color: StudentStyle.inkMuted),
        ),
      );
    }
    if (item.contentType == 'image') {
      return FutureBuilder<String>(
        future: _url(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data?.isNotEmpty != true) {
            return StudentPlaceholder(
              icon: Icons.broken_image_outlined,
              title: 'Gambar Belum Bisa Dimuat',
              message: 'Periksa koneksi internetmu, lalu coba lagi.',
              onRetry: () => setState(() {}),
            );
          }
          return StudentCard(
            padding: EdgeInsets.zero,
            clip: true,
            child: Image.network(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(EmiSpacing.md),
                child: Text(
                  'Gambar gagal dimuat.',
                  style: TextStyle(color: StudentStyle.inkMuted),
                ),
              ),
            ),
          );
        },
      );
    }
    if (item.contentType == 'audio') {
      return StudentCard(
        child: StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, snapshot) => Row(
            children: [
              IconButton.filled(
                onPressed: _loading
                    ? null
                    : () => _toggleAudio(snapshot.data?.playing == true),
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
                    : Icon(
                        snapshot.data?.playing == true
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
              ),
              const SizedBox(width: EmiSpacing.md),
              Expanded(
                child: Text(
                  _error ?? 'Putar audio',
                  style: TextStyle(
                    color: _error != null ? EmiColors.error : StudentStyle.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return StudentCard(
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _loading ? null : _openExternal,
          icon: Icon(
            item.contentType == 'pdf'
                ? Icons.picture_as_pdf
                : Icons.open_in_new,
          ),
          label: Text(
            item.contentType == 'video'
                ? 'Putar video'
                : item.contentType == 'pdf'
                ? 'Buka PDF'
                : 'Buka tautan',
          ),
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
