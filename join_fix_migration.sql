-- Fix: permitir buscar viaje por código para poder unirse
-- El RLS bloqueaba la búsqueda porque el usuario aún no es miembro.
-- Esta función bypasea RLS solo para lookup por código.

CREATE OR REPLACE FUNCTION public.find_trip_by_code(p_code text)
RETURNS TABLE(id uuid, name text, code char(5), created_by uuid, created_at timestamptz)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, name, code, created_by, created_at
  FROM trips
  WHERE code = p_code
  LIMIT 1;
$$;
