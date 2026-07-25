import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_scaffold.dart';
import '../../../shared/widgets/student_style.dart';
import '../../../shared/widgets/student_widgets.dart';
import '../data/dictionary_entry.dart';
import '../data/dictionary_providers.dart';

class DictionaryDetailScreen extends ConsumerWidget {
  const DictionaryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(dictionaryDetailProvider(entryId));

    return EmiScaffold(
      title: 'Kamus Mekongga',
      child: entry.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(dictionaryDetailProvider(entryId)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            _HeroCard(entry: data),
            const SizedBox(height: EmiSpacing.md),
            if (data.hasAudio) DictionaryAudioPlayer(audio: data.audio!),
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
    return StudentCard(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.category != null)
            StudentStatusChip(label: entry.category!.name),
          const SizedBox(height: EmiSpacing.md),
          Text(
            entry.mekongga,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: StudentStyle.ink),
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
            ).textTheme.labelLarge?.copyWith(color: StudentStyle.inkMuted),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: StudentStyle.ink)),
        ),
      ],
    );
  }
}

class DictionaryAudioPlayer extends StatefulWidget {
  const DictionaryAudioPlayer({super.key, required this.audio});

  final DictionaryAudio audio;

  @override
  State<DictionaryAudioPlayer> createState() => _DictionaryAudioPlayerState();
}

class _DictionaryAudioPlayerState extends State<DictionaryAudioPlayer> {
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
        color: StudentStyle.tint,
        borderRadius: BorderRadius.circular(StudentStyle.cardRadius),
        boxShadow: StudentStyle.softShadow(),
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing == true;
              return IconButton.filled(
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
                color: _error != null ? EmiColors.error : StudentStyle.ink,
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

    return StudentCard(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: StudentStyle.tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.format_quote_outlined,
                  size: 16,
                  color: EmiColors.primary,
                ),
              ),
              const SizedBox(width: EmiSpacing.xs),
              Text(
                'Contoh Kalimat',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: StudentStyle.ink),
              ),
            ],
          ),
          const SizedBox(height: EmiSpacing.md),
          ...examples.map(
            (example) => Padding(
              padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EmiSpacing.md),
                decoration: BoxDecoration(
                  color: StudentStyle.tint,
                  borderRadius: BorderRadius.circular(EmiRadii.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (example.mekongga != null)
                      Text(
                        example.mekongga!,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: StudentStyle.ink),
                      ),
                    if (example.indonesia != null)
                      Text(
                        example.indonesia!,
                        style: const TextStyle(color: StudentStyle.inkMuted),
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
          title: 'Kata Belum Bisa Dimuat',
          message: 'Periksa koneksi internetmu, lalu coba lagi.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}
