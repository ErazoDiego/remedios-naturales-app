import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../features/lista_compras/presentation/lista_compras_provider.dart';

/// Botón "Agregar a la lista de compras", COMPARTIDO por el detalle del
/// núcleo/colecciones ([RecipeDetailBody]) y el de recetas propias
/// (RecetaUsuarioDetailScreen): un solo punto de entrada, mismo
/// comportamiento y mismo feedback (SnackBar).
///
/// La receta viaja por su NOMBRE ([recetaNombre]) y la lista de
/// [ingredientes] ya resuelta; el provider deduplica por token
/// normalizado sin sumar cantidades.
class AgregarAListaButton extends StatelessWidget {
  final String recetaNombre;
  final List<String> ingredientes;

  const AgregarAListaButton({
    super.key,
    required this.recetaNombre,
    required this.ingredientes,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          context
              .read<ListaComprasProvider>()
              .agregarDesdeReceta(recetaNombre, ingredientes);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Text('Agregado a la lista de compras'),
                backgroundColor: AppConstants.sageGreenTitle,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
        },
        icon: const Icon(TablerIcons.shopping_cart, size: 18),
        label: const Text('Agregar a la lista de compras'),
        style: OutlinedButton.styleFrom(
          // MISMO color que el título de cada receta (sageGreenTitle),
          // aplicado como texto sobre fondo claro — el mismo contexto
          // visual del título, así el verde se percibe "suave".
          foregroundColor: AppConstants.sageGreenTitle,
          backgroundColor: AppConstants.sageGreenCard.withValues(alpha: 0.4),
          side: BorderSide(
            color: AppConstants.sageGreenTitle.withValues(alpha: 0.35),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
