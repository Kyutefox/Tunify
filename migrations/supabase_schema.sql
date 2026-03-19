-- =============================================================================
-- Tunify Music App — Supabase schema (normalized, row-wise, no JSONB lists)
-- =============================================================================
-- Run in Supabase SQL Editor. All tables reference auth.users(id).
-- One row per entity; no JSONB arrays for better performance and indexing.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Folders
-- -----------------------------------------------------------------------------
create table if not exists public.user_folders (
  user_id uuid not null,
  id text not null,
  name text not null,
  created_at timestamptz not null default now(),
  is_pinned boolean not null default false,
  primary key (user_id, id),
  foreign key (user_id) references auth.users (id) on delete cascade
);

create index if not exists idx_user_folders_user_id on public.user_folders (user_id);
create index if not exists idx_user_folders_user_name on public.user_folders (user_id, name);

-- -----------------------------------------------------------------------------
-- Playlists (metadata only; tracks in user_playlist_tracks)
-- -----------------------------------------------------------------------------
create table if not exists public.user_playlists (
  user_id uuid not null,
  id text not null,
  name text not null,
  description text not null default '',
  sort_order text not null default 'customOrder',
  custom_image_url text,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id) references auth.users (id) on delete cascade
);

create index if not exists idx_user_playlists_user_id on public.user_playlists (user_id);
create index if not exists idx_user_playlists_updated_at on public.user_playlists (user_id, updated_at desc);

-- -----------------------------------------------------------------------------
-- Playlist tracks (one row per song in a playlist)
-- -----------------------------------------------------------------------------
create table if not exists public.user_playlist_tracks (
  user_id uuid not null,
  playlist_id text not null,
  song_id text not null,
  position int not null,
  title text not null default '',
  artist text not null default '',
  thumbnail_url text not null default '',
  duration_seconds int not null default 0,
  album_name text,
  artist_browse_id text,
  album_browse_id text,
  is_explicit boolean not null default false,
  added_at timestamptz not null default now(),
  primary key (user_id, playlist_id, song_id),
  foreign key (user_id, playlist_id) references public.user_playlists (user_id, id) on delete cascade
);

create index if not exists idx_user_playlist_tracks_playlist on public.user_playlist_tracks (user_id, playlist_id);
create index if not exists idx_user_playlist_tracks_order on public.user_playlist_tracks (user_id, playlist_id, position);

-- -----------------------------------------------------------------------------
-- Folder ↔ Playlist junction
-- -----------------------------------------------------------------------------
create table if not exists public.user_folder_playlists (
  user_id uuid not null,
  folder_id text not null,
  playlist_id text not null,
  primary key (user_id, folder_id, playlist_id),
  foreign key (user_id) references auth.users (id) on delete cascade,
  foreign key (user_id, folder_id) references public.user_folders (user_id, id) on delete cascade,
  foreign key (user_id, playlist_id) references public.user_playlists (user_id, id) on delete cascade
);

create index if not exists idx_user_folder_playlists_user_id on public.user_folder_playlists (user_id);
create index if not exists idx_user_folder_playlists_folder on public.user_folder_playlists (user_id, folder_id);

-- -----------------------------------------------------------------------------
-- Library settings (scalars only)
-- -----------------------------------------------------------------------------
create table if not exists public.user_library_settings (
  user_id uuid not null primary key,
  sort_order text not null default 'recent',
  view_mode text not null default 'list',
  liked_shuffle boolean not null default false,
  downloaded_shuffle boolean not null default false,
  updated_at timestamptz not null default now(),
  foreign key (user_id) references auth.users (id) on delete cascade
);

-- -----------------------------------------------------------------------------
-- Liked songs (one row per song)
-- -----------------------------------------------------------------------------
create table if not exists public.user_liked_songs (
  user_id uuid not null,
  song_id text not null,
  position int not null,
  title text not null default '',
  artist text not null default '',
  thumbnail_url text not null default '',
  duration_seconds int not null default 0,
  album_name text,
  artist_browse_id text,
  album_browse_id text,
  is_explicit boolean not null default false,
  added_at timestamptz not null default now(),
  primary key (user_id, song_id),
  foreign key (user_id) references auth.users (id) on delete cascade
);

create index if not exists idx_user_liked_songs_user_id on public.user_liked_songs (user_id);
create index if not exists idx_user_liked_songs_order on public.user_liked_songs (user_id, position);

-- -----------------------------------------------------------------------------
-- Per-playlist shuffle setting (one row per playlist)
-- -----------------------------------------------------------------------------
create table if not exists public.user_playlist_shuffle (
  user_id uuid not null,
  playlist_id text not null,
  shuffle_enabled boolean not null default false,
  primary key (user_id, playlist_id),
  foreign key (user_id) references auth.users (id) on delete cascade
);

-- (Pinned state stored as is_pinned on user_folders and user_playlists.)

-- -----------------------------------------------------------------------------
-- Playback settings
-- -----------------------------------------------------------------------------
create table if not exists public.user_playback_settings (
  user_id uuid not null primary key,
  volume_normalization boolean not null default false,
  show_explicit_content boolean not null default true,
  smart_recommendation_shuffle boolean not null default true,
  crossfade_duration_seconds int not null default 0,
  gapless_playback boolean not null default true,
  updated_at timestamptz not null default now(),
  foreign key (user_id) references auth.users (id) on delete cascade
);

-- -----------------------------------------------------------------------------
-- Recently played (one row per song; played_at updated on each play)
-- -----------------------------------------------------------------------------
create table if not exists public.user_recently_played (
  user_id uuid not null,
  song_id text not null,
  played_at timestamptz not null default now(),
  title text not null default '',
  artist text not null default '',
  thumbnail_url text not null default '',
  duration_seconds int not null default 0,
  primary key (user_id, song_id),
  foreign key (user_id) references auth.users (id) on delete cascade
);

create index if not exists idx_user_recently_played_user_id on public.user_recently_played (user_id);
create index if not exists idx_user_recently_played_played_at on public.user_recently_played (user_id, played_at desc);

-- -----------------------------------------------------------------------------
-- Recent searches (one row per query; searched_at updated on repeat)
-- -----------------------------------------------------------------------------
create table if not exists public.user_recent_searches (
  user_id uuid not null,
  query text not null,
  searched_at timestamptz not null default now(),
  primary key (user_id, query),
  foreign key (user_id) references auth.users (id) on delete cascade
);

create index if not exists idx_user_recent_searches_user_id on public.user_recent_searches (user_id);
create index if not exists idx_user_recent_searches_searched_at on public.user_recent_searches (user_id, searched_at desc);

-- -----------------------------------------------------------------------------
-- YouTube personalization (one row per user)
-- -----------------------------------------------------------------------------
create table if not exists public.yt_personalization (
  user_id uuid not null primary key,
  visitor_data text not null default '',
  api_key text,
  client_version text,
  cookies jsonb,
  updated_at timestamptz not null default now(),
  foreign key (user_id) references auth.users (id) on delete cascade
);

-- -----------------------------------------------------------------------------
-- Downloaded song IDs (one row per song)
-- -----------------------------------------------------------------------------
create table if not exists public.user_downloaded_songs (
  user_id uuid not null,
  song_id text not null,
  added_at timestamptz not null default now(),
  primary key (user_id, song_id),
  foreign key (user_id) references auth.users (id) on delete cascade
);

create index if not exists idx_user_downloaded_songs_user_id on public.user_downloaded_songs (user_id);
create index if not exists idx_user_downloaded_songs_added_at on public.user_downloaded_songs (user_id, added_at desc);

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

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------
alter table public.user_folders enable row level security;
alter table public.user_playlists enable row level security;
alter table public.user_playlist_tracks enable row level security;
alter table public.user_folder_playlists enable row level security;
alter table public.user_library_settings enable row level security;
alter table public.user_liked_songs enable row level security;
alter table public.user_playlist_shuffle enable row level security;
alter table public.user_playback_settings enable row level security;
alter table public.user_recently_played enable row level security;
alter table public.user_recent_searches enable row level security;
alter table public.yt_personalization enable row level security;
alter table public.user_downloaded_songs enable row level security;

create policy "Users manage own folders" on public.user_folders for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own playlists" on public.user_playlists for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own playlist_tracks" on public.user_playlist_tracks for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own folder_playlists" on public.user_folder_playlists for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own library_settings" on public.user_library_settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own liked_songs" on public.user_liked_songs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own playlist_shuffle" on public.user_playlist_shuffle for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own playback_settings" on public.user_playback_settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own recently_played" on public.user_recently_played for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own recent_searches" on public.user_recent_searches for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own yt_personalization" on public.yt_personalization for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own downloaded_songs" on public.user_downloaded_songs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
alter table public.user_followed_artists enable row level security;
alter table public.user_followed_albums enable row level security;
create policy "Users manage own followed_artists" on public.user_followed_artists for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own followed_albums" on public.user_followed_albums for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
