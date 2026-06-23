-- Arreglo de la recursión infinita en las políticas de seguridad.
-- Pegar y ejecutar esto en el SQL Editor de Supabase (proyecto bon-voyage).

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

drop policy if exists "trip members can view" on trips;
create policy "trip members can view" on trips for select using (
  auth.uid() = created_by or public.is_trip_member(trips.id, auth.uid())
);

drop policy if exists "members manage countries" on trip_countries;
create policy "members manage countries" on trip_countries for all using (
  public.is_trip_member(trip_countries.trip_id, auth.uid())
);

drop policy if exists "view members of own trips" on trip_members;
create policy "view members of own trips" on trip_members for select using (
  public.is_trip_member(trip_members.trip_id, auth.uid())
);

drop policy if exists "view budget items" on budget_items;
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

drop policy if exists "insert own budget items" on budget_items;
create policy "insert own budget items" on budget_items for insert with check (
  auth.uid() = created_by and public.is_trip_member(budget_items.trip_id, auth.uid())
);
