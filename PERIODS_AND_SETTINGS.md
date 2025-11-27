# Sistema de Períodos y Configuración - Fyncee v2.3

## 📅 Nuevas Funcionalidades

### 1. Selector de Períodos
- **Ubicación**: Vista principal (Home)
- **Períodos disponibles**:
  - Este mes (actual)
  - Mes anterior
  - Últimos 3 meses
  - Últimos 6 meses
  - Este año
  - Todo el tiempo
  - Personalizado (próximamente)

- **Navegación**:
  - Botones ⬅️ ➡️ para navegar entre meses
  - Tap en el período actual para abrir el selector completo
  - Cambio automático de mes cuando inicia uno nuevo

### 2. Configuración de la App
- **Ubicación**: Perfil → Ajustes

#### Configuraciones de Balance
- ✅ **Continuar con saldo del mes anterior**
  - Cuando está activado: El saldo final del mes anterior se suma al mes actual
  - Cuando está desactivado: Cada mes empieza en $0
  - Útil para: Llevar control mensual vs. control acumulado

#### Configuraciones de Presupuestos
- ✅ **Reiniciar presupuestos cada mes**
  - Activado: Los presupuestos se reinician el día 1 de cada mes
  - Desactivado: Los presupuestos son anuales

- ✅ **Notificaciones de presupuesto**
  - Recibe alertas cuando:
    - Alcances el 80% del presupuesto (⚠️ advertencia)
    - Superes el 100% del presupuesto (❌ superado)

#### Configuraciones de Visualización
- ✅ **Agrupar transacciones por fecha**
  - Organiza los movimientos por día en la vista de Movimientos

- ✅ **Período predeterminado**
  - Selecciona qué período ver al abrir la app
  - Opciones: Mes actual, Mes anterior, Año actual, Todo

#### Configuraciones Regionales
- ✅ **Moneda**
  - MXN (Peso Mexicano) - por defecto
  - USD (Dólar)
  - EUR (Euro)

### 3. Cálculo de Balance
El balance ahora considera:
```
Balance Total = (Ingresos - Gastos del período) + Saldo arrastrado
```

- Si "Continuar con saldo" está **ACTIVADO**:
  - El saldo del mes anterior se suma automáticamente
  - Ejemplo: Si terminaste noviembre con $5,000, ese monto aparece en diciembre

- Si "Continuar con saldo" está **DESACTIVADO**:
  - Cada período empieza en $0
  - Solo muestra ingresos - gastos del período seleccionado

## 🗄️ Base de Datos

### Nueva Tabla: `app_settings`
Ejecuta el script `SETUP_APP_SETTINGS.sql` en Supabase:

```sql
-- Ver script completo en SETUP_APP_SETTINGS.sql
```

Columnas:
- `user_id`: UUID (Primary Key, FK a auth.users)
- `carry_over_balance`: BOOLEAN (continuar con saldo)
- `reset_budgets_monthly`: BOOLEAN (reiniciar presupuestos)
- `default_period`: TEXT (período por defecto)
- `show_budget_notifications`: BOOLEAN (mostrar notificaciones)
- `group_transactions_by_date`: BOOLEAN (agrupar por fecha)
- `currency`: TEXT (moneda)
- `date_format`: TEXT (formato de fecha)

## 🎯 Casos de Uso

### Ejemplo 1: Control Mensual Estricto
**Configuración**:
- ❌ Continuar con saldo del mes anterior
- ✅ Reiniciar presupuestos cada mes
- ✅ Notificaciones de presupuesto
- Período por defecto: "Mes actual"

**Resultado**: Cada mes empieza en $0, puedes ver cuánto gastaste/ganaste ese mes específicamente.

### Ejemplo 2: Control Acumulado
**Configuración**:
- ✅ Continuar con saldo del mes anterior
- ❌ Reiniciar presupuestos cada mes
- ✅ Notificaciones de presupuesto
- Período por defecto: "Todo el tiempo"

**Resultado**: El saldo se acumula mes a mes, los presupuestos son anuales.

### Ejemplo 3: Análisis Histórico
**Configuración**:
- ❌ Continuar con saldo del mes anterior
- ✅ Reiniciar presupuestos cada mes
- Período por defecto: "Últimos 6 meses"

**Resultado**: Puedes analizar tendencias sin que el saldo anterior afecte las métricas.

## 📱 Uso en la App

### Cambiar de Período
1. En Home, verás el selector de período debajo del header
2. Usa ⬅️ ➡️ para navegar entre meses
3. O toca el período actual para ver todas las opciones

### Configurar Preferencias
1. Ve a **Perfil** (ícono de persona en la barra inferior)
2. Toca **Ajustes**
3. Ajusta las configuraciones según tus necesidades
4. Los cambios se guardan automáticamente

### Ver Balance con/sin Arrastre
- El balance mostrado en Home considera automáticamente la configuración
- Si tienes dudas, desactiva "Continuar con saldo" y verás solo el período actual

## 🔄 Sincronización

Las configuraciones se guardan en Supabase y se sincronizan automáticamente entre dispositivos.

## 🚀 Próximas Mejoras (v2.4)

- [ ] Período personalizado (seleccionar fechas manualmente)
- [ ] Exportar datos por período
- [ ] Comparar períodos (ej: noviembre vs octubre)
- [ ] Gráficas de tendencias por período
- [ ] Presupuestos con fechas personalizadas
- [ ] Recordatorios de fin de mes
- [ ] Metas vinculadas a períodos específicos

## 🐛 Solución de Problemas

**El balance no se actualiza al cambiar de período**
- Asegúrate de que hayas ejecutado `SETUP_APP_SETTINGS.sql`
- Verifica que la tabla `app_settings` existe en Supabase

**No veo la opción de Ajustes en Perfil**
- Haz hot reload (`r` en la terminal de Flutter)
- Verifica que importaste `settings_screen.dart`

**El saldo arrastrado no aparece**
- Activa "Continuar con saldo del mes anterior" en Ajustes
- Regresa a Home y verifica el balance

## 📝 Notas Técnicas

### Modelos Nuevos
- `lib/models/app_settings.dart`: Configuración de la app
- `lib/models/date_period.dart`: Períodos de fecha

### Servicios Actualizados
- `SupabaseService.getAppSettings()`: Obtener configuración
- `SupabaseService.saveAppSettings()`: Guardar configuración
- `SupabaseService.getCarryOverBalance()`: Calcular saldo anterior
- `SupabaseService.getTransactionsByDateRange()`: Ya existía, ahora se usa con períodos

### UI Actualizada
- `HomePage._buildPeriodSelector()`: Selector de períodos
- `HomePage._showPeriodPicker()`: Modal de selección
- `SettingsScreen`: Nueva pantalla completa de configuración
