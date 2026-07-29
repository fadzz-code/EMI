import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../core/errors/app_error.dart';
import '../../../shared/widgets/emi_card.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/admin_knowledge_providers.dart';
import '../data/admin_knowledge_repository.dart';
import 'admin_shell.dart';

typedef AdminKnowledgePdfPicker = Future<PlatformFile?> Function();

final adminKnowledgePdfPickerProvider = Provider<AdminKnowledgePdfPicker>(
  (_) => () async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    return result?.files.single;
  },
);

class AdminKnowledgeScreen extends ConsumerStatefulWidget {
  const AdminKnowledgeScreen({super.key});

  @override
  ConsumerState<AdminKnowledgeScreen> createState() =>
      _AdminKnowledgeScreenState();
}

class _AdminKnowledgeScreenState extends ConsumerState<AdminKnowledgeScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(adminKnowledgeSummaryProvider);
    final page = ref.watch(adminKnowledgeProvider);
    final query = ref.read(adminKnowledgeProvider.notifier).query;
    return AdminShell(
      title: 'Pengetahuan Basis AI',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminKnowledgeSummaryProvider);
          await ref.read(adminKnowledgeProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            const Text(
              'Kelola informasi yang dapat digunakan chatbot EMI untuk membantu menjawab pertanyaan pengguna.',
            ),
            const SizedBox(height: EmiSpacing.md),
            summary.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Data belum bisa dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
              ),
              data: (data) => Wrap(
                spacing: EmiSpacing.md,
                runSpacing: EmiSpacing.sm,
                children: [
                  _StatText('Total', data.total),
                  _StatText('Draft', data.draft),
                  _StatText('Terbit', data.published),
                  _StatText('Arsip', data.archived),
                ],
              ),
            ),
            const SizedBox(height: EmiSpacing.md),
            FilledButton.icon(
              key: const Key('adminAdd-knowledge'),
              onPressed: () => context.push('/admin/knowledge/create'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Pengetahuan'),
            ),
            const SizedBox(height: EmiSpacing.md),
            TextField(
              key: const Key('adminSearch-knowledge'),
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Cari judul atau isi pengetahuan',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Filter',
                  onPressed: () => _showFilter(
                    context,
                    query,
                    page.valueOrNull?.items ?? const [],
                  ),
                  icon: Badge(
                    isLabelVisible:
                        query.category != null ||
                        query.sourceType != null ||
                        query.status != null,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  ref.read(adminKnowledgeProvider.notifier).search(value);
                });
              },
            ),
            if (query.category != null ||
                query.sourceType != null ||
                query.status != null) ...[
              const SizedBox(height: EmiSpacing.sm),
              Wrap(
                spacing: EmiSpacing.xs,
                children: [
                  if (query.category != null)
                    Chip(label: Text(query.category!)),
                  if (query.sourceType != null)
                    Chip(label: Text(_sourceLabel(query.sourceType!))),
                  if (query.status != null)
                    Chip(label: Text(_statusLabel(query.status!))),
                ],
              ),
            ],
            const SizedBox(height: EmiSpacing.md),
            page.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.wifi_off_outlined,
                title: 'Data belum bisa dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                onRetry: () => ref.invalidate(adminKnowledgeProvider),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  final hasSearch =
                      _search.text.trim().isNotEmpty ||
                      query.category != null ||
                      query.sourceType != null ||
                      query.status != null;
                  return FriendlyState(
                    key: const Key('adminEmpty-knowledge'),
                    icon: Icons.psychology_alt_outlined,
                    title: hasSearch
                        ? 'Pengetahuan Tidak Ditemukan'
                        : 'Belum Ada Pengetahuan',
                    message: hasSearch
                        ? 'Coba gunakan judul, kategori, atau filter yang berbeda.'
                        : 'Tambahkan informasi agar chatbot EMI dapat memberikan jawaban yang lebih tepat.',
                  );
                }
                return Column(
                  children: [
                    for (final item in data.items) ...[
                      _KnowledgeTile(
                        key: Key('adminKnowledgeRow-${item.id}'),
                        item: item,
                      ),
                      const SizedBox(height: EmiSpacing.sm),
                    ],
                    if (data.hasMore)
                      FilledButton(
                        onPressed: () => ref
                            .read(adminKnowledgeProvider.notifier)
                            .loadMore(),
                        child: const Text('Muat Lagi'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilter(
    BuildContext context,
    AdminKnowledgeQuery query,
    List<AdminKnowledgeItem> items,
  ) async {
    String? category = query.category;
    String? sourceType = query.sourceType;
    String? status = query.status;
    final categories =
        items
            .map((item) => item.category)
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(EmiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: EmiSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Kategori'),
                  ),
                  for (final item in categories)
                    DropdownMenuItem(value: item, child: Text(item)),
                ],
                onChanged: (value) => setSheetState(() => category = value),
              ),
              const SizedBox(height: EmiSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: sourceType,
                decoration: const InputDecoration(labelText: 'Jenis Sumber'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'manual', child: Text('Teks Manual')),
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'link', child: Text('Tautan')),
                ],
                onChanged: (value) => setSheetState(() => sourceType = value),
              ),
              const SizedBox(height: EmiSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'published', child: Text('Terbit')),
                  DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                ],
                onChanged: (value) => setSheetState(() => status = value),
              ),
              const SizedBox(height: EmiSpacing.lg),
              FilledButton(
                onPressed: () {
                  ref
                      .read(adminKnowledgeProvider.notifier)
                      .filter(
                        category: category,
                        sourceType: sourceType,
                        status: status,
                      );
                  Navigator.pop(context);
                },
                child: const Text('Terapkan'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(adminKnowledgeProvider.notifier).filter();
                  Navigator.pop(context);
                },
                child: const Text('Hapus Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowledgeTile extends StatelessWidget {
  const _KnowledgeTile({super.key, required this.item});

  final AdminKnowledgeItem item;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/admin/knowledge/${item.id}'),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(
        horizontal: EmiSpacing.md,
        vertical: EmiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: EmiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmiColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: EmiSpacing.xs),
                Text(
                  item.category.isEmpty ? 'Umum' : item.category,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: EmiSpacing.xs),
                Text(
                  '${_sourceLabel(item.sourceType)} • ${_statusLabel(item.status)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Diubah ${_shortDate(item.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: EmiSpacing.sm),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Tindakan',
            onSelected: (value) {
              if (value == 'edit') {
                context.push('/admin/knowledge/${item.id}/edit');
              } else if (value == 'publish') {
                _confirmPublish(context, item);
              } else if (value == 'archive') {
                _confirmArchive(context, item);
              } else if (value == 'delete') {
                _confirmDelete(context, item);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (item.status != 'published')
                PopupMenuItem(
                  value: 'publish',
                  enabled: _canPublish(item),
                  child: const Text('Terbitkan'),
                ),
              if (item.status != 'archived')
                const PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus', style: TextStyle(color: EmiColors.error)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StatText extends StatelessWidget {
  const _StatText(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$value',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(width: EmiSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

class AdminKnowledgeDetailScreen extends ConsumerWidget {
  const AdminKnowledgeDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminKnowledgeDetailProvider(id));
    return AdminShell(
      title: 'Detail Pengetahuan',
      fallbackRoute: '/admin/knowledge',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => FriendlyState(
          icon: Icons.wifi_off_outlined,
          title: 'Data belum bisa dimuat',
          message: 'Periksa koneksi internet, lalu coba lagi.',
          onRetry: () => ref.invalidate(adminKnowledgeDetailProvider(id)),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(EmiSpacing.md),
          children: [
            _InfoSection(
              title: 'Identitas Pengetahuan',
              rows: {'Judul': item.title, 'Kategori': item.category},
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Konten Pengetahuan',
              rows: {
                'Konten': item.content.isEmpty
                    ? 'Konten disiapkan dari dokumen.'
                    : item.content,
              },
            ),
            const SizedBox(height: EmiSpacing.md),
            _InfoSection(
              title: 'Sumber dan Status',
              rows: {
                'Jenis Sumber': _sourceLabel(item.sourceType),
                'Status': _statusLabel(item.status),
                'URL Sumber': item.sourceUrl ?? '-',
              },
            ),
            if (item.sourceType == 'pdf') ...[
              const SizedBox(height: EmiSpacing.md),
              _InfoSection(
                title: 'Informasi Dokumen',
                rows: {
                  'Status Dokumen': _documentStatus(item),
                  'Dokumen': item.sourceUrl ?? 'PDF tersimpan',
                },
              ),
            ],
            const SizedBox(height: EmiSpacing.md),
            FilledButton(
              key: const Key('adminEdit-knowledge'),
              onPressed: () => context.push('/admin/knowledge/${item.id}/edit'),
              child: const Text('Edit Pengetahuan'),
            ),
            const SizedBox(height: EmiSpacing.sm),
            Wrap(
              spacing: EmiSpacing.xs,
              children: [
                if (item.status != 'published')
                  OutlinedButton(
                    key: const Key('adminPublish-knowledge'),
                    onPressed: () => _confirmPublish(context, item),
                    child: const Text('Terbitkan'),
                  ),
                if (item.status != 'archived')
                  OutlinedButton(
                    key: const Key('adminArchive-knowledge'),
                    onPressed: () => _confirmArchive(context, item),
                    child: const Text('Arsipkan'),
                  ),
                if (item.sourceType == 'pdf' &&
                    item.processingStatus == 'failed')
                  OutlinedButton(
                    key: const Key('adminRetry-knowledge'),
                    onPressed: () => _retry(context, item),
                    child: const Text('Coba Proses Lagi'),
                  ),
                OutlinedButton(
                  key: const Key('adminDelete-knowledge'),
                  onPressed: () => _confirmDelete(context, item),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminKnowledgeFormScreen extends ConsumerStatefulWidget {
  const AdminKnowledgeFormScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<AdminKnowledgeFormScreen> createState() =>
      _AdminKnowledgeFormScreenState();
}

class _AdminKnowledgeFormScreenState
    extends ConsumerState<AdminKnowledgeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _content = TextEditingController();
  final _url = TextEditingController();
  String _sourceType = 'manual';
  String _status = 'draft';
  String _pdfMode = 'upload';
  PlatformFile? _pdf;
  AdminKnowledgeSourcePreview? _preview;
  bool _checking = false;
  bool _saving = false;
  bool _filled = false;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _content.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.id == null
        ? null
        : ref.watch(adminKnowledgeDetailProvider(widget.id!));
    return Semantics(
      key: const Key('adminScreen-knowledge-form'),
      child: AdminShell(
        title: widget.id == null
            ? 'Tambah Pengetahuan'
            : 'Edit Pengetahuan Basis AI',
        fallbackRoute: widget.id == null
            ? '/admin/knowledge'
            : '/admin/knowledge/${widget.id}',
        child: widget.id == null
            ? _form(null)
            : detail!.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const FriendlyState(
                  icon: Icons.wifi_off_outlined,
                  title: 'Data belum bisa dimuat',
                  message: 'Periksa koneksi internet, lalu coba lagi.',
                ),
                data: (item) => _form(item),
              ),
      ),
    );
  }

  Widget _form(AdminKnowledgeItem? item) {
    if (item != null && !_filled) {
      _title.text = item.title;
      _category.text = item.category;
      _content.text = item.content;
      _url.text = item.sourceUrl ?? '';
      _sourceType = item.sourceType;
      _status = item.status;
      if (_sourceType == 'pdf') {
        final url = item.sourceUrl ?? '';
        _pdfMode = url.contains('/storage/') ? 'upload' : 'url';
      }
      _filled = true;
    }
    return PopScope(
      canPop: !_changed(item),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave(context);
        if (!mounted || leave != true) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(
            widget.id == null
                ? '/admin/knowledge'
                : '/admin/knowledge/${widget.id}',
          );
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.id == null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: EmiSpacing.xl),
                    child: Text(
                      'Tambahkan informasi yang dapat membantu chatbot EMI menjawab pertanyaan dengan lebih tepat.',
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: EmiSpacing.xl),
                    child: Text(
                      'Perbarui informasi tanpa mengubah sumber yang tidak diperlukan.',
                    ),
                  ),
                _SectionTitle(
                  'Identitas Pengetahuan',
                  'Judul dan kategori membantu Admin menemukan sumber saat mengelola Basis AI.',
                ),
                TextFormField(
                  key: const Key('adminField-knowledge-title'),
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    hintText: 'Contoh: Asal-usul Mekongga',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Judul wajib diisi.'
                      : null,
                ),
                const SizedBox(height: EmiSpacing.md),
                TextFormField(
                  key: const Key('adminField-knowledge-category'),
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                const SizedBox(height: EmiSpacing.lg),
                _SectionTitle(
                  'Konten Pengetahuan',
                  'Agar chatbot menjawab lebih tepat, buat pengetahuan secara spesifik.\nContoh:\n“Asal-usul Mekongga”\n“Arti nama Mekongga”\n“Kosakata dasar Mekongga”',
                ),
                if (_sourceType != 'pdf')
                  TextFormField(
                    key: const Key('adminField-knowledge-content'),
                    controller: _content,
                    minLines: 6,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      labelText: 'Konten Pengetahuan',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Konten pengetahuan wajib diisi.'
                        : null,
                  ),
                const SizedBox(height: EmiSpacing.lg),
                _SectionTitle(
                  'Sumber dan Status',
                  'Draft belum digunakan chatbot.\nTerbit dapat digunakan chatbot siswa.\nArsip tetap tersimpan, tetapi tidak digunakan chatbot.',
                ),
                DropdownButtonFormField<String>(
                  initialValue: _sourceType,
                  decoration: const InputDecoration(labelText: 'Jenis Sumber'),
                  items: const [
                    DropdownMenuItem(
                      value: 'manual',
                      child: Text('Teks Manual'),
                    ),
                    DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem(value: 'link', child: Text('Tautan')),
                  ],
                  onChanged: _saving || item != null
                      ? null
                      : (value) => setState(() {
                          _sourceType = value ?? 'manual';
                          _preview = null;
                        }),
                ),
                const SizedBox(height: EmiSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'published', child: Text('Terbit')),
                    DropdownMenuItem(value: 'archived', child: Text('Arsip')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _status = value ?? 'draft'),
                ),
                if (_sourceType == 'link') ...[
                  const SizedBox(height: EmiSpacing.md),
                  TextFormField(
                    controller: _url,
                    decoration: const InputDecoration(
                      labelText: 'Tautan Sumber',
                      hintText: 'https://sumber-resmi.id/artikel',
                      helperText:
                          'Gunakan tautan sumber resmi yang dapat dibuka tanpa login.',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Tautan wajib diisi.'
                        : null,
                  ),
                ],
                if (_sourceType == 'pdf') ...[
                  const SizedBox(height: EmiSpacing.md),
                  const Text(
                    'Cara Menambahkan PDF',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: EmiSpacing.sm),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'upload', label: Text('Unggah PDF')),
                      ButtonSegment(
                        value: 'url',
                        label: Text('Gunakan Tautan PDF'),
                      ),
                    ],
                    selected: {_pdfMode},
                    onSelectionChanged: (set) {
                      setState(() {
                        _pdfMode = set.first;
                        _pdf = null;
                        _url.clear();
                        _preview = null;
                      });
                    },
                  ),
                  const SizedBox(height: EmiSpacing.md),
                  if (_pdfMode == 'url') ...[
                    TextFormField(
                      controller: _url,
                      onChanged: (_) => setState(() => _preview = null),
                      decoration: const InputDecoration(
                        labelText: 'Tautan PDF Publik',
                        hintText: 'https://contoh-sumber-resmi.id/dokumen.pdf',
                        helperText:
                            'Gunakan tautan PDF yang dapat dibuka tanpa login.',
                      ),
                    ),
                    const SizedBox(height: EmiSpacing.sm),
                    OutlinedButton.icon(
                      onPressed:
                          _saving || _checking || _url.text.trim().isEmpty
                          ? null
                          : _checkPdfUrl,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(
                        _checking ? 'Memeriksa...' : 'Periksa Tautan',
                      ),
                    ),
                    if (_preview != null)
                      Padding(
                        padding: const EdgeInsets.only(top: EmiSpacing.sm),
                        child: EmiCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PDF Ditemukan',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Text('PDF Siap Disimpan'),
                              Text(
                                'Nama dokumen: ${_preview!.title.isEmpty ? 'Dokumen PDF' : _preview!.title}',
                              ),
                              Text(
                                'Ukuran teks: ${_preview!.characterCount} karakter',
                              ),
                            ],
                          ),
                        ),
                      ),
                  ] else ...[
                    EmiCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_pdf == null &&
                              (item == null ||
                                  item.sourceType != 'pdf' ||
                                  item.sourceUrl == null ||
                                  !item.sourceUrl!.contains('/storage/'))) ...[
                            const Text(
                              'Belum Ada PDF Dipilih',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: EmiSpacing.xs),
                            const Text(
                              'Pilih dokumen PDF yang berisi pengetahuan yang ingin digunakan.',
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            FilledButton.icon(
                              key: const Key('adminPickPdf-knowledge'),
                              onPressed: _saving ? null : _pickPdf,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Pilih PDF'),
                            ),
                          ] else if (_pdf == null &&
                              item != null &&
                              item.sourceUrl != null) ...[
                            const Text(
                              'PDF Saat Ini',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(item.sourceUrl!.split('/').last),
                            const SizedBox(height: EmiSpacing.md),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: _saving ? null : _pickPdf,
                                  child: const Text('Ganti PDF'),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              _pdf!.name,
                              key: const Key('adminPdfFilename-knowledge'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_pdf!.size} byte',
                              key: const Key('adminPdfStatus-knowledge'),
                            ),
                            const SizedBox(height: EmiSpacing.md),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: _saving ? null : _pickPdf,
                                  child: const Text('Ganti'),
                                ),
                                const SizedBox(width: EmiSpacing.sm),
                                TextButton(
                                  onPressed: () => setState(() => _pdf = null),
                                  child: const Text('Hapus Pilihan'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: EmiSpacing.lg),
                FilledButton(
                  key: const Key('adminSave-knowledge'),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Menyimpan...' : 'Simpan Pengetahuan'),
                ),
                TextButton(
                  onPressed: _saving ? null : () => context.pop(),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _changed(AdminKnowledgeItem? item) =>
      _title.text != (item?.title ?? '') ||
      _category.text != (item?.category ?? '') ||
      _content.text != (item?.content ?? '') ||
      _url.text != (item?.sourceUrl ?? '') ||
      _pdf != null;

  Future<void> _checkPdfUrl() async {
    setState(() => _checking = true);
    try {
      final preview = await ref
          .read(adminKnowledgeRepositoryProvider)
          .previewSource(sourceType: 'pdf', sourceUrl: _url.text.trim());
      if (!mounted) return;
      setState(() {
        _preview = preview;
        if (_title.text.trim().isEmpty && preview.title.isNotEmpty) {
          _title.text = preview.title;
        }
        if (_content.text.trim().isEmpty) {
          _content.text = preview.content;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan PDF belum dapat digunakan.')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _pickPdf() async {
    final file = await ref.read(adminKnowledgePdfPickerProvider)();
    if (file == null) return;
    setState(() => _pdf = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceType == 'pdf' && _pdf == null && _url.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih file PDF atau gunakan tautan PDF terlebih dahulu.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final sourceUrl = _sourceType == 'manual'
          ? null
          : _url.text.trim().isEmpty
          ? null
          : _url.text.trim();
      final saved = await ref
          .read(adminKnowledgeRepositoryProvider)
          .save(
            id: widget.id,
            request: AdminKnowledgeSaveRequest(
              title: _title.text.trim(),
              category: _category.text.trim().isEmpty
                  ? 'Umum'
                  : _category.text.trim(),
              content: _sourceType == 'pdf'
                  ? (_content.text.trim().isEmpty
                        ? 'Dokumen PDF'
                        : _content.text.trim())
                  : _content.text.trim(),
              sourceType: _sourceType,
              sourceUrl: sourceUrl,
              status: _status,
              pdfPath: _sourceType == 'pdf' ? _pdf?.path : null,
              pdfName: _sourceType == 'pdf' ? _pdf?.name : null,
            ),
          );
      _invalidate(saved.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _status == 'published'
                ? 'Pengetahuan berhasil diterbitkan.'
                : 'Pengetahuan berhasil disimpan.',
          ),
        ),
      );
      context.go('/admin/knowledge/${saved.id}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengetahuan belum dapat diproses saat ini.'),
        ),
      );
      setState(() => _saving = false);
    }
  }

  void _invalidate(String id) {
    ref.invalidate(adminKnowledgeProvider);
    ref.invalidate(adminKnowledgeSummaryProvider);
    ref.invalidate(adminKnowledgeDetailProvider(id));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.helper);

  final String title;
  final String helper;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: EmiSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: EmiSpacing.xl),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EmiSpacing.xs),
        Text(helper, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) => EmiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EmiSpacing.sm),
        for (final row in rows.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: EmiSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.key, style: Theme.of(context).textTheme.labelMedium),
                Text(row.value.isEmpty ? '-' : row.value),
              ],
            ),
          ),
      ],
    ),
  );
}

Future<bool?> _confirmLeave(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Batalkan perubahan?'),
    content: const Text('Perubahan yang belum disimpan akan hilang.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Tetap di Halaman'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Keluar'),
      ),
    ],
  ),
);

bool _canPublish(AdminKnowledgeItem item) =>
    item.sourceType == 'manual' || item.processingStatus == 'ready';

Future<void> _confirmPublish(
  BuildContext context,
  AdminKnowledgeItem item,
) async {
  if (!_canPublish(item)) {
    final failed = item.processingStatus == 'failed';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengetahuan Belum Siap Diterbitkan'),
        content: Text(
          failed
              ? 'PDF belum berhasil disiapkan. Coba proses kembali sebelum menerbitkan.'
              : 'PDF masih sedang disiapkan. Terbitkan setelah dokumen siap digunakan.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Terbitkan pengetahuan ini?'),
      content: const Text(
        'Pengetahuan dapat digunakan chatbot EMI setelah diterbitkan dan sumbernya siap.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Terbitkan'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await _runAction(
      context,
      item.id,
      (repo) => repo.publish(item.id),
      'Pengetahuan berhasil diterbitkan.',
    );
  }
}

Future<void> _confirmArchive(
  BuildContext context,
  AdminKnowledgeItem item,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Arsipkan pengetahuan ini?'),
      content: const Text(
        'Pengetahuan tetap tersimpan, tetapi tidak digunakan chatbot.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Arsipkan'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await _runAction(
      context,
      item.id,
      (repo) => repo.archive(item.id),
      'Pengetahuan berhasil diarsipkan.',
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  AdminKnowledgeItem item,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus pengetahuan ini?'),
      content: const Text(
        'Pengetahuan tidak lagi tampil pada daftar aktif, tetapi datanya tetap disimpan oleh sistem.',
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
  if (ok != true || !context.mounted) return;
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await container.read(adminKnowledgeRepositoryProvider).delete(item.id);
    container.invalidate(adminKnowledgeProvider);
    container.invalidate(adminKnowledgeSummaryProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengetahuan berhasil dihapus.')),
    );
    context.go('/admin/knowledge');
  } catch (error) {
    if (context.mounted) {
      final message = error is AppError && error.type == AppErrorType.conflict
          ? 'Pengetahuan Belum Siap Diterbitkan'
          : 'Pengetahuan belum dapat diproses saat ini.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

Future<void> _retry(BuildContext context, AdminKnowledgeItem item) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Siapkan ulang PDF ini?'),
      content: const Text(
        'Sistem akan mencoba membaca kembali dokumen yang sebelumnya gagal.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Coba Proses Lagi'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await _runAction(
      context,
      item.id,
      (repo) => repo.retry(item.id),
      'PDF sedang disiapkan kembali.',
    );
  }
}

Future<void> _runAction(
  BuildContext context,
  String id,
  Future<AdminKnowledgeItem> Function(AdminKnowledgeRepository repo) action,
  String message,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    final saved = await action(
      container.read(adminKnowledgeRepositoryProvider),
    );
    container.invalidate(adminKnowledgeProvider);
    container.invalidate(adminKnowledgeSummaryProvider);
    container.invalidate(adminKnowledgeDetailProvider(id));
    container.invalidate(adminKnowledgeDetailProvider(saved.id));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  } catch (error) {
    if (context.mounted) {
      final message = error is AppError && error.type == AppErrorType.conflict
          ? 'Pengetahuan Belum Siap Diterbitkan'
          : 'Pengetahuan belum dapat diproses saat ini.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

String _sourceLabel(String value) => switch (value) {
  'manual' => 'Teks Manual',
  'pdf' => 'PDF',
  'link' => 'Tautan',
  _ => 'Teks Manual',
};
String _statusLabel(String value) => switch (value) {
  'draft' => 'Draft',
  'published' => 'Terbit',
  'archived' => 'Arsip',
  _ => 'Draft',
};
String _documentStatus(AdminKnowledgeItem item) =>
    switch (item.processingStatus) {
      'queued' => 'Menunggu Disiapkan',
      'processing' => 'PDF Sedang Disiapkan',
      'ready' => 'Pengetahuan Siap Digunakan',
      'failed' => 'PDF Belum Berhasil Disiapkan',
      _ => 'PDF Sedang Disiapkan',
    };
String _shortDate(String? value) =>
    value == null || value.length < 10 ? '-' : value.substring(0, 10);
