-- Migración: integración Bon Voyage ↔ La Canasta
-- Pegar y ejecutar en el SQL Editor de Supabase (proyecto bon-voyage).

-- 1. Tabla para vincular cada viaje de Bon Voyage con un presupuesto de La Canasta
CREATE TABLE IF NOT EXISTS canasta_trip_links (
  user_id           uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  trip_id           uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  canasta_trip_code text NOT NULL,
  PRIMARY KEY (user_id, trip_id)
);
ALTER TABLE canasta_trip_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own canasta trip link" ON canasta_trip_links
  FOR ALL USING (auth.uid() = user_id);

-- 2. Fuente de pago en gastos
ALTER TABLE budget_items
  ADD COLUMN IF NOT EXISTS payment_source text
    CHECK (payment_source IN ('disponible','ahorros','tarjeta'));

-- 3. Soporte de subsidio (A paga por B)
ALTER TABLE budget_items
  ADD COLUMN IF NOT EXISTS amount_consumed numeric;  -- consumo real de la persona (puede diferir de amount)
ALTER TABLE budget_items
  ADD COLUMN IF NOT EXISTS subsidy_from uuid REFERENCES auth.users(id);  -- quién pagó por este ítem
