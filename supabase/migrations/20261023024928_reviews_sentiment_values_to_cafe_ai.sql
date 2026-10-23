-- cafe-ai 가 돌려주는 감정 값(좋음/보통/아쉬움)에 맞춰 reviews.sentiment 허용값을 바꾼다
alter table public.reviews drop constraint reviews_sentiment_check;
alter table public.reviews add constraint reviews_sentiment_check
  check (sentiment in ('좋음', '보통', '아쉬움'));
