alter table user_mail_campaigns ADD COLUMN recipients JSON;
delete from user_mail_campaigns where not exists (select 1 from user_project where user_project.id = user_mail_campaigns.project_id);
