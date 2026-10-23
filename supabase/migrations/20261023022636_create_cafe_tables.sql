create table public.menus (
  id bigint generated always as identity primary key,
  name text not null,
  category text not null,
  price integer not null check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  created_at timestamptz not null default now()
);

create table public.sales (
  id bigint generated always as identity primary key,
  menu_id bigint references public.menus (id) on delete set null,
  menu_name text not null,
  quantity integer not null check (quantity > 0),
  amount integer not null check (amount >= 0),
  sold_at timestamptz not null default now()
);
create index sales_sold_at_idx on public.sales (sold_at);
create index sales_menu_id_idx on public.sales (menu_id);

create table public.reviews (
  id bigint generated always as identity primary key,
  rating smallint not null check (rating between 1 and 5),
  content text not null,
  sentiment text check (sentiment in ('긍정', '중립', '부정')),
  reply text,
  written_at timestamptz not null default now()
);

alter table public.menus enable row level security;
alter table public.sales enable row level security;
alter table public.reviews enable row level security;

grant select, insert, update, delete on public.menus to anon;
grant select, insert, update, delete on public.sales to anon;
grant select, insert, update, delete on public.reviews to anon;

create policy "anon full access" on public.menus
  for all to anon using (true) with check (true);
create policy "anon full access" on public.sales
  for all to anon using (true) with check (true);
create policy "anon full access" on public.reviews
  for all to anon using (true) with check (true);
