-- Migración: agregar fecha de nacimiento al perfil
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS date_of_birth date;
