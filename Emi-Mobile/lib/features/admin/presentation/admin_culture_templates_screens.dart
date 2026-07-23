import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/emi_theme.dart';
import '../../../shared/widgets/role_dashboard_widgets.dart';
import '../data/admin_culture_providers.dart';
import '../data/admin_culture_repository.dart';
import '../data/admin_repository.dart';
import '../data/admin_providers.dart';
import 'admin_shell.dart';

final adminCultureTemplatesProvider =
    FutureProvider<List<AdminCultureTemplate>>(
      (ref) => ref.watch(adminCultureRepositoryProvider).templates(),
    );
final adminCultureTemplateProvider =
    FutureProvider.family<AdminCultureTemplate, String>(
      (ref, id) => ref.watch(adminCultureRepositoryProvider).template(id),
    );

class AdminCultureTemplatesScreen extends ConsumerWidget {
  const AdminCultureTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminShell(
    title: 'Template Budaya',
    fallbackRoute: '/admin/culture',
    child: ListView(
      padding: const EdgeInsets.all(EmiSpacing.md),
      children: [
        FilledButton.icon(
          onPressed: () => _editTemplate(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Template'),
        ),
        const SizedBox(height: EmiSpacing.md),
        ref
            .watch(adminCultureTemplatesProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => FriendlyState(
                icon: Icons.error_outline,
                title: 'Template Belum Bisa Dimuat',
                message: 'Silakan coba lagi.',
                onRetry: () => ref.invalidate(adminCultureTemplatesProvider),
              ),
              data: (items) => items.isEmpty
                  ? const FriendlyState(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'Belum Ada Template',
                      message: 'Tambah template untuk diterapkan ke kelas.',
                    )
                  : Column(
                      children: [
                        for (final item in items)
                          ListTile(
                            title: Text(item.title),
                            subtitle: Text(
                              '${item.items.length} item · ${item.status}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '/admin/culture/templates/${item.id}',
                            ),
                          ),
                      ],
                    ),
            ),
      ],
    ),
  );
}

class AdminCultureTemplateDetailScreen extends ConsumerWidget {
  const AdminCultureTemplateDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminShell(
    title: 'Detail Template Budaya',
    fallbackRoute: '/admin/culture/templates',
    child: ref
        .watch(adminCultureTemplateProvider(id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const FriendlyState(
            icon: Icons.error_outline,
            title: 'Template Belum Bisa Dimuat',
            message: 'Silakan coba lagi.',
          ),
          data: (template) => ListView(
            padding: const EdgeInsets.all(EmiSpacing.md),
            children: [
              Text(
                template.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(template.description.isEmpty ? '-' : template.description),
              const SizedBox(height: EmiSpacing.md),
              Wrap(
                spacing: EmiSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: () => _editTemplate(context, ref, template),
                    child: const Text('Edit'),
                  ),
                  if (template.status != 'published')
                    OutlinedButton(
                      onPressed: () => _publish(context, ref, template.id),
                      child: const Text('Terbitkan'),
                    ),
                  if (template.status == 'published')
                    FilledButton(
                      onPressed: () => _apply(context, ref, template.id),
                      child: const Text('Terapkan ke Kelas'),
                    ),
                ],
              ),
              const Divider(),
              FilledButton.icon(
                onPressed: () => _editItem(context, ref, template.id),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item'),
              ),
              for (final item in template.items)
                ListTile(
                  title: Text(item.title),
                  subtitle: Text('${item.contentType} · ${item.status}'),
                  onTap: () => _editItem(context, ref, template.id, item),
                  trailing: IconButton(
                    tooltip: 'Hapus item',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref
                          .read(adminCultureRepositoryProvider)
                          .deleteTemplateItem(item.id);
                      ref.invalidate(adminCultureTemplateProvider(id));
                    },
                  ),
                ),
            ],
          ),
        ),
  );
}

Future<void> _editTemplate(
  BuildContext context,
  WidgetRef ref, [
  AdminCultureTemplate? item,
]) async {
  final title = TextEditingController(text: item?.title);
  final description = TextEditingController(text: item?.description);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(item == null ? 'Tambah Template' : 'Edit Template'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Judul'),
          ),
          TextField(
            controller: description,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, title.text.trim().isNotEmpty),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final saved = await ref
      .read(adminCultureRepositoryProvider)
      .saveTemplate(
        id: item?.id,
        title: title.text.trim(),
        description: description.text.trim(),
      );
  ref.invalidate(adminCultureTemplatesProvider);
  if (context.mounted) context.go('/admin/culture/templates/${saved.id}');
}

Future<void> _editItem(
  BuildContext context,
  WidgetRef ref,
  String templateId, [
  AdminCultureItem? item,
]) async {
  final title = TextEditingController(text: item?.title);
  final description = TextEditingController(text: item?.description);
  final url = TextEditingController(text: item?.externalUrl);
  var type = item?.contentType ?? 'article';
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(item == null ? 'Tambah Item' : 'Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'article', child: Text('Artikel')),
                  DropdownMenuItem(value: 'link', child: Text('Tautan')),
                  DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                ],
                onChanged: (value) => setState(() => type = value ?? 'article'),
              ),
              TextField(
                controller: url,
                decoration: const InputDecoration(labelText: 'URL lengkap'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              title.text.trim().isNotEmpty &&
                  Uri.tryParse(url.text)?.hasScheme == true,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return;
  await ref
      .read(adminCultureRepositoryProvider)
      .saveTemplateItem(
        templateId: templateId,
        id: item?.id,
        request: AdminCultureSaveRequest(
          title: title.text.trim(),
          description: description.text.trim(),
          contentType: type,
          mediaId: null,
          externalUrl: url.text.trim(),
          displayOrder: item?.displayOrder ?? 1,
          status: item?.status ?? 'published',
        ),
      );
  ref.invalidate(adminCultureTemplateProvider(templateId));
}

Future<void> _publish(BuildContext context, WidgetRef ref, String id) async {
  await ref.read(adminCultureRepositoryProvider).publishTemplate(id);
  ref.invalidate(adminCultureTemplateProvider(id));
  ref.invalidate(adminCultureTemplatesProvider);
}

Future<void> _apply(BuildContext context, WidgetRef ref, String id) async {
  final classes = await ref
      .read(adminRepositoryProvider)
      .classes(const AdminListQuery(status: 'active'));
  if (!context.mounted) return;
  final selected = <String>{};
  final ok = await showModalBottomSheet<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => ListView(
        padding: const EdgeInsets.all(EmiSpacing.md),
        children: [
          Text('Pilih Kelas', style: Theme.of(context).textTheme.titleLarge),
          for (final item in classes.items)
            CheckboxListTile(
              title: Text(item.name),
              value: selected.contains(item.id),
              onChanged: (value) => setState(
                () => value == true
                    ? selected.add(item.id)
                    : selected.remove(item.id),
              ),
            ),
          FilledButton(
            onPressed: selected.isEmpty
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Terapkan'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return;
  final result = await ref
      .read(adminCultureRepositoryProvider)
      .applyTemplate(id, selected.toList());
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Diterapkan: ${result.applied}, dilewati: ${result.skipped}, gagal: ${result.failed}.',
        ),
      ),
    );
  }
}
