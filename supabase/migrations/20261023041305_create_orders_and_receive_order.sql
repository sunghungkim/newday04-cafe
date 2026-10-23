-- 재고 발주: 발주 내역 테이블
create table public.orders (
  id bigint generated always as identity primary key,
  menu_id bigint references public.menus (id) on delete set null,
  menu_name text not null,
  quantity integer not null check (quantity > 0),
  status text not null default '발주' check (status in ('발주', '입고', '취소')),
  ordered_by text not null default '',
  ordered_at timestamptz not null default now(),
  received_at timestamptz
);
create index orders_ordered_at_idx on public.orders (ordered_at desc);
create index orders_menu_id_idx on public.orders (menu_id);

alter table public.orders enable row level security;
grant select, insert, update, delete on public.orders to anon;
create policy "anon full access" on public.orders
  for all to anon using (true) with check (true);

-- 입고 처리: 발주 상태를 '입고'로 바꾸고 그 메뉴의 재고를 수량만큼 늘린다 (둘 중 하나만 되는 일이 없게 한 번에 처리)
create or replace function public.receive_order(p_order_id bigint)
returns public.orders
language plpgsql
security invoker
set search_path = ''
as $$
declare
  o public.orders;
begin
  update public.orders
     set status = '입고', received_at = now()
   where id = p_order_id and status = '발주'
  returning * into o;

  if not found then
    if exists (select 1 from public.orders where id = p_order_id) then
      raise exception 'already_processed';
    end if;
    raise exception 'order_not_found';
  end if;

  update public.menus set stock = stock + o.quantity where id = o.menu_id;
  if not found then
    raise exception 'menu_not_found'; -- 메뉴가 지워졌으면 입고할 곳이 없으므로 위의 상태 변경도 되돌아간다
  end if;

  return o;
end;
$$;

revoke all on function public.receive_order(bigint) from public;
grant execute on function public.receive_order(bigint) to anon;
