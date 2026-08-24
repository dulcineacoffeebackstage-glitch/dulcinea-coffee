-- ============================================================
--  杜辛亞咖啡 Dulcinea Coffee — 會員專區／我的優惠券 補充腳本
--  使用方式：整份複製，貼進 Supabase 後台的 SQL Editor，按 Run。
--  可重複執行。這份不會動到任何現有資料表或資料，
--  只新增一個「查自己優惠券」的專用函式。
--
--  為什麼需要這個檔案：
--  coupons 資料表本來就有 phone 欄位（後台發券、風味護照
--  達標自動發券都會把電話寫進去），但 schema.sql 裡的權限
--  規則（RLS）刻意沒有讓沒登入的訪客讀 coupons 表 —— 這是
--  對的，不然任何人都能撈到全店的優惠券清單。
--  所以會員專區前台要「用自己的電話查自己的券」，需要另外
--  一個安全的函式：只回傳「電話對得上」的那幾張券，其他人
--  的完全看不到。
-- ============================================================

drop function if exists public.get_member_coupons(text);

create or replace function public.get_member_coupons(p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_phone text := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
  v_rows  jsonb;
begin
  if length(v_phone) < 8 then
    return jsonb_build_object('ok', false, 'reason', '手機號碼格式不正確');
  end if;

  select coalesce(jsonb_agg(row_to_json(t) order by t.rank, t.expiry nulls last, t.created_at desc), '[]'::jsonb)
    into v_rows
  from (
    select
      code, kind, discount_type, discount_value, exchange_item,
      expiry, status, created_at,
      case
        when status = '未使用' and (expiry is null or expiry >= current_date) then 0
        when status = '未使用' then 1  -- 未使用但過期了
        else 2                          -- 已使用
      end as rank
    from public.coupons
    where regexp_replace(coalesce(phone, ''), '\D', '', 'g') = v_phone
  ) t;

  return jsonb_build_object('ok', true, 'coupons', v_rows);
end;
$$;

-- 訪客只能執行這個函式來查自己的券，不能直接讀 coupons 表
grant execute on function public.get_member_coupons(text) to anon, authenticated;

-- ============================================================
--  完成。前台的「我的優惠券」頁會呼叫：
--    sb.rpc('get_member_coupons', { p_phone: '0912345678' })
--  回傳格式：
--    { ok: true, coupons: [
--        { code, kind, discount_type, discount_value,
--          exchange_item, expiry, status, created_at }, ...
--    ] }
-- ============================================================
