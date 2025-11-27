-- Crear tabla de configuración de la app
CREATE TABLE IF NOT EXISTS app_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  carry_over_balance BOOLEAN DEFAULT FALSE,
  reset_budgets_monthly BOOLEAN DEFAULT TRUE,
  default_period TEXT DEFAULT 'current_month',
  show_budget_notifications BOOLEAN DEFAULT TRUE,
  group_transactions_by_date BOOLEAN DEFAULT TRUE,
  currency TEXT DEFAULT 'MXN',
  date_format TEXT DEFAULT 'dd/MM/yyyy',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si las hay (para evitar conflictos)
DROP POLICY IF EXISTS "Users can view own settings" ON app_settings;
DROP POLICY IF EXISTS "Users can insert own settings" ON app_settings;
DROP POLICY IF EXISTS "Users can update own settings" ON app_settings;

-- Política: Los usuarios solo pueden ver sus propias configuraciones
CREATE POLICY "Users can view own settings"
  ON app_settings
  FOR SELECT
  USING (auth.uid() = user_id);

-- Política: Los usuarios solo pueden insertar sus propias configuraciones
CREATE POLICY "Users can insert own settings"
  ON app_settings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Política: Los usuarios solo pueden actualizar sus propias configuraciones
CREATE POLICY "Users can update own settings"
  ON app_settings
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_app_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS app_settings_updated_at ON app_settings;

-- Trigger para actualizar updated_at
CREATE TRIGGER app_settings_updated_at
  BEFORE UPDATE ON app_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_app_settings_updated_at();

-- Insertar configuración por defecto para usuarios existentes (opcional)
-- INSERT INTO app_settings (user_id)
-- SELECT id FROM auth.users
-- ON CONFLICT (user_id) DO NOTHING;
