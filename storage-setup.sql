-- ============================================================
--  杜辛亞咖啡 Dulcinea Coffee — 圖片上傳空間 補充腳本
--  使用方式：跟 site-settings.sql 一樣，整份複製，貼進 Supabase
--  後台的 SQL Editor，按 Run。可重複執行，不會動到既有資料。
--
--  這份做兩件事：
--  1) 建立一個叫 site-photos 的公開儲存空間（Storage bucket），
--     專門放後台自行上傳的圖片（目前是護照背景照，之後也能放別的）。
--  2) 設定這個空間的存取規則：任何人都能「看」裡面的圖片
--     （不然前台客人看不到），但只有登入後台的管理者能「上傳／
--     覆蓋／刪除」。
--
--  跑完這份之後，後台「風味護照 → 護照外觀 · 背景照片」那邊就會
--  多一個「自行上傳」的選項，選一張圖片、按上傳，就會自動套用。
-- ============================================================

insert into storage.buckets (id, name, public)
values ('site-photos', 'site-photos', true)
on conflict (id) do nothing;

-- 任何人（含前台訪客）都能讀取 site-photos 裡的圖片
drop policy if exists "任何人都能看 site-photos" on storage.objects;
create policy "任何人都能看 site-photos" on storage.objects
  for select using (bucket_id = 'site-photos');

-- 登入後台的管理者可以上傳新圖片
drop policy if exists "管理者可以上傳到 site-photos" on storage.objects;
create policy "管理者可以上傳到 site-photos" on storage.objects
  for insert to authenticated with check (bucket_id = 'site-photos');

-- 登入後台的管理者可以覆蓋／更新既有圖片
drop policy if exists "管理者可以更新 site-photos" on storage.objects;
create policy "管理者可以更新 site-photos" on storage.objects
  for update to authenticated using (bucket_id = 'site-photos');

-- 登入後台的管理者可以刪除圖片
drop policy if exists "管理者可以刪除 site-photos" on storage.objects;
create policy "管理者可以刪除 site-photos" on storage.objects
  for delete to authenticated using (bucket_id = 'site-photos');

-- ============================================================
--  完成。這份只需要跑一次。如果之前已經跑過 site-settings.sql，
--  這份跑完後，後台上傳圖片就會自動存進 site_settings 裡，
--  跟原本貼網址的方式共用同一個「護照外觀 · 背景照片」欄位。
-- ============================================================
