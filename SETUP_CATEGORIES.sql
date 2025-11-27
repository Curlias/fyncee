-- ============================================
-- SETUP DE CATEGORÍAS GLOBALES Y PERSONALIZADAS
-- ============================================

-- 1. Crear tabla para categorías ocultas por usuario
CREATE TABLE IF NOT EXISTS user_hidden_categories (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  hidden_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, category_id)
);

-- 2. Habilitar RLS en user_hidden_categories
ALTER TABLE user_hidden_categories ENABLE ROW LEVEL SECURITY;

-- 3. Políticas RLS para user_hidden_categories
DROP POLICY IF EXISTS "Users can view their own hidden categories" ON user_hidden_categories;
CREATE POLICY "Users can view their own hidden categories"
  ON user_hidden_categories FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can hide categories" ON user_hidden_categories;
CREATE POLICY "Users can hide categories"
  ON user_hidden_categories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unhide categories" ON user_hidden_categories;
CREATE POLICY "Users can unhide categories"
  ON user_hidden_categories FOR DELETE
  USING (auth.uid() = user_id);

-- 4. Actualizar políticas RLS de categories para permitir lectura global
DROP POLICY IF EXISTS "Users can view all categories" ON categories;
CREATE POLICY "Users can view all categories"
  ON categories FOR SELECT
  USING (
    user_id IS NULL OR  -- Categorías globales
    auth.uid() = user_id  -- Categorías personalizadas del usuario
  );

DROP POLICY IF EXISTS "Users can create personal categories" ON categories;
CREATE POLICY "Users can create personal categories"
  ON categories FOR INSERT
  WITH CHECK (auth.uid() = user_id AND is_default = false);

DROP POLICY IF EXISTS "Users can update their own categories" ON categories;
CREATE POLICY "Users can update their own categories"
  ON categories FOR UPDATE
  USING (auth.uid() = user_id AND is_default = false);

DROP POLICY IF EXISTS "Users can delete their own categories" ON categories;
CREATE POLICY "Users can delete their own categories"
  ON categories FOR DELETE
  USING (auth.uid() = user_id AND is_default = false);

-- 5. Agregar columna 'icon' si no existe y migrar datos de 'emoji'
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'icon'
  ) THEN
    -- Agregar nueva columna 'icon'
    ALTER TABLE categories ADD COLUMN icon TEXT;
    
    -- Migrar datos de emoji a icon (si emoji existe)
    UPDATE categories SET icon = emoji WHERE emoji IS NOT NULL;
  END IF;
END $$;

-- 5b. Cambiar color_value de INTEGER a BIGINT
ALTER TABLE categories ALTER COLUMN color_value TYPE BIGINT;

-- 5c. Permitir que user_id sea NULL para categorías globales
ALTER TABLE categories ALTER COLUMN user_id DROP NOT NULL;


-- 6. Limpiar categorías duplicadas (mantener solo globales)
-- IMPORTANTE: Ejecutar solo una vez. Esto eliminará categorías con user_id
-- Si tienes datos importantes, haz backup antes!
DELETE FROM categories WHERE user_id IS NOT NULL;

-- 7. Insertar categorías globales de ingresos
INSERT INTO categories (user_id, name, type, emoji, icon, color_value, is_default) VALUES
  (NULL, 'Salario', 'ingreso', '💰', 'account_balance_wallet', 4288423856::bigint, true),
  (NULL, 'Inversiones', 'ingreso', '📈', 'trending_up', 4283215151::bigint, true),
  (NULL, 'Ventas', 'ingreso', '🏷️', 'sell', 4287074920::bigint, true),
  (NULL, 'Freelance', 'ingreso', '💻', 'computer', 4284513675::bigint, true),
  (NULL, 'Bonos', 'ingreso', '🎁', 'card_giftcard', 4294940672::bigint, true),
  (NULL, 'Otros ingresos', 'ingreso', '💵', 'attach_money', 4291681200::bigint, true)
ON CONFLICT DO NOTHING;

-- 8. Insertar categorías globales de egresos
INSERT INTO categories (user_id, name, type, emoji, icon, color_value, is_default) VALUES
  (NULL, 'Comida', 'egreso', '🍔', 'restaurant', 4294940928::bigint, true),
  (NULL, 'Transporte', 'egreso', '🚗', 'directions_car', 4286611584::bigint, true),
  (NULL, 'Entretenimiento', 'egreso', '🎬', 'movie', 4293664223::bigint, true),
  (NULL, 'Compras', 'egreso', '🛍️', 'shopping_bag', 4294923728::bigint, true),
  (NULL, 'Salud', 'egreso', '🏥', 'local_hospital', 4294924066::bigint, true),
  (NULL, 'Educación', 'egreso', '🎓', 'school', 4289200810::bigint, true),
  (NULL, 'Servicios', 'egreso', '🔧', 'build', 4287349578::bigint, true),
  (NULL, 'Vivienda', 'egreso', '🏠', 'home', 4294925312::bigint, true),
  (NULL, 'Otros gastos', 'egreso', '📋', 'more_horiz', 4290494208::bigint, true)
ON CONFLICT DO NOTHING;

-- 9. Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_user_hidden_categories_user ON user_hidden_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_user_hidden_categories_category ON user_hidden_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_is_default ON categories(is_default);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Contar categorías globales
SELECT COUNT(*) as global_categories FROM categories WHERE user_id IS NULL AND is_default = true;

-- Ver todas las categorías globales
SELECT id, name, type, emoji, icon, is_default FROM categories WHERE user_id IS NULL ORDER BY type, name;
