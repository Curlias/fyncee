# Detección Automática de Transacciones Bancarias

## 📱 Descripción

Esta funcionalidad permite que Fyncee detecte automáticamente transacciones desde las notificaciones de tu banco, eliminando la necesidad de ingresarlas manualmente.

## ⚙️ Cómo Funciona

1. **Lectura de Notificaciones**: Fyncee escucha las notificaciones del sistema en segundo plano
2. **Detección de Bancos**: Identifica notificaciones de apps bancarias configuradas
3. **Extracción de Datos**: Parsea la notificación para extraer:
   - Monto de la transacción
   - Tipo (cargo/abono)
   - Comercio o destinatario
   - Tipo de transacción
4. **Sugerencia de Categoría**: Sugiere automáticamente la categoría basándose en el comercio
5. **Creación de Transacción**: Crea la transacción automáticamente o pide confirmación

## 🏦 Bancos Soportados

La app viene preconfigurada con los siguientes bancos mexicanos:

- **BBVA** (`com.bbva.bancomer`)
- **Banorte** (`com.banorte.movil`)
- **Santander** (`com.santander.app`)
- **Scotiabank** (`com.scotiabank.mobile`)
- **Citibanamex** (`mx.com.citibanamex.banamexmobile`)
- **BanCoppel** (`mx.bancoppel.appbancoppel`)
- **Google Wallet** (`com.google.android.apps.walletnfcrel`)

## 📋 Requisitos

### Android
- **Android 4.3+** (API 18+)
- **Permiso de acceso a notificaciones**

### iOS
⚠️ **No compatible** - iOS no permite el acceso a notificaciones de otras apps por restricciones de privacidad.

## 🚀 Configuración

### Paso 1: Habilitar Permiso de Notificaciones

1. Abre la app Fyncee
2. Ve a **Perfil → Ajustes → Detección automática**
3. Activa el switch "Activar detección automática"
4. Toca "Abrir Configuración de Notificaciones"
5. En Android:
   - Ve a **Configuración → Notificaciones → Acceso a notificaciones**
   - Activa **Fyncee**

### Paso 2: Configurar Opciones

En **Detección automática** puedes configurar:

- **Confirmar antes de crear**: Si está activado, te preguntará antes de crear cada transacción
- **Crear automáticamente**: Si está desactivado, las transacciones se crean sin confirmación

### Paso 3: ¡Listo!

Una vez configurado, el servicio funcionará en segundo plano. Cada vez que recibas una notificación de tu banco:

1. Fyncee la detectará automáticamente
2. Extraerá la información (monto, comercio, tipo)
3. Sugerirá una categoría basada en el comercio
4. Te mostrará un diálogo de confirmación (si está habilitado)
5. Creará la transacción en tu registro

## 💡 Ejemplos de Uso

### Ejemplo 1: Compra en OXXO

**Notificación del Banco:**
```
BBVA
Cargo en OXXO
Monto: $45.50
```

**Fyncee detecta:**
- Monto: $45.50
- Tipo: Gasto
- Comercio: OXXO
- Categoría sugerida: Comida

**Resultado:**
✅ Transacción creada automáticamente en la categoría "Comida"

### Ejemplo 2: Pago de Netflix

**Notificación del Banco:**
```
Santander
Cargo mensual - NETFLIX
$149.00
```

**Fyncee detecta:**
- Monto: $149.00
- Tipo: Gasto
- Comercio: NETFLIX
- Categoría sugerida: Servicios

**Resultado:**
✅ Transacción creada en "Servicios"

### Ejemplo 3: Transferencia Recibida

**Notificación del Banco:**
```
Banorte
Transferencia recibida
Monto: $5,000.00
```

**Fyncee detecta:**
- Monto: $5,000.00
- Tipo: Ingreso
- Categoría sugerida: Otros ingresos

**Resultado:**
✅ Transacción creada como ingreso

## 🎯 Categorización Inteligente

Fyncee reconoce automáticamente estos comercios y los categoriza:

### Comida
- OXXO, 7-Eleven, McDonald's, Burger King, Pizza Hut, Starbucks

### Compras
- Walmart, Soriana, Chedraui, Amazon, Mercado Libre, Liverpool

### Transporte
- Uber, Didi, Gasolinerías, Pemex

### Servicios
- Netflix, Spotify, Disney+, HBO, Amazon Prime

### Salud
- Farmacias, Hospitales, Consultorios médicos

Si el comercio no se reconoce, se asignará a la categoría "Compras" por defecto.

## ⚠️ Limitaciones

### Patrones de Notificaciones
- Cada banco tiene su propio formato de notificaciones
- Si tu banco cambia el formato, puede que no se detecte correctamente
- Algunos bancos pueden no incluir toda la información necesaria

### Tipos de Transacciones
**Detecta:**
- ✅ Compras con tarjeta
- ✅ Retiros en cajero
- ✅ Transferencias
- ✅ Pagos de servicios

**No detecta:**
- ❌ Cargos que no generan notificación
- ❌ Transacciones muy antiguas
- ❌ Movimientos internos entre cuentas del mismo banco (depende del banco)

### Privacidad
- ⚠️ El servicio solo lee notificaciones de las apps bancarias configuradas
- ⚠️ Los datos se procesan localmente en tu dispositivo
- ⚠️ No se envía información de las notificaciones a servidores externos

## 🔧 Solución de Problemas

### El servicio no detecta notificaciones

1. **Verificar permisos**:
   - Ve a Configuración de Android
   - Busca "Acceso a notificaciones"
   - Asegúrate de que Fyncee esté activado

2. **Verificar que el banco esté en la lista**:
   - Ve a Detección automática
   - Busca tu banco en la lista de apps detectadas
   - Si no aparece, puedes solicitarlo

3. **Reiniciar el servicio**:
   - Desactiva y vuelve a activar el switch en Detección automática

### Las transacciones se crean con la categoría incorrecta

1. **Editar manualmente**:
   - Puedes editar la transacción después de creada
   - Desliza la transacción hacia la derecha

2. **Reportar el comercio**:
   - Si un comercio se categoriza mal frecuentemente
   - Puede agregarse a la lista de reconocimiento

### Se crean transacciones duplicadas

1. **Verificar notificaciones**:
   - Algunos bancos envían múltiples notificaciones para la misma transacción
   - Puedes eliminar manualmente las duplicadas

2. **Desactivar "Crear automáticamente"**:
   - Activa "Confirmar antes de crear"
   - Así puedes ignorar duplicados

## 📊 Estadísticas

Una vez activado el servicio, puedes ver:

- Número de transacciones detectadas automáticamente
- Porcentaje de precisión en la categorización
- Tiempo ahorrado vs. entrada manual

## 🔐 Privacidad y Seguridad

### Qué accede Fyncee:
- ✅ Solo notificaciones de apps bancarias configuradas
- ✅ Solo información visible en la notificación (monto, comercio)

### Qué NO accede Fyncee:
- ❌ Tus contraseñas bancarias
- ❌ Saldo de cuentas
- ❌ Números de tarjeta
- ❌ Información bancaria sensible

### Procesamiento de Datos:
- Todos los datos se procesan **localmente** en tu dispositivo
- No se envía información a servidores externos
- Solo se almacena en Supabase (tu base de datos)

## 🆕 Próximas Mejoras

- [ ] Soporte para más bancos internacionales
- [ ] Detección de meses sin intereses (MSI)
- [ ] Reconocimiento de propinas
- [ ] Análisis de patrones de gasto por comercio
- [ ] Detección de suscripciones recurrentes
- [ ] Alertas de cargos sospechosos
- [ ] Integración con Open Banking APIs

## 🤝 Contribuir

¿Tu banco no está en la lista? Puedes ayudar proporcionando:

1. Nombre de la app bancaria
2. Package name (Android) o Bundle ID (iOS)
3. Ejemplos de notificaciones (sin datos sensibles)

## 📝 Notas Técnicas

### Dependencias
- `flutter_notification_listener: ^2.1.0` - Lectura de notificaciones
- `flutter_local_notifications: ^17.2.3` - Gestión de notificaciones locales

### Servicios Creados
- `lib/services/bank_notification_service.dart` - Parseo y categorización
- `lib/services/notification_listener_service.dart` - Escucha de notificaciones
- `lib/widgets/bank_notification_dialog.dart` - UI de confirmación

### Configuración de Base de Datos
Las configuraciones se guardan en `app_settings`:
- `auto_create_bank_transactions`: BOOLEAN
- `notify_before_creating`: BOOLEAN
- `default_bank_category_id`: INTEGER

## ❓ Preguntas Frecuentes

**¿Funciona en iOS?**
No, iOS no permite el acceso a notificaciones de otras apps.

**¿Consume mucha batería?**
No, el servicio funciona de forma pasiva y solo se activa cuando llega una notificación.

**¿Puedo desactivarlo temporalmente?**
Sí, solo desactiva el switch en Detección automática.

**¿Se sincroniza entre dispositivos?**
Sí, las transacciones creadas se sincronizan con Supabase.

**¿Qué pasa si no tengo internet?**
Las transacciones se guardan localmente y se sincronizan cuando haya conexión.
