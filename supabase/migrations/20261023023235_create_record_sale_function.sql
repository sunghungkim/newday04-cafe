-- 판매 기록과 재고 차감을 한 번에 처리한다 (재고가 모자라면 아무것도 바꾸지 않는다)
create or replace function public.record_sale(p_menu_id bigint, p_quantity integer)
returns public.sales
language plpgsql
security invoker
set search_path = ''
as $$
declare
  m public.menus;
  s public.sales;
begin
  if p_quantity is null or p_quantity < 1 then
    raise exception 'invalid_quantity';
  end if;

  update public.menus
     set stock = stock - p_quantity
   where id = p_menu_id and stock >= p_quantity
  returning * into m;

  if not found then
    if exists (select 1 from public.menus where id = p_menu_id) then
      raise exception 'out_of_stock';
    end if;
    raise exception 'menu_not_found';
  end if;

  insert into public.sales (menu_id, menu_name, quantity, amount)
  values (m.id, m.name, p_quantity, m.price * p_quantity)
  returning * into s;

  return s;
end;
$$;

revoke all on function public.record_sale(bigint, integer) from public;
grant execute on function public.record_sale(bigint, integer) to anon;
