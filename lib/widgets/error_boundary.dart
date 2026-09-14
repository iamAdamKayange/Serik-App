import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'loading_states.dart';

/// Error boundary widget to catch and handle errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final void Function(dynamic error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  dynamic _error;

  @override
  void initState() {
    super.initState();
    _error = null;
  }

  void _handleError(dynamic error, StackTrace stackTrace) {
    setState(() {
      _error = error;
    });
    widget.onError?.call(error, stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget ?? _buildDefaultError(context);
    }

    return ErrorReporter(
      onError: _handleError,
      child: widget.child,
    );
  }

  Widget _buildDefaultError(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'An unexpected error occurred. Please try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error reporter widget that catches errors in its child tree
class ErrorReporter extends StatefulWidget {
  final Widget child;
  final void Function(dynamic error, StackTrace stackTrace) onError;

  const ErrorReporter({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  State<ErrorReporter> createState() => _ErrorReporterState();
}

class _ErrorReporterState extends State<ErrorReporter> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Async error boundary for FutureBuilder and similar async operations
class AsyncErrorBoundary extends StatefulWidget {
  final Future<void> Function() future;
  final Widget Function()? loadingWidget;
  final Widget Function(Object error)? errorWidget;
  final Widget Function()? successWidget;

  const AsyncErrorBoundary({
    super.key,
    required this.future,
    this.loadingWidget,
    this.errorWidget,
    this.successWidget,
  });

  @override
  State<AsyncErrorBoundary> createState() => _AsyncErrorBoundaryState();
}

class _AsyncErrorBoundaryState extends State<AsyncErrorBoundary> {
  bool _isLoading = true;
  Object? _error;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _executeFuture();
  }

  Future<void> _executeFuture() async {
    try {
      await widget.future();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _success = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget?.call() ?? const LoadingState();
    }

    if (_error != null) {
      return widget.errorWidget?.call(_error!) ?? 
             ErrorState(
               title: 'Operation Failed',
               subtitle: _error.toString(),
               onRetry: _executeFuture,
             );
    }

    if (_success) {
      return widget.successWidget?.call() ?? const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }
}

/// Safe builder widget that handles errors gracefully
class SafeBuilder extends StatelessWidget {
  final Future<Widget> Function() builder;
  final Widget Function()? loadingWidget;
  final Widget Function(Object error)? errorWidget;

  const SafeBuilder({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: builder(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget?.call() ?? const LoadingState();
        }

        if (snapshot.hasError) {
          return errorWidget?.call(snapshot.error!) ??
                 ErrorState(
                   title: 'Error',
                   subtitle: snapshot.error.toString(),
                 );
        }

        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }
}