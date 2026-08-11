import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/payments/premium_rules.dart';
import '../../../data/models/receta_usuario.dart';
import '../../providers/mis_recetas_provider.dart';
import '../../providers/premium_provider.dart';
import '../../widgets/premium/premium_dialog.dart';

/// Formulario de creación/edición de una receta propia.
///
/// - `receta == null` → modo crear.
/// - `receta != null` → modo editar (precarga los campos).
///
/// Las listas (ideal para, ingredientes, preparación) usan chips dinámicos:
/// texto + botón agregar, cada item se puede quitar con la X.
class RecetaUsuarioFormScreen extends StatefulWidget {
  final RecetaUsuario? receta;

  const RecetaUsuarioFormScreen({super.key, this.receta});

  bool get isEditing => receta != null;

  @override
  State<RecetaUsuarioFormScreen> createState() => _RecetaUsuarioFormScreenState();
}

class _RecetaUsuarioFormScreenState extends State<RecetaUsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _tipoController;
  late final TextEditingController _tipoPreparacionController;
  late final TextEditingController _cuandoUsarController;
  late final TextEditingController _precaucionController;
  late final TextEditingController _dosisController;
  late final TextEditingController _almacenamientoController;

  late final List<String> _idealPara;
  late final List<String> _ingredientes;
  late final List<String> _preparacion;

  @override
  void initState() {
    super.initState();
    final r = widget.receta;
    _nombreController = TextEditingController(text: r?.nombre ?? '');
    _descripcionController = TextEditingController(text: r?.descripcion ?? '');
    _tipoController = TextEditingController(text: r?.tipo ?? '');
    _tipoPreparacionController =
        TextEditingController(text: r?.tipoPreparacion ?? '');
    _cuandoUsarController = TextEditingController(text: r?.cuandoUsar ?? '');
    _precaucionController = TextEditingController(text: r?.precaucion ?? '');
    _dosisController = TextEditingController(text: r?.dosis ?? '');
    _almacenamientoController =
        TextEditingController(text: r?.almacenamiento ?? '');
    _idealPara = [...?r?.idealPara];
    _ingredientes = [...?r?.ingredientes];
    _preparacion = [...?r?.preparacion];
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _tipoController.dispose();
    _tipoPreparacionController.dispose();
    _cuandoUsarController.dispose();
    _precaucionController.dispose();
    _dosisController.dispose();
    _almacenamientoController.dispose();
    super.dispose();
  }

  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Poné un nombre a tu receta';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MisRecetasProvider>();

    // Gating premium (solo modo crear; editar no suma una receta nueva):
    // el plan FREE permite ${freeMisRecetasLimit} recetas propias.
    if (!widget.isEditing) {
      // Garantizar el conteo real: si la lista no se cargó aún (deep
      // link directo al form), cargar antes de validar el límite.
      if (provider.recetas.isEmpty) {
        await provider.load();
        if (!mounted) return;
      }
      final premium = context.read<PremiumProvider>();
      if (!PremiumRules.canCreateReceta(
        isPremium: premium.isPremium,
        currentRecetas: provider.recetas.length,
      )) {
        await showPremiumDialog(
          context,
          title: 'Llegaste al límite de recetas propias',
          message: 'En el plan gratis podés crear '
              '${AppConstants.freeMisRecetasLimit} recetas. Con Premium '
              'creás todas las que quieras.',
        );
        return;
      }
    }

    // Valores que vienen del form (los listados ya están normalizados).
    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();
    final tipo = _tipoController.text.trim();
    final tipoPreparacion = _tipoPreparacionController.text.trim();
    final cuandoUsar = _cuandoUsarController.text.trim().isEmpty
        ? null
        : _cuandoUsarController.text.trim();
    final precaucion = _precaucionController.text.trim();
    final dosis = _dosisController.text.trim();
    final almacenamiento = _almacenamientoController.text.trim();

    // Modo crear: draft sin id (la DB lo genera).
    // Modo editar: conservamos SOLO los campos de sistema del original
    // (id/usuarioId/creadoAt/actualizadoAt). NO usar copyWith para los
    // campos editables: `cuandoUsar ?? this.cuandoUsar` no permitiría
    // vaciar el campo (null mantiene el valor viejo).
    final ok = widget.isEditing
        ? await provider.actualizar(RecetaUsuario(
            id: widget.receta!.id,
            usuarioId: widget.receta!.usuarioId,
            nombre: nombre,
            descripcion: descripcion,
            idealPara: List.unmodifiable(_idealPara),
            tipo: tipo,
            tipoPreparacion: tipoPreparacion,
            cuandoUsar: cuandoUsar,
            precaucion: precaucion,
            ingredientes: List.unmodifiable(_ingredientes),
            preparacion: List.unmodifiable(_preparacion),
            dosis: dosis,
            almacenamiento: almacenamiento,
            creadoAt: widget.receta!.creadoAt,
            actualizadoAt: widget.receta!.actualizadoAt,
          ))
        : await provider.crear(RecetaUsuario(
            nombre: nombre,
            descripcion: descripcion,
            idealPara: List.unmodifiable(_idealPara),
            tipo: tipo,
            tipoPreparacion: tipoPreparacion,
            cuandoUsar: cuandoUsar,
            precaucion: precaucion,
            ingredientes: List.unmodifiable(_ingredientes),
            preparacion: List.unmodifiable(_preparacion),
            dosis: dosis,
            almacenamiento: almacenamiento,
          ));

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Receta actualizada'
                : '¡Receta guardada!',
          ),
          backgroundColor: AppConstants.sageGreenTitle,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo guardar'),
          backgroundColor: AppConstants.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MisRecetasProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/mis-recetas');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isEditing ? TablerIcons.edit : TablerIcons.plus,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(widget.isEditing ? 'Editar receta' : 'Nueva receta'),
          ],
        ),
        backgroundColor: AppConstants.headerBeige,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre (obligatorio)
              TextFormField(
                controller: _nombreController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Jarabe de jengibre',
                  prefixIcon: Icon(TablerIcons.leaf),
                ),
                validator: _validateNombre,
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Para qué sirve tu receta...',
                  prefixIcon: Icon(TablerIcons.align_left),
                ),
              ),
              const SizedBox(height: 16),

              // Ideal para (chips)
              _ChipsField(
                label: 'Ideal para',
                hint: 'Ej: tos, resfrío...',
                icon: TablerIcons.circle_check,
                initialItems: _idealPara,
                onChanged: (items) => setState(() => _idealPara
                  ..clear()
                  ..addAll(items)),
              ),
              const SizedBox(height: 16),

              // Tipo + tipo de preparación
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tipoController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        hintText: 'Ej: remedio casero',
                        prefixIcon: Icon(TablerIcons.tag),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tipoPreparacionController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Preparación',
                        hintText: 'Ej: infusión, jarabe',
                        prefixIcon: Icon(TablerIcons.flask),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ingredientes (chips)
              _ChipsField(
                label: 'Ingredientes',
                hint: 'Ej: 1 cda de miel...',
                icon: TablerIcons.basket,
                initialItems: _ingredientes,
                onChanged: (items) => setState(() => _ingredientes
                  ..clear()
                  ..addAll(items)),
              ),
              const SizedBox(height: 16),

              // Preparación (chips)
              _ChipsField(
                label: 'Preparación (pasos)',
                hint: 'Ej: hervir 10 min...',
                icon: TablerIcons.list_numbers,
                initialItems: _preparacion,
                onChanged: (items) => setState(() => _preparacion
                  ..clear()
                  ..addAll(items)),
              ),
              const SizedBox(height: 16),

              // Dosis + almacenamiento
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dosisController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Dosis',
                        hintText: 'Ej: 1 cucharada',
                        prefixIcon: Icon(TablerIcons.droplet),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _almacenamientoController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Almacenamiento',
                        hintText: 'Ej: frasco cerrado',
                        prefixIcon: Icon(TablerIcons.archive),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cuándo usar
              TextFormField(
                controller: _cuandoUsarController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Cuándo usar',
                  hintText: 'Ej: ante los primeros síntomas',
                  prefixIcon: Icon(TablerIcons.clock),
                ),
              ),
              const SizedBox(height: 16),

              // Precaución (warning)
              TextFormField(
                controller: _precaucionController,
                maxLines: 2,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Precaución',
                  hintText: 'Advertencias, contraindicaciones...',
                  prefixIcon: Icon(
                    TablerIcons.alert_triangle,
                    color: AppConstants.alertAmber,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: provider.isSaving ? null : _guardar,
                  child: provider.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.isEditing ? 'Guardar cambios' : 'Guardar receta',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de lista dinámica: TextField + botón agregar + chips removibles.
class _ChipsField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<String> initialItems;
  final ValueChanged<List<String>> onChanged;

  const _ChipsField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.initialItems,
    required this.onChanged,
  });

  @override
  State<_ChipsField> createState() => _ChipsFieldState();
}

class _ChipsFieldState extends State<_ChipsField> {
  late final List<String> _items = [...widget.initialItems];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _agregar() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    if (_items.contains(value)) {
      _controller.clear();
      return;
    }
    setState(() {
      _items.add(value);
      _controller.clear();
    });
    widget.onChanged(_items);
  }

  void _quitar(int index) {
    setState(() => _items.removeAt(index));
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 20, color: AppConstants.sageGreenTitle),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Input + botón agregar
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _agregar(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _agregar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.sageGreenTitle,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Icon(TablerIcons.plus, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Chips de los items
        if (_items.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _items.length; i++)
                InputChip(
                  label: Text(_items[i]),
                  onDeleted: () => _quitar(i),
                  backgroundColor: AppConstants.sageGreenCard,
                  side: BorderSide.none,
                  deleteIconColor: AppConstants.sageGreenTitle,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.sageGreenTitle,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
      ],
    );
  }
}
