delete from jq_subtask_config
where name in ('eventsDequeue_deleteEventsQueue', 'notifications_deleteNotificationsQueue');

update jq_subtask_config
set step_num = step_num - 1
where name like '%eventsDequeue%';

update jq_subtask_config
set step_num = step_num - 1
where name like '%notifications%';
