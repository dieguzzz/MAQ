# 🗺️ Mapa Personalizado del Metro

## ✅ Funcionalidad Implementada

Ya tienes un **mapa personalizado** que muestra solo las líneas del metro sin el mapa completo de Google Maps. Este mapa es ideal para visualizar el estado del metro de forma simple y clara.

---

## 🎯 Cómo Usarlo

### 1. En la Pantalla Principal

La pantalla principal (`HomeScreen`) ahora tiene un **botón para cambiar entre mapas**:

- **Botón de Tren (🚇)**: Muestra el mapa personalizado del metro
- **Botón de Mapa (🗺️)**: Muestra Google Maps completo

**Ubicación del botón:** En el AppBar, a la izquierda del filtro de líneas.

### 2. Características del Mapa Personalizado

El mapa personalizado muestra:

- ✅ **Línea 1 (Azul)**: Todas las estaciones de la Línea 1
- ✅ **Línea 2 (Verde)**: Todas las estaciones de la Línea 2
- ✅ **Estaciones con estado**:
  - 🟢 Verde: Normal
  - 🟡 Amarillo: Moderado
  - 🔴 Rojo: Lleno
  - ⚫ Gris: Cerrado
- ✅ **Tiempo estimado** para próximo tren
- ✅ **Trenes animados** en movimiento
- ✅ **Fondo limpio** sin calles ni edificios (solo las líneas del metro)

---

## 📱 Archivos Relacionados

### Widget del Mapa Personalizado
- **Archivo**: `lib/widgets/custom_metro_map.dart`
- **Widget**: `CustomMetroMap`

### Pantalla de Uso
- **Archivo**: `lib/screens/home/home_screen.dart`
- **Uso**: Toggle entre Google Maps y mapa personalizado

### Pantalla Completa (Opcional)
- **Archivo**: `lib/screens/home/custom_map_screen.dart`
- **Widget**: `CustomMapScreen`
- **Uso**: Pantalla completa dedicada al mapa personalizado

---

## 🎨 Personalización

### Cambiar Colores de las Líneas

En `lib/widgets/custom_metro_map.dart`:

```dart
// Línea 1 (Azul)
paint.color = Colors.blue; // Cambia este color

// Línea 2 (Verde)
paint.color = Colors.green; // Cambia este color
```

### Cambiar Tamaño de Estaciones

```dart
canvas.drawCircle(Offset(x, y), 12, paint); // Cambia 12 por otro tamaño
```

### Cambiar Grosor de Líneas

```dart
final paint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 4; // Cambia 4 por otro grosor
```

---

## 🔄 Mejoras Futuras

### 1. Usar Coordenadas Reales

Actualmente el mapa dibuja líneas horizontales simples. Para usar coordenadas reales:

1. Obtén las coordenadas exactas de cada estación
2. Convierte coordenadas GPS (lat/lng) a coordenadas de pantalla
3. Dibuja las líneas conectando las estaciones según sus coordenadas reales

### 2. Crear un Mapa Vectorial (SVG)

Puedes crear un mapa del metro en formato SVG usando herramientas como:
- **Inkscape** (gratis)
- **Adobe Illustrator**
- **Figma**
- **MapBox Studio**

Luego puedes cargar el SVG en Flutter usando `flutter_svg`.

### 3. Usar Mapbox Personalizado

Puedes usar **Mapbox** para crear un estilo de mapa personalizado que muestre solo las líneas del metro:

1. Crea un estilo de mapa en Mapbox Studio
2. Oculta calles, edificios, y otros elementos
3. Solo muestra las líneas del metro
4. Úsalo con `mapbox_gl_flutter`

---

## 💡 Crear un Mapa Personalizado en Otra App

### Opción 1: Inkscape (Gratis)

1. **Descarga Inkscape**: https://inkscape.org/
2. **Crea un nuevo documento**
3. **Importa el mapa base** de Panamá (opcional)
4. **Dibuja las líneas del metro**:
   - Línea 1 en azul
   - Línea 2 en verde
5. **Agrega las estaciones** como círculos
6. **Exporta como SVG**
7. **Úsalo en Flutter** con `flutter_svg`

### Opción 2: MapBox Studio (Gratis)

1. **Crea una cuenta en Mapbox**: https://www.mapbox.com/
2. **Abre Mapbox Studio**
3. **Crea un nuevo estilo**
4. **Personaliza el mapa**:
   - Oculta calles, edificios, etc.
   - Agrega las líneas del metro como capas personalizadas
5. **Publica el estilo**
6. **Úsalo en Flutter** con `mapbox_gl_flutter`

### Opción 3: Google My Maps

1. **Crea un mapa en Google My Maps**
2. **Agrega las líneas del metro** como rutas
3. **Agrega las estaciones** como marcadores
4. **Exporta el mapa** (formato KML)
5. **Convierte a formato compatible** para Flutter

---

## 📦 Instalación de Paquetes (si usas SVG o Mapbox)

### Para usar SVG:
```yaml
dependencies:
  flutter_svg: ^2.0.9
```

### Para usar Mapbox:
```yaml
dependencies:
  mapbox_gl: ^0.17.0
```

---

## 🎯 Recomendación

**Para tu caso, la mejor opción es:**

1. **Mejorar el mapa personalizado actual** para que use coordenadas reales
2. **Mantener el fondo simple** (sin calles ni edificios)
3. **Enfocarse en las líneas del metro** y su estado

Esto te dará un mapa limpio y claro, perfecto para mostrar el estado del metro en tiempo real.

---

## ✅ Próximos Pasos

1. **Probar el mapa personalizado**: Presiona el botón de tren en la pantalla principal
2. **Personalizar los colores**: Cambia los colores de las líneas si lo deseas
3. **Mejorar con coordenadas reales**: Si tienes las coordenadas exactas, podemos actualizar el mapa

---

**¡El mapa personalizado ya está funcionando! Solo necesitas presionar el botón de tren (🚇) en la pantalla principal para verlo.** 🚀

