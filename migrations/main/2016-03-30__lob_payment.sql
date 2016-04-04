INSERT INTO jq_task_config
  VALUES (
    'lobPayment', --name
    'Mail campaign payments', --description
    '{}', --data
    NULL, --ignore_until
    60, --repeat_period_minutes
    5, --warn_timeout_minutes
    5, --kill_timeout_minutes
    true, --active
    5); --fail_retry_minutes

UPDATE jq_subtask_config set name='lobPayment_findCampaigns', task_name='lobPayment' where name='lob_findCampaigns';
UPDATE jq_subtask_config set name='lobPayment_chargeCampaign', task_name='lobPayment' where name='lob_chargeCampaign';
