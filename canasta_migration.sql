-- Migración: tabla canasta_profiles (para unificar La Canasta con Bon Voyage)
-- Pegar y ejecutar en el SQL Editor de Supabase (proyecto bon-voyage).

CREATE TABLE IF NOT EXISTS canasta_profiles (
  user_id    uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  data       jsonb       NOT NULL DEFAULT '{}',
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE canasta_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "own canasta profile" ON canasta_profiles
  FOR ALL USING (auth.uid() = user_id);
