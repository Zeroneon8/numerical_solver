# Numerical Solver

Aplicación móvil educativa para la resolución paso a paso de sistemas de ecuaciones lineales mediante métodos de análisis numérico. Desarrollada en Flutter para Android.

---

## ¿Qué hace?

El usuario ingresa los coeficientes de un sistema de ecuaciones lineales de tamaño n×n (desde 2×2 hasta 6×6) a través de una grilla interactiva con teclado matemático personalizado, elige un método de solución y obtiene el resultado con cada paso intermedio explicado y renderizado en notación matemática LaTeX.

La app está pensada como herramienta de apoyo académico: no solo da la respuesta final, sino que muestra el proceso completo de forma que un estudiante pueda seguir y entender cada operación realizada.

---

## Métodos disponibles

| Método | Tipo | Notas |
|---|---|---|
| Factorización LU | Directo | Con pivoteo parcial. Muestra matrices L y U por separado. |
| Método de Jacobi | Iterativo | Máx. 100 iteraciones, tolerancia 1×10⁻⁶. |
| Método de Gauss-Seidel | Iterativo | Máx. 100 iteraciones, tolerancia 1×10⁻⁶. |

Los métodos iterativos intentan reorganizar automáticamente las filas para maximizar la dominancia diagonal antes de iterar. Si el sistema no converge, la app lo indica con un mensaje claro sin mostrar pasos parciales.

---

## Características principales

- **Aritmética de alta precisión** — todos los cálculos internos utilizan `double`, haciendo aproximaciones precisas.
- **Teclado matemático personalizado** — dos pestañas: una numérica con soporte para potencias (`xⁿ`), raíces (`ⁿ√`), π y *e*; y una alfabética para expresiones con letras.
- **Renderizado LaTeX nativo** — los resultados y pasos se renderizan con `flutter_math_fork` sin WebView.
- **Validación en tiempo real** — las celdas con expresiones inválidas se marcan visualmente en rojo antes de intentar resolver.
- **Multiplicación implícita** — expresiones como `9e` o `2π` se interpretan automáticamente como `9×e` y `2×π`.
- **Paso a paso pedagógico** — cada operación significativa genera una tarjeta expandible con título descriptivo, explicación y estado de la matriz en ese momento.
- **Reorganización automática de filas** — antes de los métodos iterativos se intenta reordenar la matriz para maximizar dominancia diagonal.

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Framework | Flutter (Android only) |
| Lenguaje | Dart |
| Estado | flutter_riverpod |
| Navegación | go_router |
| Renderizado matemático | flutter_math_fork |
| Aritmética exacta | fraction |

---

## Arquitectura

El proyecto sigue una arquitectura en tres capas:

```
lib/
├── domain/          # Modelos, entidades y contratos (sin dependencias externas)
│   ├── models/      # Matrix, LinearSystem, SolutionStep
│   ├── enums/       # NumericalMethod, ProximityZone
│   └── repositories/
├── data/            # Implementaciones concretas
│   └── solvers/     # LuSolver, JacobiSolver, GaussSeidelSolver
├── presentation/    # UI y estado
│   ├── screens/
│   ├── widgets/     # MatrixInputGrid, MathKeyboard, StepCard
│   └── providers/
└── utils/           # ExpressionParser, ExpressionEvaluator, LatexFormatter
```

La separación entre capas permite que los solvers sean completamente independientes de Flutter y puedan probarse como Dart puro.

---

## Dependencias principales

```yaml
flutter_math_fork: ^0.7.2
fraction: ^5.1.0
flutter_riverpod: ^2.5.0
go_router: ^14.0.0
```

---

## Requisitos

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android SDK >= 21 (Android 5.0)
- Dispositivo o emulador Android (la app no tiene soporte para iOS ni web)

---

## Instalación y ejecución

```bash
# Clonar el repositorio
git clone https://github.com/Zeroneon8/numerical_solver.git
cd numerical-solver

# Instalar dependencias
flutter pub get

# Ejecutar en dispositivo o emulador Android conectado
flutter run
```

Para generar un APK de release:

```bash
flutter build apk --release
```

---

## Limitaciones conocidas

- Tamaño máximo de sistema: 6×6. Sistemas más grandes generan demasiados pasos para ser legibles en pantalla móvil.
- Expresiones con funciones trigonométricas (seno, coseno) no están soportadas en esta versión.
- La app es Android exclusivamente. No existe plan de soporte para iOS en esta versión.

---

## Licencia
 
Licencia MIT con Restricción No Comercial
 
Copyright (c) 2025 Juan David Alvarez Tapias e Isabella Guerra Rincón
 
Se concede permiso, de forma gratuita, a cualquier persona que obtenga una copia de este software y los archivos de documentación asociados, para utilizar el software con las siguientes condiciones:
 
**Permitido:**
- Usar, copiar y distribuir el software de forma gratuita
- Modificar el software y distribuir versiones modificadas
- Usar el software con fines académicos, educativos, de investigación o personales
**No permitido:**
- Usar el software, total o parcialmente, con fines comerciales de ningún tipo
- Vender el software o versiones derivadas del mismo
- Incluir el software en productos o servicios de pago
- Sublicenciar el software para uso comercial por parte de terceros
Para cualquier uso comercial se requiere autorización expresa y por escrito de los titulares del copyright.
 
El aviso de copyright anterior y este aviso de permiso se incluirán en todas las copias o partes sustanciales del software.
 
EL SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O IMPLÍCITA, INCLUYENDO PERO NO LIMITADO A LAS GARANTÍAS DE COMERCIABILIDAD, IDONEIDAD PARA UN PROPÓSITO PARTICULAR Y NO INFRACCIÓN. EN NINGÚN CASO LOS AUTORES O TITULARES DEL COPYRIGHT SERÁN RESPONSABLES DE NINGUNA RECLAMACIÓN, DAÑO U OTRA RESPONSABILIDAD, YA SEA EN UNA ACCIÓN DE CONTRATO, AGRAVIO O DE OTRO MODO, QUE SURJA DE, FUERA DE O EN CONEXIÓN CON EL SOFTWARE O EL USO U OTROS TRATOS EN EL SOFTWARE.
---

## Autores

- **Juan David Alvarez Tapias**
- **Isabella Guerra Rincón**
