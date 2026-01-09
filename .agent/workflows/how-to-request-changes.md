---
description: Cómo hacer solicitudes de cambios a la app
---

# 📋 Cómo Pedirme Cambios

## Tipos de Solicitudes

### 1. Rediseño de UI
Cuando quieras cambiar el aspecto visual, incluye:
- **Qué sección**: "el widget de ETA", "la pantalla de perfil"
- **Estilo deseado**: "como Duolingo", "más minimalista", "más colorido"
- **Referencias**: capturas de pantalla o nombres de apps similares
- **Mantener/Cambiar**: qué debe quedarse igual vs qué cambiar

**Ejemplo bueno:**
> "Quiero rediseñar la sección de Estado actual. Mantener la información pero hacerla más visual con iconos grandes y colores por estado (verde/amarillo/rojo)"

### 2. Nueva Funcionalidad
Cuando quieras agregar algo nuevo:
- **Qué hace**: descripción clara de la funcionalidad
- **Dónde aparece**: en qué pantalla o sección
- **Interacción**: cómo el usuario la usa
- **Datos**: qué información necesita

**Ejemplo bueno:**
> "Agregar un botón para compartir mi reporte en redes. Va en la pantalla de confirmación después de reportar. Genera una imagen con el estado del metro y un link a la app"

### 3. Arreglo de Bugs
Cuando algo no funciona:
- **Qué pasa**: describir el error exacto
- **Cuándo pasa**: en qué pantalla/acción
- **Qué debería pasar**: comportamiento esperado
- **Error visible**: mensaje de error si hay (overflow, etc)

**Ejemplo bueno:**
> "Hay un overflow de 33 pixels en la tarjeta de ETA cuando el número de minutos es grande. Debería ajustarse al espacio disponible"

### 4. Cambio de Orden/Estructura
Cuando quieras reorganizar:
- **Orden actual**: qué está arriba/abajo
- **Orden deseado**: qué quieres primero/último
- **Razón**: por qué (UX, importancia, etc)

**Ejemplo bueno:**
> "Mover Acciones rápidas al final del sheet. Primero quiero ver los trenes, luego el estado, y las acciones al final"

## Información que Siempre Ayuda

### Para UI
- ¿Mantener la estructura o cambiarla?
- ¿Qué información es más importante?
- ¿Hay elementos que sobran?

### Para Funcionalidad
- ¿Afecta gamificación (puntos/badges)?
- ¿Necesita guardar datos en Firebase?
- ¿Solo para ciertos usuarios?

### Para Bugs
- ¿En qué dispositivo/pantalla?
- ¿Qué tamaño de texto tiene el dispositivo?
- ¿Puedes reproducirlo consistentemente?

## Palabras Clave Útiles

| Dices | Entiendo |
|-------|----------|
| "Como Duolingo" | Gradientes, emojis, esquinas 24px, sombras suaves |
| "Más moderno" | Menos bordes, más espaciado, tipografía bold |
| "Mantener estructura" | Solo cambiar estilos, no mover elementos |
| "Panameño" | Colores del metro, referencias culturales |
| "Minimalista" | Menos elementos, más espacio blanco |
| "Más visible" | Fuentes más grandes, colores más vivos |

## Qué NO Necesitas Decirme
- Nombres de archivos específicos (los encuentro)
- Líneas de código exactas
- Sintaxis de Dart/Flutter
- Cómo implementarlo técnicamente
