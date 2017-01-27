delete from user_events_queue;

alter table user_events_queue add column project_id int not null;
