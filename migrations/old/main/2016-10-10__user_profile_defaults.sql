ALTER TABLE user_profile ALTER COLUMN filters set default '{}'::json;
ALTER TABLE user_profile ALTER COLUMN map_position set default '{}'::json;

update user_profile
  set filters = '{}'::json
where filters is null;

update user_profile
  set map_position = '{}'::json
where map_position is null;
