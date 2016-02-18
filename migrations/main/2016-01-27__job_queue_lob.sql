DELETE FROM jq_subtask_config WHERE task_name = 'lob';
INSERT INTO jq_subtask_config VALUES ('lob_findLetters', 'lob', 'lob', 1, 'null', NULL, 0, true, true, true, NULL, NULL, true);
INSERT INTO jq_subtask_config VALUES ('lob_createLetter', 'lob', 'lob', 2, 'null', NULL, 0, false, true, true, 60, 300, false);

DELETE FROM jq_task_config WHERE name = 'lob';
INSERT INTO jq_task_config VALUES ('lob', 'Send letters queued from mail campaigns', '{}', NULL, 60, 5, 5, true, 5);

DELETE FROM jq_queue_config WHERE name = 'lob';
INSERT INTO jq_queue_config VALUES ('lob', 56225253, 1, 5, 1, true);
