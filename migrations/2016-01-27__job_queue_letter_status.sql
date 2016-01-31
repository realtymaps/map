DELETE FROM jq_subtask_config WHERE task_name = 'lobCleanup';
INSERT INTO jq_subtask_config VALUES ('lobCleanup_updateLetters', 'lobCleanup', 'lob', 1, 'null', NULL, 0, true, true, true, NULL, NULL, true);
INSERT INTO jq_subtask_config VALUES ('lobCleanup_getLetter', 'lobCleanup', 'lob', 2, 'null', NULL, 0, false, true, true, 60, 300, false);

DELETE FROM jq_task_config WHERE name = 'lobCleanup';
INSERT INTO jq_task_config VALUES ('lobCleanup', 'Janitor task for mail', '{}', NULL, 60, 5, 5, true, 5);
