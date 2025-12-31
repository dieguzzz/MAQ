# Prompt - Provider (ChangeNotifier) bien hecho

Crear/ajustar provider con:
- private fields: _data, _isLoading, _error
- getters públicos
- métodos async con try/catch/finally
- notifyListeners() en puntos correctos

No hacer:
- Llamar Firestore directo desde widgets
- Meter BuildContext en provider
