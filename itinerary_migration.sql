-- Migración: Itinerario + categorías transporte y seguros
-- Pegar y ejecutar en el SQL Editor de Supabase (proyecto bon-voyage).

-- 1. Agregar categorías transporte y seguros a budget_items
ALTER TABLE budget_items DROP CONSTRAINT IF EXISTS budget_items_category_check;
ALTER TABLE budget_items ADD CONSTRAINT budget_items_category_check
  CHECK (category IN ('flights','lodging','food','visits','transport','insurance'));

-- 2. Tabla de eventos del itinerario
CREATE TABLE IF NOT EXISTS itinerary_events (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id     uuid        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  title       text        NOT NULL,
  event_date  date        NOT NULL,
  start_time  time,
  end_time    time,
  location    text,
  notes       text,
  allow_edit  boolean     NOT NULL DEFAULT false,
  created_by  uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE itinerary_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "trip members view events" ON itinerary_events FOR SELECT USING (
  public.is_trip_member(itinerary_events.trip_id, auth.uid())
);
CREATE POLICY "trip members create events" ON itinerary_events FOR INSERT WITH CHECK (
  auth.uid() = created_by AND public.is_trip_member(itinerary_events.trip_id, auth.uid())
);
CREATE POLICY "edit itinerary event" ON itinerary_events FOR UPDATE USING (
  auth.uid() = created_by
  OR (allow_edit = true AND public.is_trip_member(itinerary_events.trip_id, auth.uid()))
);
CREATE POLICY "delete itinerary event" ON itinerary_events FOR DELETE USING (
  auth.uid() = created_by
);

-- 3. Vincular gastos a eventos (columna nullable — no rompe datos existentes)
ALTER TABLE budget_items ADD COLUMN IF NOT EXISTS event_id uuid REFERENCES itinerary_events(id) ON DELETE SET NULL;
