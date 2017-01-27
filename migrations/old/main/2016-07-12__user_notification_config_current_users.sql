insert into user_notification_config (auth_user_id, type, method, frequency)
select id as auth_user_id, 'propertySaved', 'emailVero', 'onDemand' from auth_user
EXCEPT
select auth_user_id, type, method, frequency from user_notification_config;
