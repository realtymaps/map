alter table user_project add column sandbox boolean default false;

delete from user_profile where project_id is null;