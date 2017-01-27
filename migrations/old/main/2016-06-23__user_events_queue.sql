alter table user_events_queue add column sub_type text;


update user_events_queue
  set
    sub_type = 'un',
    type = lower(replace(type, 'un', ''))
where type like '%un%';
