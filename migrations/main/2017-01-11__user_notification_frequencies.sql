ALTER  TABLE user_notification_frequencies ADD COLUMN target_hour int4;

update user_notification_frequencies
  set target_hour=4
where code_name in ('daily','weekly', 'monthly');
