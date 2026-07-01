-- Migración: sistema de contribuciones a gastos compartidos
CREATE TABLE IF NOT EXISTS expense_contributions (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id        uuid        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  item_id        uuid        NOT NULL REFERENCES budget_items(id) ON DELETE CASCADE,
  payer_id       uuid        NOT NULL REFERENCES auth.users(id),
  contributor_id uuid        NOT NULL REFERENCES auth.users(id),
  amount_owed    numeric     NOT NULL,
  currency       text        NOT NULL,
  description    text,
  status         text        NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid')),
  created_at     timestamptz DEFAULT now()
);
ALTER TABLE expense_contributions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "trip members view contributions" ON expense_contributions FOR SELECT
  USING (contributor_id = auth.uid() OR payer_id = auth.uid() OR public.is_trip_member(trip_id, auth.uid()));
CREATE POLICY "payer creates contribution" ON expense_contributions FOR INSERT
  WITH CHECK (auth.uid() = payer_id AND public.is_trip_member(trip_id, auth.uid()));
CREATE POLICY "payer or contributor updates" ON expense_contributions FOR UPDATE
  USING (auth.uid() = contributor_id OR auth.uid() = payer_id);
CREATE POLICY "payer deletes contribution" ON expense_contributions FOR DELETE
  USING (auth.uid() = payer_id);
