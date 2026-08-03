import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/hierbas_provider.dart';

/// Pantalla del Herbolario — directorio de hierbas medicinales A-Z
/// con buscador y filtro por propiedad
class HerbolarioScreen extends StatefulWidget {
  const HerbolarioScreen({super.key});

  @override
  State<HerbolarioScreen> createState() => _HerbolarioScreenState();
}

class _HerbolarioScreenState extends State<HerbolarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HierbasProvider>().loadHierbas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentQuery = value;
    });
    context.read<HierbasProvider>().aplicarFiltros(busqueda: value);
  }

  void _onTagSelected(String? tag) {
    context.read<HierbasProvider>().aplicarFiltros(tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () => context.go('/'),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.leaf, size: 20),
            SizedBox(width: 8),
            Text('Herbolario'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: Consumer<HierbasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.hierbas.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppConstants.sageGreenTitle,
                strokeWidth: 2,
              ),
            );
          }

          if (provider.error != null && provider.hierbas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      TablerIcons.alert_circle,
                      size: 48,
                      color: AppConstants.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // ═══════════════════════════════════════════════════════
              // BARRA DE BÚSQUEDA
              // ═══════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppConstants.borderLight,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppConstants.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar hierba o propiedad...',
                        hintStyle: const TextStyle(
                          color: AppConstants.textTertiary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          TablerIcons.search,
                          size: 20,
                          color: AppConstants.textTertiary,
                        ),
                        suffixIcon: _currentQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  TablerIcons.x,
                                  size: 18,
                                  color: AppConstants.textTertiary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppConstants.backgroundCream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppConstants.borderLight,
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppConstants.borderLight,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppConstants.sageGreenTitle,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),

                    // Chips de propiedades (filtro rápido)
                    if (provider.tagsPopulares.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip(
                              label: 'Todas',
                              selected: provider.tagSeleccionado == null,
                              onTap: () => _onTagSelected(null),
                            ),
                            ...provider.tagsPopulares.map(
                              (tag) => _buildFilterChip(
                                label: provider.tagLabel(tag),
                                selected: provider.tagSeleccionado == tag,
                                onTap: () => _onTagSelected(tag),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ═══════════════════════════════════════════════════════
              // CONTADOR + LISTA DE HIERBAS
              // ═══════════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${provider.resultados.length} hierbas',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: provider.resultados.isEmpty
                    ? _buildEmptyState(provider)
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: provider.resultados.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final hierba = provider.resultados[index];
                          return _HerbaCard(
                            hierba: hierba,
                            provider: provider,
                            onTap: () {
                              context.push(
                                '/herba/${hierba.id}',
                                extra: hierba,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppConstants.sageGreenTitle
                : Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? AppConstants.sageGreenTitle
                  : AppConstants.borderLight,
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected
                  ? Colors.white
                  : AppConstants.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(HierbasProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              TablerIcons.leaf_off,
              size: 48,
              color: AppConstants.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron hierbas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentQuery.isNotEmpty
                  ? 'para "$_currentQuery"'
                  : 'para este filtro',
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                provider.limpiarFiltros();
                setState(() => _currentQuery = '');
              },
              child: const Text(
                'Limpiar filtros',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.sageGreenTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de hierba en la lista del herbolario
class _HerbaCard extends StatelessWidget {
  final dynamic hierba;
  final HierbasProvider provider;
  final VoidCallback onTap;

  const _HerbaCard({
    required this.hierba,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tags = (hierba.tags as List).take(3).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.borderLight,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppConstants.backgroundCream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      TablerIcons.leaf,
                      size: 18,
                      color: AppConstants.sageGreenTitle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hierba.nombre as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    TablerIcons.chevron_right,
                    size: 18,
                    color: AppConstants.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hierba.propiedades as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.textSecondary,
                  height: 1.4,
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.backgroundCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        provider.tagLabel(tag as String),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppConstants.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
