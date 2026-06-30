-- Migración: campos de vuelo en budget_items
-- Pegar y ejecutar en el SQL Editor de Supabase (proyecto bon-voyage).

ALTER TABLE budget_items
  ADD COLUMN IF NOT EXISTS flight_origin      text,
  ADD COLUMN IF NOT EXISTS flight_destination text,
  ADD COLUMN IF NOT EXISTS flight_departure   text,
  ADD COLUMN IF NOT EXISTS flight_arrival     text,
  ADD COLUMN IF NOT EXISTS flight_layover     text;
