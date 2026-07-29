import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/recetas_provider.dart';
import '../../widgets/search_result_card.dart';

/// Pantalla por síntoma - Muestra recetas para una condición específica
class BySymptomScreen extends StatefulWidget {
  final String condition;

  const BySymptomScreen({super.key, required this.condition});

  @override
  State<BySymptomScreen> createState() => _BySymptomScreenState();
}

class _BySymptomScreenState extends State<BySymptomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecetasProvider>().search(widget.condition);
    });
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(TablerIcons.stethoscope, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.condition,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: Consumer<RecetasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppConstants.sageGreenTitle,
                strokeWidth: 2,
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      TablerIcons.alert_triangle,
                      size: 48,
                      color: AppConstants.alertAmber,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al buscar recetas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final results = provider.searchResults;

          if (results.isEmpty) {
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
                      'No encontramos recetas para',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${widget.condition}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.go('/search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.sageGreenTitle,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Buscar manualmente'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Header con cantidad de resultados
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppConstants.borderLight,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      TablerIcons.list_search,
                      size: 16,
                      color: AppConstants.sageGreenTitle,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${results.length} resultado${results.length == 1 ? '' : 's'} para "${widget.condition}"',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de resultados
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return SearchResultCard(
                      result: result,
                      showImage: false,
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
}
