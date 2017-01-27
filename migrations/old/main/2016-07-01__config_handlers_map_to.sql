CREATE TABLE temp_config_handlers_event_map (
  event_type text,
  handler_name text,
  handler_method text,
  method text,
  to_direction json,
  PRIMARY KEY (event_type)
);

ALTER TABLE config_handlers_event_map RENAME to orig_config_handlers_event_map;

ALTER TABLE temp_config_handlers_event_map RENAME to config_handlers_event_map;

insert into config_handlers_event_map
(select event_type, handler_name, handler_method, method,
concat('["', to_direction, '"]')::json
from orig_config_handlers_event_map
where to_direction is not NULL
);

insert into config_handlers_event_map
(select event_type, handler_name, handler_method, method
from orig_config_handlers_event_map
where to_direction is NULL
);

DROP TABLE orig_config_handlers_event_map;
