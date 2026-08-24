-- ============================================================
--  杜辛亞咖啡 Dulcinea Coffee — 網站外觀設定 補充腳本
--  使用方式：跟 member-coupons.sql 一樣，整份複製，貼進 Supabase
--  後台的 SQL Editor，按 Run。可重複執行，不會動到既有資料。
--
--  這份只做一件事：新增一張 key/value 的「外觀設定」表，
--  目前用來存風味護照卡片背後的背景照片網址，之後如果還想讓
--  後台可以自訂其他外觀（例如首頁標語），也可以往這張表加新的
--  key，不用再另外開資料表。
-- ============================================================

create table if not exists public.site_settings (
  key        text primary key,
  value      text,
  updated_at timestamptz default now()
);

alter table public.site_settings enable row level security;

-- 訪客（前台）只能讀，不能寫
drop policy if exists "訪客可讀取外觀設定" on public.site_settings;
create policy "訪客可讀取外觀設定" on public.site_settings
  for select to anon using (true);

-- 管理者（後台登入後）可以完整讀寫
drop policy if exists "管理者可管理外觀設定" on public.site_settings;
create policy "管理者可管理外觀設定" on public.site_settings
  for all to authenticated using (true) with check (true);

grant select on public.site_settings to anon;
grant select, insert, update, delete on public.site_settings to authenticated;

-- 預設值：跟 index.html 內建的那張森林照片一樣，
-- 後台還沒存過設定之前，前台會用 index.html 裡寫死的那張，不會用到這一列，
-- 這裡先放著只是方便你之後在後台看到「目前是這張」。
insert into public.site_settings (key, value) values
  ('passport_bg_photo_url', 'https://images.unsplash.com/photo-1761549789935-c3ac22f69fd3?fm=jpg&q=70&w=1600&auto=format&fit=crop')
on conflict (key) do nothing;

-- ============================================================
--  完成。之後在後台「風味護照」分頁裡的「護照外觀 · 背景照片」
--  貼新的圖片網址、按儲存，前台重新整理就會換成新照片。
-- ============================================================
