# Checklist de Pruebas Manuales

## 1. Creación de Reportes

- [ ] Crear reporte de estación operativa con crowd bajo (yes, crowd 1-2)
  - Verificar que el estado de la estación se actualiza a "normal" en el mapa
  - Verificar que el estado se muestra correctamente en el bottom sheet
  - Verificar que el reporte aparece en "Últimos reportes"

- [ ] Crear reporte de estación parcialmente operativa (partial)
  - Verificar que el estado se actualiza a "moderado"
  - Verificar que se muestra correctamente

- [ ] Crear reporte de estación cerrada (no)
  - Verificar que el estado se actualiza a "cerrado"
  - Verificar que se muestra con el ícono correcto

- [ ] Crear reporte con problemas específicos (issues)
  - Verificar que se otorgan puntos bonus (+5 por issue)
  - Verificar que los issues se guardan correctamente

## 2. Múltiples Reportes

- [ ] Crear 2 reportes con mismo estado (ej: ambos "yes" + crowd 2)
  - Verificar que el estado de la estación refleja el consenso
  - Verificar que ambos reportes aparecen en "Últimos reportes"

- [ ] Crear 3 reportes con estados diferentes
  - Ejemplo: 2 dicen "yes" + crowd 2, 1 dice "yes" + crowd 4
  - Verificar que gana el más común (moda)
  - Verificar que la aglomeración es el promedio

- [ ] Crear 5+ reportes para una estación
  - Verificar que se usa promedio ponderado por confirmaciones
  - Verificar que reportes con más confirmaciones pesan más

## 3. Confirmaciones

- [ ] Confirmar un reporte de otro usuario
  - Verificar que aumenta el contador de confirmaciones
  - Verificar que se otorgan puntos al confirmador
  - Verificar que se otorgan puntos al autor del reporte

- [ ] Alcanzar 3 confirmaciones en un reporte
  - Verificar que el reporte se marca como "community_verified"
  - Verificar que la estación se actualiza automáticamente
  - Verificar que el autor recibe notificación (si está configurado)

- [ ] Intentar confirmar el propio reporte
  - Verificar que muestra error "No puedes confirmar tu propio reporte"

- [ ] Intentar confirmar el mismo reporte dos veces
  - Verificar que muestra error "Ya confirmaste este reporte"

## 4. Tiempo Real

- [ ] Abrir app en 2 dispositivos o emuladores
- [ ] Crear reporte en dispositivo 1
- [ ] Verificar que dispositivo 2 se actualiza automáticamente
  - El estado de la estación debe cambiar
  - El reporte debe aparecer en "Últimos reportes"
  - No debe requerir refresh manual

## 5. Edge Cases

- [ ] Crear reporte sin ubicación (sin permisos de GPS)
  - Verificar que el reporte se crea correctamente
  - Verificar que la estación se actualiza

- [ ] Crear reporte con valores null
  - Verificar que el sistema maneja correctamente valores faltantes

- [ ] Estación sin reportes
  - Verificar que muestra estado por defecto
  - Verificar que no hay errores en consola

- [ ] Reportes muy antiguos (más de 30 min)
  - Crear reporte, esperar 31 minutos
  - Verificar que el reporte antiguo no afecta el estado actual
  - Verificar que solo reportes recientes se consideran

- [ ] Múltiples reportes simultáneos
  - Crear varios reportes rápidamente para la misma estación
  - Verificar que el sistema calcula correctamente el consenso
  - Verificar que no hay condiciones de carrera

## 6. UI y Visualización

- [ ] Verificar que los reportes se muestran en formato legible
  - Debe mostrar: estado (emoji), crowd level, confirmaciones, tiempo

- [ ] Verificar que la confianza se muestra correctamente
  - Alta confianza (high): verde
  - Media confianza (medium): amarillo
  - Baja confianza (low): rojo

- [ ] Verificar que el estado de la estación se refleja en el mapa
  - Normal: verde
  - Moderado: amarillo/naranja
  - Lleno: rojo
  - Cerrado: gris

## 7. Performance

- [ ] Verificar que no hay lag al crear reportes
- [ ] Verificar que las actualizaciones en tiempo real son rápidas (< 2 segundos)
- [ ] Verificar que no hay memory leaks después de múltiples reportes

## 8. Errores y Validación

- [ ] Intentar crear reporte sin estar autenticado
  - Debe mostrar error apropiado

- [ ] Verificar manejo de errores de red
  - Desconectar internet, intentar crear reporte
  - Debe mostrar error apropiado
  - Al reconectar, debe funcionar normalmente

## Notas

- Todas las pruebas deben realizarse en un entorno de desarrollo/test
- Verificar logs en consola para errores inesperados
- Documentar cualquier comportamiento inesperado encontrado

