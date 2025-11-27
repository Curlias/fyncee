-- Agregar columna 'read' a la tabla notifications si no existe
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'read'
  ) THEN
    ALTER TABLE notifications ADD COLUMN read BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Agregar columna 'budget_id' a la tabla notifications si no existe (para futuro uso)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'budget_id'
  ) THEN
    ALTER TABLE notifications ADD COLUMN budget_id INTEGER REFERENCES budgets(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Eliminar el constraint antiguo de type si existe
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'notifications_type_check' AND table_name = 'notifications'
  ) THEN
    ALTER TABLE notifications DROP CONSTRAINT notifications_type_check;
  END IF;
END $$;

-- Crear nuevo constraint que permita budget_exceeded y budget_warning
ALTER TABLE notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN ('info', 'warning', 'error', 'success', 'budget_warning', 'budget_exceeded'));
