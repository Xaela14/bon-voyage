-- Migración: solicitudes de gastos compartidos
-- Pegar y ejecutar en el SQL Editor de Supabase (proyecto bon-voyage).

CREATE TABLE IF NOT EXISTS expense_share_requests (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id        uuid        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  budget_item_id uuid        NOT NULL REFERENCES budget_items(id) ON DELETE CASCADE,
  from_user_id   uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status         text        NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at     timestamptz DEFAULT now()
);

ALTER TABLE expense_share_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "view own requests" ON expense_share_requests FOR SELECT USING (
  auth.uid() = from_user_id OR auth.uid() = to_user_id
);
CREATE POLICY "create share request" ON expense_share_requests FOR INSERT WITH CHECK (
  auth.uid() = from_user_id AND public.is_trip_member(trip_id, auth.uid())
);
CREATE POLICY "respond to request" ON expense_share_requests FOR UPDATE USING (
  auth.uid() = to_user_id
);
CREATE POLICY "cancel own request" ON expense_share_requests FOR DELETE USING (
  auth.uid() = from_user_id
);
