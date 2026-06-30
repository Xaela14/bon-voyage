-- Migración: campos adicionales de gastos, vuelos, solicitudes de pago y eliminar viajes
-- Pegar y ejecutar en el SQL Editor de Supabase (proyecto bon-voyage).

-- 1. Fecha real del gasto (independiente de cuando se registra)
ALTER TABLE budget_items ADD COLUMN IF NOT EXISTS expense_date date;

-- 2. Número de vuelo
ALTER TABLE budget_items ADD COLUMN IF NOT EXISTS flight_number text;

-- 3. Compartir información del vuelo con todos los viajeros del grupo
ALTER TABLE budget_items ADD COLUMN IF NOT EXISTS share_flight_info boolean DEFAULT false;

-- 4. Tabla de solicitudes de pago (alguien más pagó por mí)
CREATE TABLE IF NOT EXISTS payment_cover_requests (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id      uuid        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  item_id      uuid        NOT NULL REFERENCES budget_items(id) ON DELETE CASCADE,
  from_user_id uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id   uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount       numeric,
  currency     text,
  status       text        NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at   timestamptz DEFAULT now()
);
ALTER TABLE payment_cover_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "view own cover requests" ON payment_cover_requests FOR SELECT
  USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);
CREATE POLICY "create cover request" ON payment_cover_requests FOR INSERT
  WITH CHECK (auth.uid() = from_user_id AND public.is_trip_member(trip_id, auth.uid()));
CREATE POLICY "respond to cover request" ON payment_cover_requests FOR UPDATE
  USING (auth.uid() = to_user_id);
CREATE POLICY "cancel cover request" ON payment_cover_requests FOR DELETE
  USING (auth.uid() = from_user_id);

-- 5. Permitir al pagador actualizar el monto del gasto al aceptar la solicitud
CREATE POLICY "cover payer can set amount" ON budget_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM payment_cover_requests
      WHERE item_id = budget_items.id AND to_user_id = auth.uid() AND status = 'pending'
    )
  );

-- 6. Permitir eliminar viajes al creador
CREATE POLICY "creator can delete trip" ON trips FOR DELETE USING (auth.uid() = created_by);
