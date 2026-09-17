-- LowVolt Pilot core account/data model.
-- Run once in the Supabase SQL editor for the LowVolt Pilot project.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text not null default 'personal'
    check (kind in ('personal', 'company')),
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workspace_members (
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member'
    check (role in ('owner', 'admin', 'member', 'viewer')),
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create or replace function public.is_workspace_member(target_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.workspace_members wm
    where wm.workspace_id = target_workspace_id
      and wm.user_id = auth.uid()
  );
$$;

revoke all on function public.is_workspace_member(uuid) from public;
grant execute on function public.is_workspace_member(uuid) to authenticated;

create table if not exists public.sites (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  name text not null,
  address text,
  notes text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  site_id uuid references public.sites(id) on delete set null,
  title text not null,
  customer_name text,
  system_type text,
  status text not null default 'active'
    check (status in ('draft', 'active', 'complete', 'archived')),
  notes text,
  created_by uuid not null references auth.users(id),
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.system_designs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  site_id uuid references public.sites(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  name text not null,
  system_type text not null,
  design_data jsonb not null default '{}'::jsonb,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.devices (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  site_id uuid references public.sites(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  name text,
  device_type text not null,
  manufacturer text,
  model text,
  ip_address inet,
  mac_address macaddr,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_events (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  event_type text not null,
  event_data jsonb not null default '{}'::jsonb,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null
    references public.workspaces(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  name text not null,
  storage_path text,
  report_data jsonb not null default '{}'::jsonb,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

-- Server-maintained product access. This is intentionally generic so a
-- future ServiceTechIQ plan can grant LowVolt Pilot companion access.
create table if not exists public.entitlements (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_key text not null,
  tier text not null,
  status text not null
    check (status in ('active', 'trialing', 'grace', 'expired', 'revoked')),
  source text not null,
  expires_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, product_key)
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_workspace_id uuid;
  new_display_name text;
begin
  new_display_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'display_name', ''),
    split_part(coalesce(new.email, 'Technician'), '@', 1)
  );

  insert into public.profiles (id, display_name)
  values (new.id, new_display_name)
  on conflict (id) do nothing;

  insert into public.workspaces (name, kind, created_by)
  values ('My Workspace', 'personal', new.id)
  returning id into new_workspace_id;

  insert into public.workspace_members (workspace_id, user_id, role)
  values (new_workspace_id, new.id, 'owner');

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.sites enable row level security;
alter table public.jobs enable row level security;
alter table public.system_designs enable row level security;
alter table public.devices enable row level security;
alter table public.job_events enable row level security;
alter table public.reports enable row level security;
alter table public.entitlements enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "workspaces_select_member" on public.workspaces;
create policy "workspaces_select_member"
on public.workspaces for select
to authenticated
using (public.is_workspace_member(id));

drop policy if exists "workspace_members_select_member" on public.workspace_members;
create policy "workspace_members_select_member"
on public.workspace_members for select
to authenticated
using (public.is_workspace_member(workspace_id));

drop policy if exists "sites_member_all" on public.sites;
create policy "sites_member_all"
on public.sites for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (
  public.is_workspace_member(workspace_id)
  and created_by = auth.uid()
);

drop policy if exists "jobs_member_all" on public.jobs;
create policy "jobs_member_all"
on public.jobs for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (
  public.is_workspace_member(workspace_id)
  and created_by = auth.uid()
);

drop policy if exists "designs_member_all" on public.system_designs;
create policy "designs_member_all"
on public.system_designs for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (
  public.is_workspace_member(workspace_id)
  and created_by = auth.uid()
);

drop policy if exists "devices_member_all" on public.devices;
create policy "devices_member_all"
on public.devices for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (
  public.is_workspace_member(workspace_id)
  and created_by = auth.uid()
);

drop policy if exists "job_events_member_all" on public.job_events;
create policy "job_events_member_all"
on public.job_events for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (
  public.is_workspace_member(workspace_id)
  and created_by = auth.uid()
);

drop policy if exists "reports_member_all" on public.reports;
create policy "reports_member_all"
on public.reports for all
to authenticated
using (public.is_workspace_member(workspace_id))
with check (
  public.is_workspace_member(workspace_id)
  and created_by = auth.uid()
);

drop policy if exists "entitlements_select_own" on public.entitlements;
create policy "entitlements_select_own"
on public.entitlements for select
to authenticated
using (user_id = auth.uid());

grant select, update on public.profiles to authenticated;
grant select on public.workspaces, public.workspace_members to authenticated;
grant select, insert, update, delete
  on public.sites, public.jobs, public.system_designs, public.devices,
     public.job_events, public.reports
  to authenticated;
grant select on public.entitlements to authenticated;
