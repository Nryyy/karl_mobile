import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../data/documents_repository.dart';
import '../../domain/document_models.dart';
import '../../providers/document_actions_provider.dart';

// ─── Notifier ────────────────────────────────────────────────────────────────

class _TemplatesNotifier extends AsyncNotifier<List<DocumentTemplate>> {
  late DocumentsRepository _repo;

  @override
  Future<List<DocumentTemplate>> build() async {
    _repo = ref.read(documentsRepositoryProvider);
    return _load();
  }

  Future<List<DocumentTemplate>> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const [];
    final profile = await _repo.fetchCurrentUser(user.email ?? '');
    return _repo.fetchTemplates(
      organizationId: profile.organizationId.isNotEmpty
          ? profile.organizationId
          : null,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final _templatesProvider =
    AsyncNotifierProvider<_TemplatesNotifier, List<DocumentTemplate>>(
      _TemplatesNotifier.new,
    );

// ─── Page ─────────────────────────────────────────────────────────────────────

class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key, required this.repository});

  final DocumentsRepository repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [documentsRepositoryProvider.overrideWithValue(repository)],
      child: const _TemplatesPageContent(),
    );
  }
}

class _TemplatesPageContent extends ConsumerStatefulWidget {
  const _TemplatesPageContent();

  @override
  ConsumerState<_TemplatesPageContent> createState() =>
      _TemplatesPageContentState();
}

class _TemplatesPageContentState
    extends ConsumerState<_TemplatesPageContent> {
  final _searchController = TextEditingController();
  String _search = '';
  String _selectedCategory = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentTemplate> _filter(List<DocumentTemplate> all) {
    var result = all;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result
          .where(
            (t) =>
                t.name.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q) ||
                t.category.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_selectedCategory.isNotEmpty) {
      result =
          result.where((t) => t.category == _selectedCategory).toList();
    }
    return result;
  }

  List<String> _categories(List<DocumentTemplate> all) {
    final cats = all.map((t) => t.category).where((c) => c.isNotEmpty).toSet();
    return cats.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final async = ref.watch(_templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.templates ?? 'Templates'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(_templatesProvider.notifier).refresh(),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.read(_templatesProvider.notifier).refresh(),
          ),
          data: (all) {
            final categories = _categories(all);
            final filtered = _filter(all);
            return Column(
              children: [
                _SearchBar(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                ),
                if (categories.isNotEmpty)
                  _CategoryChips(
                    categories: categories,
                    selected: _selectedCategory,
                    onSelected: (c) =>
                        setState(() => _selectedCategory = c),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(hasFilters: _search.isNotEmpty || _selectedCategory.isNotEmpty)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => _TemplateCard(
                            template: filtered[i],
                            repository: ref.read(documentsRepositoryProvider),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Пошук шаблонів…',
          prefixIcon: const Icon(Icons.search_outlined),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Усі'),
              selected: selected.isEmpty,
              onSelected: (_) => onSelected(''),
            ),
          ),
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c),
                selected: selected == c,
                onSelected: (_) => onSelected(selected == c ? '' : c),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  const _TemplateCard({required this.template, required this.repository});

  final DocumentTemplate template;
  final DocumentsRepository repository;

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final bytes = await widget.repository.downloadTemplate(widget.template.id);
      if (!mounted) return;
      _showDownloadSuccess(bytes);
    } catch (e) {
      developer.log('Template download failed', name: 'karl.templates', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка завантаження: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showDownloadSuccess(Uint8List bytes) {
    final kb = (bytes.lengthInBytes / 1024).toStringAsFixed(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Завантажено ${widget.template.originalFileName} ($kb КБ)',
        ),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void _showDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TemplateDetailSheet(
        template: widget.template,
        onDownload: _download,
        downloading: _downloading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = widget.template;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showDetails,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _FileTypeIcon(fileType: t.fileType, colorScheme: colorScheme),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name.isNotEmpty ? t.name : t.originalFileName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (t.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        t.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (t.category.isNotEmpty)
                          _Chip(label: t.category, color: colorScheme.secondaryContainer),
                        _Chip(
                          label: t.fileType.toUpperCase(),
                          color: colorScheme.tertiaryContainer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _downloading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download_outlined),
                      tooltip: 'Завантажити',
                      onPressed: _download,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateDetailSheet extends StatelessWidget {
  const _TemplateDetailSheet({
    required this.template,
    required this.onDownload,
    required this.downloading,
  });

  final DocumentTemplate template;
  final VoidCallback onDownload;
  final bool downloading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = template;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FileTypeIcon(fileType: t.fileType, colorScheme: colorScheme, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name.isNotEmpty ? t.name : t.originalFileName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (t.originalFileName.isNotEmpty)
                      Text(
                        t.originalFileName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (t.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(t.description, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          _DetailRow(label: 'Тип файлу', value: t.fileType.toUpperCase()),
          if (t.category.isNotEmpty)
            _DetailRow(label: 'Категорія', value: t.category),
          if (t.createdByName.isNotEmpty)
            _DetailRow(label: 'Автор', value: t.createdByName),
          if (t.createdAt != null)
            _DetailRow(
              label: 'Дата створення',
              value: _formatDate(t.createdAt!),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: downloading ? null : onDownload,
              icon: downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(downloading ? 'Завантаження…' : 'Завантажити'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileTypeIcon extends StatelessWidget {
  const _FileTypeIcon({
    required this.fileType,
    required this.colorScheme,
    this.size = 40,
  });

  final String fileType;
  final ColorScheme colorScheme;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (fileType.toLowerCase()) {
      'pdf' => (Icons.picture_as_pdf_outlined, Colors.red.shade400),
      'docx' || 'doc' => (Icons.description_outlined, Colors.blue.shade400),
      'xlsx' || 'xls' => (Icons.table_chart_outlined, Colors.green.shade400),
      'pptx' || 'ppt' => (Icons.slideshow_outlined, Colors.orange.shade400),
      _ => (Icons.insert_drive_file_outlined, colorScheme.primary),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.search_off_outlined : Icons.article_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Нічого не знайдено' : 'Шаблони відсутні',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Спробуйте змінити параметри пошуку'
                  : 'Активні шаблони з\'являться тут',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Не вдалося завантажити шаблони',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Спробувати знову'),
            ),
          ],
        ),
      ),
    );
  }
}
