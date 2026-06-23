-- Bon Voyage — esquema inicial para Supabase
-- Pegar y ejecutar en el SQL Editor del proyecto Supabase (gratis).

-- Perfil público de cada usuario (separado de auth.users)
create table profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz default now()
);

-- Vínculo opcional con una cuenta de La Canasta (solo guarda la intención/email, no cruza proyectos automáticamente)
create table canasta_links (
  user_id uuid primary key references auth.users(id) on delete cascade,
  canasta_email text not null,
  linked_at timestamptz default now()
);

-- Un viaje
create table trips (
  id uuid primary key default gen_random_uuid(),
  code char(5) not null unique,
  name text not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

-- Países incluidos en un viaje (un viaje puede tener varios)
create table trip_countries (
  trip_id uuid not null references trips(id) on delete cascade,
  country_code char(2) not null,
  primary key (trip_id, country_code)
);

-- Miembros de un viaje
create table trip_members (
  trip_id uuid not null references trips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  share_budget boolean not null default false, -- si comparte su presupuesto personal con los demás
  joined_at timestamptz default now(),
  primary key (trip_id, user_id)
);

-- Ítems de presupuesto: si member_id es null, es presupuesto común del viaje
create table budget_items (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id) on delete cascade,
  member_id uuid references auth.users(id) on delete cascade, -- null = presupuesto común
  category text not null check (category in ('flights','lodging','food','visits')),
  description text,
  amount numeric(12,2) not null,
  currency char(3) not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

-- ===== ROW LEVEL SECURITY =====
alter table profiles enable row level security;
alter table canasta_links enable row level security;
alter table trips enable row level security;
alter table trip_countries enable row level security;
alter table trip_members enable row level security;
alter table budget_items enable row level security;

-- Función auxiliar: verifica membresía sin pasar por RLS de trip_members,
-- para evitar que las políticas de trip_members se llamen a sí mismas (recursión infinita).
create or replace function public.is_trip_member(p_trip_id uuid, p_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from trip_members tm where tm.trip_id = p_trip_id and tm.user_id = p_user_id
  );
$$;

-- profiles: cada uno ve/edita el suyo
create policy "own profile" on profiles for all using (auth.uid() = user_id);

-- canasta_links: cada uno ve/edita el suyo
create policy "own canasta link" on canasta_links for all using (auth.uid() = user_id);

-- trips: visibles para quien sea miembro o el creador; insertable por cualquier usuario autenticado
create policy "trip members can view" on trips for select using (
  auth.uid() = created_by or public.is_trip_member(trips.id, auth.uid())
);
create policy "any authed user can create trip" on trips for insert with check (auth.uid() = created_by);

-- trip_countries: visible/editable por miembros del viaje
create policy "members manage countries" on trip_countries for all using (
  public.is_trip_member(trip_countries.trip_id, auth.uid())
);

-- trip_members: un usuario puede unirse (insertar su propia fila) y ver a los demás miembros del mismo viaje
create policy "view members of own trips" on trip_members for select using (
  public.is_trip_member(trip_members.trip_id, auth.uid())
);
create policy "join trip as self" on trip_members for insert with check (auth.uid() = user_id);
create policy "update own membership" on trip_members for update using (auth.uid() = user_id);

-- budget_items: presupuesto común visible para todos los miembros; presupuesto personal visible solo
-- para el dueño, salvo que haya activado share_budget
create policy "view budget items" on budget_items for select using (
  public.is_trip_member(budget_items.trip_id, auth.uid())
  and (
    member_id is null
    or member_id = auth.uid()
    or exists (
      select 1 from trip_members tm2 where tm2.trip_id = budget_items.trip_id
        and tm2.user_id = budget_items.member_id and tm2.share_budget = true
    )
  )
);
create policy "insert own budget items" on budget_items for insert with check (
  auth.uid() = created_by and public.is_trip_member(budget_items.trip_id, auth.uid())
);
create policy "update own budget items" on budget_items for update using (auth.uid() = created_by);
create policy "delete own budget items" on budget_items for delete using (auth.uid() = created_by);
