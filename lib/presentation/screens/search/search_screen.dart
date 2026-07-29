import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/recetas_provider.dart';
import '../../widgets/search_result_card.dart';

/// Pantalla de búsqueda - Permite buscar recetas por texto o condición
class SearchScreen extends StatefulWidget {
  final String initialQuery;
  
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _searchController.text = widget.initialQuery;
      _currentQuery = widget.initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RecetasProvider>().search(widget.initialQuery);
      });
    }
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
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
            Icon(TablerIcons.search, size: 20),
            SizedBox(width: 8),
            Text('Buscar Remedios'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════
          // BARRA DE BÚSQUEDA
          // ═══════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppConstants.borderLight,
                  width: 0.5,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: const TextStyle(
                fontSize: 15,
                color: AppConstants.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, condición o ingrediente...',
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
                          setState(() {
                            _currentQuery = '';
                          });
                          context.read<RecetasProvider>().clearSearch();
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
              onChanged: (value) {
                setState(() {
                  _currentQuery = value;
                });
                context.read<RecetasProvider>().search(value);
              },
            ),
          ),

          // ═══════════════════════════════════════════════════════════
          // SUGERENCIAS O RESULTADOS
          // ═══════════════════════════════════════════════════════════
          if (_currentQuery.isEmpty)
            Expanded(child: _buildSuggestions()),

          if (_currentQuery.isNotEmpty)
            Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SUGERENCIAS DE BÚSQUEDA RÁPIDA
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSuggestions() {
    final suggestions = [
      {'icon': TablerIcons.bandage, 'text': 'dolor de cabeza'},
      {'icon': TablerIcons.virus, 'text': 'gripe'},
      {'icon': TablerIcons.brain, 'text': 'ansiedad'},
      {'icon': TablerIcons.heartbeat, 'text': 'presión alta'},
      {'icon': TablerIcons.droplet, 'text': 'diabetes'},
      {'icon': TablerIcons.mood_sick, 'text': 'tos'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Búsquedas populares',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConstants.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((suggestion) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppConstants.borderLight,
                width: 0.5,
              ),
            ),
            child: ListTile(
              leading: Icon(
                suggestion['icon'] as IconData,
                size: 20,
                color: AppConstants.sageGreenTitle,
              ),
              title: Text(
                suggestion['text'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textPrimary,
                ),
              ),
              trailing: const Icon(
                TablerIcons.arrow_right,
                size: 16,
                color: AppConstants.textTertiary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 2,
              ),
              onTap: () {
                _searchController.text = suggestion['text'] as String;
                setState(() {
                  _currentQuery = suggestion['text'] as String;
                });
                context.read<RecetasProvider>().search(
                      suggestion['text'] as String,
                    );
              },
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // RESULTADOS DE BÚSQUEDA
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSearchResults() {
    return Consumer<RecetasProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppConstants.sageGreenTitle,
              strokeWidth: 2,
            ),
          );
        }

        if (provider.searchResults.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    TablerIcons.search_off,
                    size: 48,
                    color: AppConstants.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron resultados',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'para "$_currentQuery"',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Probá con otro término',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppConstants.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: provider.searchResults.length,
          itemBuilder: (context, index) {
            final result = provider.searchResults[index];
            return SearchResultCard(result: result);
          },
        );
      },
    );
  }
}
