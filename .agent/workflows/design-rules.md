---
description: Reglas de diseño UI y branding para MetroPTY
---

# 🎨 Reglas de Diseño UI - MetroPTY

## Estilo Visual: Duolingo + Panamá

El diseño de la app debe tener un estilo moderno tipo Duolingo con toques panameños:

### Características del Estilo
1. **Tarjetas con gradientes suaves** (esquinas 24px)
2. **Sombras suaves y elegantes** (blur: 20px, offset: 8px)
3. **Headers con emojis** para cada sección
4. **Colores vibrantes** pero no chillones
5. **Fuentes bold** para información importante
6. **Animaciones sutiles** (<300ms)

### Emojis por Sección
```dart
🚇 Próximos trenes
📊 Estado actual
⚡ Acciones rápidas
🏆 Logros / Gamificación
📍 Ubicación
🎯 Precisión
🔥 Rachas
```

### Colores del Metro de Panamá
```dart
// Línea 1 - Azul
MetroColors.blue (#0066CC)
Gradient: [Colors.white, Color(0xFFF0F7FF)]

// Línea 2 - Verde
MetroColors.green (#009933)
Gradient: [Colors.white, Color(0xFFF0FFF4)]

// Estado actual - Naranja cálido
Gradient: [Colors.white, Color(0xFFFFF8F0)]

// Acciones - Azul suave
Gradient: [Colors.white, Color(0xFFF0F4FF)]
```

### Estructura de Tarjetas
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, colorDeFondo],
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: colorPrincipal.withValues(alpha: 0.12),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: Column(
    children: [
      Row(
        children: [
          Text('🚇', style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text('Título', style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          )),
        ],
      ),
      // Contenido...
    ],
  ),
)
```

### Countdowns y Números Importantes
```dart
TextStyle(
  fontWeight: FontWeight.w900,
  fontSize: 22,  // Grande para "Próximo"
  letterSpacing: -1,
)
```

## Orden de Secciones en StationInfoView
1. **Header** - Nombre de estación
2. **Próximos trenes** - ETA y Llegó el metro
3. **Estado actual** - Aglomeración y problemas
4. **Confirmación** - Confirmar llegada
5. **Acciones rápidas** - Siempre al final

## Cultura Panameña
- Usar referencias culturales cuando aplique
- Badges con temas panameños (Carnaval, Pollera, etc.)
- Idioma español panameño natural
- Considerar horarios del metro real de Panamá

## Anti-Patterns (NO HACER)
❌ Diseños planos sin profundidad
❌ Esquinas muy cuadradas (máx 8px sin gradiente)
❌ Sombras duras o muy oscuras
❌ Textos pequeños para información importante
❌ Muchos colores diferentes en una pantalla
❌ Placeholders sin estilo
