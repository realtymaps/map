CREATE TABLE handlers_event_map (
  event_type text,
  handler_name text,
  handler_method text,
  method text,
  to_direction text,
  PRIMARY KEY (event_type)
);

insert into handlers_event_map values
  ('pin', 'notifications', 'notifyByUser', 'emailVero', 'parents'),
  ('favorite', 'notifications', 'notifyByUser', 'emailVero', 'parents'),
  ('jobQueue', 'notifications', 'notifyFlat', 'email', null);
