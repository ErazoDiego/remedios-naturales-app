import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar estados de carga, error y vacío
class LoadingErrorEmpty extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback? onRetry;
  final Widget? child;

  const LoadingErrorEmpty({
    super.key,
    this.isLoading = false,
    this.error,
    this.isEmpty = false,
    this.emptyMessage = 'No hay datos disponibles',
    this.emptyIcon = Icons.inbox,
    this.onRetry,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Estado de carga
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Estado de error
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Estado vacío
    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Estado normal (con contenido)
    return child ?? const SizedBox.shrink();
  }
}

/// Widget reutilizable para mostrar estados de carga en listas
class LoadingList extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final VoidCallback? onRetry;
  final String emptyMessage;

  const LoadingList({
    super.key,
    this.isLoading = false,
    this.error,
    required this.itemCount,
    required this.itemBuilder,
    this.onRetry,
    this.emptyMessage = 'No hay elementos',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(error!, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      );
    }

    if (itemCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
