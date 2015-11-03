alter table user_project add column sandbox boolean default false;

delete from user_profile where project_id is null;

alter table user_profile alter column project_id set not null;
