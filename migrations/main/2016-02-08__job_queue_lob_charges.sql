INSERT INTO jq_subtask_config VALUES ('lob_findCampaigns', 'lob', 'lob', 3, 'null', NULL, 0, true, true, true, NULL, NULL, true);
INSERT INTO jq_subtask_config VALUES ('lob_chargeCampaign', 'lob', 'lob', 4, 'null', NULL, 0, false, true, true, 60, 300, false);

UPDATE jq_task_config SET description = 'Send letters and handling billing for mail campaigns' WHERE name = 'lob';
