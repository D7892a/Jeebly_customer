-- Mansouriya module: isolated from existing Jeebly tables.
create extension if not exists pgcrypto;
create table if not exists public.mans_admins (user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz not null default now());
create or replace function public.mans_is_admin() returns boolean language sql stable security definer set search_path = '' as $$ select exists(select 1 from public.mans_admins where user_id = (select auth.uid())) $$;
revoke all on function public.mans_is_admin() from public;
grant execute on function public.mans_is_admin() to authenticated, anon;
create table if not exists public.mans_teams (id uuid primary key default gen_random_uuid(), name text not null unique check(length(trim(name)) between 2 and 100), logo_url text, description text, created_at timestamptz not null default now());
create table if not exists public.mans_tournaments (id uuid primary key default gen_random_uuid(), name text not null, kind text not null default 'league' check(kind in ('league','cup')), season text, status text not null default 'upcoming' check(status in ('upcoming','active','completed')), created_at timestamptz not null default now());
create table if not exists public.mans_tournament_teams (tournament_id uuid not null references public.mans_tournaments(id) on delete cascade, team_id uuid not null references public.mans_teams(id) on delete cascade, primary key(tournament_id,team_id));
create table if not exists public.mans_matches (id uuid primary key default gen_random_uuid(), tournament_id uuid references public.mans_tournaments(id) on delete set null, home_team_id uuid not null references public.mans_teams(id) on delete restrict, away_team_id uuid not null references public.mans_teams(id) on delete restrict, match_type text not null default 'league', venue text, kickoff timestamptz not null, status text not null default 'scheduled' check(status in ('scheduled','live','finished','postponed','cancelled')), home_score int check(home_score>=0), away_score int check(away_score>=0), created_at timestamptz not null default now(), constraint mans_distinct_teams check(home_team_id<>away_team_id), constraint mans_finished_scores check(status <> 'finished' or (home_score is not null and away_score is not null)));
create index if not exists mans_matches_kickoff_idx on public.mans_matches(kickoff);
create index if not exists mans_matches_tournament_idx on public.mans_matches(tournament_id);
create index if not exists mans_matches_home_idx on public.mans_matches(home_team_id);
create index if not exists mans_matches_away_idx on public.mans_matches(away_team_id);
-- Read access for public, all modifications only authorized association admins.
do $$ declare t text; begin foreach t in array array['mans_admins','mans_teams','mans_tournaments','mans_tournament_teams','mans_matches'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
drop policy if exists mans_admin_read on public.mans_admins;
create policy mans_admin_read on public.mans_admins for select to authenticated using (user_id=(select auth.uid()));
-- Membership is assigned only through privileged SQL/dashboard, never from browser.
do $$ declare t text; begin foreach t in array array['mans_teams','mans_tournaments','mans_tournament_teams','mans_matches'] loop
 execute format('drop policy if exists mans_public_read on public.%I',t);
 execute format('create policy mans_public_read on public.%I for select to anon, authenticated using (true)',t);
 execute format('drop policy if exists mans_admin_insert on public.%I',t);
 execute format('create policy mans_admin_insert on public.%I for insert to authenticated with check (public.mans_is_admin())',t);
 execute format('drop policy if exists mans_admin_update on public.%I',t);
 execute format('create policy mans_admin_update on public.%I for update to authenticated using (public.mans_is_admin()) with check (public.mans_is_admin())',t);
 execute format('drop policy if exists mans_admin_delete on public.%I',t);
 execute format('create policy mans_admin_delete on public.%I for delete to authenticated using (public.mans_is_admin())',t);
 end loop; end $$;
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types) values ('mans-team-logos','mans-team-logos',true,2097152,array['image/jpeg','image/png','image/webp']) on conflict(id) do update set public=true,file_size_limit=2097152,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists mans_logos_read on storage.objects;
create policy mans_logos_read on storage.objects for select to anon,authenticated using(bucket_id='mans-team-logos');
drop policy if exists mans_logos_insert on storage.objects;
create policy mans_logos_insert on storage.objects for insert to authenticated with check(bucket_id='mans-team-logos' and public.mans_is_admin());
drop policy if exists mans_logos_update on storage.objects;
create policy mans_logos_update on storage.objects for update to authenticated using(bucket_id='mans-team-logos' and public.mans_is_admin()) with check(bucket_id='mans-team-logos' and public.mans_is_admin());
drop policy if exists mans_logos_delete on storage.objects;
create policy mans_logos_delete on storage.objects for delete to authenticated using(bucket_id='mans-team-logos' and public.mans_is_admin());
-- Add the administrator AFTER signing up through Supabase Auth (SQL editor, privileged role):
-- insert into public.mans_admins(user_id) select id from auth.users where email = 'YOUR_ADMIN_EMAIL' on conflict do nothing;
-- Enable Realtime for these mans_ tables in Supabase Dashboard > Database > Publications > supabase_realtime.
