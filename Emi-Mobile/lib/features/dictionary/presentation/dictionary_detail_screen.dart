import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/emi_scaffold.dart';
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
          message: error.toString(),
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
    return EmiCard(
      elevated: true,
      padding: const EdgeInsets.all(EmiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: EmiColors.primary,
                borderRadius: BorderRadius.circular(EmiRadii.pill),
              ),
              child: Text(entry.category!.name),
            ),
          const SizedBox(height: EmiSpacing.md),
          Text(
            entry.mekongga,
            style: Theme.of(context).textTheme.headlineMedium,
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
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: Text(value)),
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
        color: const Color(0xFF81D4FA),
        border: Border.all(color: EmiColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(EmiRadii.card),
        boxShadow: const [EmiShadows.hard],
      ),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing == true;
              return IconButton.filled(
                onPressed: _loading ? null : () => _toggle(playing),
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
          const SizedBox(width: EmiSpacing.md),
          Expanded(
            child: Text(
              _error ?? 'Putar pelafalan',
              style: Theme.of(context).textTheme.titleMedium,
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

    return Container(
      padding: const EdgeInsets.all(EmiSpacing.lg),
      decoration: BoxDecoration(
        color: EmiColors.secondary,
        border: Border.all(color: EmiColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(EmiRadii.card),
        boxShadow: const [EmiShadows.hard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contoh Kalimat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: EmiSpacing.md),
          ...examples.map(
            (example) => Padding(
              padding: const EdgeInsets.only(bottom: EmiSpacing.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EmiSpacing.md),
                decoration: BoxDecoration(
                  color: EmiColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (example.mekongga != null)
                      Text(
                        example.mekongga!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    if (example.indonesia != null) Text(example.indonesia!),
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
