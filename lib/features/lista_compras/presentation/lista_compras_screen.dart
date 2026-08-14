import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tabler_icons/tabler_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/item_lista.dart';
import 'lista_compras_provider.dart';

/// Pantalla de la LISTA DE COMPRAS.
///
/// La lista es DEL usuario: las recetas solo la alimentan (botón
/// "Agregar a la lista" en los detalles) y acá también se agregan ítems
/// manuales ("12 huevos"). Dedupe por token normalizado: la llave une,
/// el dato no miente (las cantidades se listan tal cual, nunca se suman).
class ListaComprasScreen extends StatefulWidget {
  const ListaComprasScreen({super.key});

  @override
  State<ListaComprasScreen> createState() => _ListaComprasScreenState();
}

class _ListaComprasScreenState extends State<ListaComprasScreen> {
  final TextEditingController _manualController = TextEditingController();

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListaComprasProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.shopping_cart,
              size: 20,
              color: AppConstants.sageGreenTitle,
            ),
            SizedBox(width: 8),
            Text('Lista de compras'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
        actions: [
          if (provider.items.isNotEmpty)
            IconButton(
              icon: const Icon(
                TablerIcons.share,
                size: 18,
                color: AppConstants.sageGreenTitle,
              ),
              tooltip: 'Compartir',
              onPressed: () => _compartir(context, provider),
            ),
          if (provider.items.isNotEmpty)
            IconButton(
              icon: const Icon(
                TablerIcons.trash,
                size: 18,
                color: AppConstants.alertRed,
              ),
              tooltip: 'Vaciar lista',
              onPressed: () => _confirmarVaciar(context, provider),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.items.isEmpty
                ? _buildEmptyState()
                : _buildLista(provider),
          ),
          // ═══════════════════════════════════════════════════════════
          // AGREGAR ÍTEM MANUAL
          // ═══════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppConstants.borderLight,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _agregarManual(),
                      decoration: InputDecoration(
                        hintText: 'Agregar ítem... ej: 12 huevos',
                        hintStyle: const TextStyle(
                          color: AppConstants.textTertiary,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppConstants.backgroundCream,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
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
                            width: 1,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _agregarManual,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConstants.sageGreenTitle,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(TablerIcons.plus, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lista de ítems ───
  Widget _buildLista(ListaComprasProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        return _buildItemCard(provider.items[index]);
      },
    );
  }

  Widget _buildItemCard(ItemLista item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.borderLight,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Checkbox de comprado ───
            Checkbox(
              value: item.marcado,
              activeColor: AppConstants.sageGreenTitle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (_) =>
                  context.read<ListaComprasProvider>().toggleMarcado(
                        item.tokenBase,
                      ),
            ),
            // ─── Detalle del ítem ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombreMostrable,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                      letterSpacing: -0.2,
                      decoration:
                          item.marcado ? TextDecoration.lineThrough : null,
                      decorationColor: AppConstants.textTertiary,
                    ),
                  ),
                  // Cantidades: el DATO tal cual (nunca sumadas)
                  for (final cantidad in item.cantidades) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            TablerIcons.point,
                            size: 8,
                            color: AppConstants.sageGreenTitle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cantidad,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Origen: de qué recetas vino (para decidir qué preparar)
                  if (item.deRecetas.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Para: ${item.deRecetas.join(', ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppConstants.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ─── Borrar ítem ───
            IconButton(
              icon: const Icon(
                TablerIcons.x,
                size: 16,
                color: AppConstants.textTertiary,
              ),
              tooltip: 'Quitar',
              onPressed: () => context
                  .read<ListaComprasProvider>()
                  .quitarItem(item.tokenBase),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Estado vacío ───
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              TablerIcons.shopping_cart,
              size: 48,
              color: AppConstants.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu lista está vacía',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agregá ingredientes desde cualquier receta con el botón '
              '"Agregar a la lista de compras", o escribí un ítem abajo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Acciones ───
  void _agregarManual() {
    final texto = _manualController.text.trim();
    if (texto.isEmpty) return;
    context.read<ListaComprasProvider>().agregarManual(texto);
    _manualController.clear();
  }

  Future<void> _compartir(
    BuildContext context,
    ListaComprasProvider provider,
  ) async {
    final texto = provider.exportarTexto();
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: texto,
        subject: 'Lista de compras — Yuyo',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.zero,
      ),
    );
  }

  Future<void> _confirmarVaciar(
    BuildContext context,
    ListaComprasProvider provider,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Vaciar la lista?'),
        content: const Text('Se borran todos los ítems de la lista.'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Vaciar',
              style: TextStyle(
                color: AppConstants.alertRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmado == true && context.mounted) {
      provider.vaciar();
    }
  }
}
