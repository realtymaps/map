update user_events_queue
  set
    sub_type = type,
    type = 'propertySaved'
where type ilike 'pin' or type ilike 'favorite' and sub_type is null;;

update user_events_queue
  set
    sub_type = sub_type || initcap(type),
    type = 'propertySaved'
where type ilike 'pin' or type ilike 'favorite' and sub_type is not null;

alter table user_events_queue ALTER COLUMN sub_type SET NOT NULL;

update config_handlers_event_map
set
  event_type = 'propertySaved',
  to_direction = 'all'
where event_type = 'pin';

delete from config_handlers_event_map
where event_type = 'favorite';

update user_notification_config
set type = 'propertySaved'
where type in ('pin', 'favorite');
