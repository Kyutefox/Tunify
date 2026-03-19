-- =============================================================================
-- Migration: Add user_followed_artists and user_followed_albums tables
-- Run this in the Supabase SQL Editor for existing databases.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Followed artists (one row per followed artist)
-- -----------------------------------------------------------------------------
create table if not exists public.user_followed_artists (
  user_id uuid not null,
  artist_id text not null,
  name text not null default '',
  thumbnail_url text not null default '',
  browse_id text,
  followed_at timestamptz not null default now(),
  primary key (user_id, artist_id),
  foreign key (user_id) references auth.users (id) on delete cascade
);

create index if not exists idx_user_followed_artists_user_id on public.user_followed_artists (user_id);
create index if not exists idx_user_followed_artists_followed_at on public.user_followed_artists (user_id, followed_at);

alter table public.user_followed_artists enable row level security;
create policy "Users manage own followed_artists" on public.user_followed_artists for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- Followed albums (one row per saved album)
-- -----------------------------------------------------------------------------
create table if not exists public.user_followed_albums (
  user_id uuid not null,
  album_id text not null,
  title text not null default '',
  artist_name text not null default '',
  thumbnail_url text not null default '',
  browse_id text,
  followed_at timestamptz not null default now(),
  primary key (user_id, album_id),
  foreign key (user_id) references auth.users (id) on delete cascade
);

create index if not exists idx_user_followed_albums_user_id on public.user_followed_albums (user_id);
create index if not exists idx_user_followed_albums_followed_at on public.user_followed_albums (user_id, followed_at);

alter table public.user_followed_albums enable row level security;
create policy "Users manage own followed_albums" on public.user_followed_albums for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
