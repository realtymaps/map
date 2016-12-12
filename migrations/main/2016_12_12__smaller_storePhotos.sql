CREATE OR REPLACE FUNCTION refactor_store_photos() RETURNS VOID
LANGUAGE plpgsql AS $$
  DECLARE
    row RECORD;
    blob JSON[];
  BEGIN
    FOR row IN
      SELECT *
      FROM
        jq_current_subtasks
      WHERE
        name = 'swflmls_photo_store' AND
        status IN ('queued', 'running')
      ORDER BY step_num ASC
    LOOP
      SELECT array_agg(e) FROM (SELECT json_array_elements(row.data->'values')) x(e) INTO blob;
      INSERT INTO jq_current_subtasks(name,task_name,queue_name,batch_id,step_num,task_step,data,task_data,retry_max_count,retry_num,ignore_until,enqueued,started,finished,status,auto_enqueue,preparing_started,heartbeat,retry_delay_minutes,kill_timeout_minutes,warn_timeout_minutes)
      VALUES
        (row.name,row.task_name,row.queue_name,row.batch_id,row.step_num*10+1,row.task_name||'_0000'||row.step_num*10+1,('{"values":'||array_to_json(blob[  1:100])||',"chunk":"'||(row.data->'chunk')||'-1'||'","count":100}')::JSON,row.task_data,row.retry_max_count,row.retry_num,row.ignore_until,row.enqueued,row.started,row.finished,row.status,row.auto_enqueue,row.preparing_started,row.heartbeat,row.retry_delay_minutes,row.kill_timeout_minutes,row.warn_timeout_minutes),
        (row.name,row.task_name,row.queue_name,row.batch_id,row.step_num*10+2,row.task_name||'_0000'||row.step_num*10+2,('{"values":'||array_to_json(blob[101:200])||',"chunk":"'||(row.data->'chunk')||'-2'||'","count":100}')::JSON,row.task_data,row.retry_max_count,row.retry_num,row.ignore_until,row.enqueued,row.started,row.finished,row.status,row.auto_enqueue,row.preparing_started,row.heartbeat,row.retry_delay_minutes,row.kill_timeout_minutes,row.warn_timeout_minutes),
        (row.name,row.task_name,row.queue_name,row.batch_id,row.step_num*10+3,row.task_name||'_0000'||row.step_num*10+3,('{"values":'||array_to_json(blob[201:300])||',"chunk":"'||(row.data->'chunk')||'-3'||'","count":100}')::JSON,row.task_data,row.retry_max_count,row.retry_num,row.ignore_until,row.enqueued,row.started,row.finished,row.status,row.auto_enqueue,row.preparing_started,row.heartbeat,row.retry_delay_minutes,row.kill_timeout_minutes,row.warn_timeout_minutes),
        (row.name,row.task_name,row.queue_name,row.batch_id,row.step_num*10+4,row.task_name||'_0000'||row.step_num*10+4,('{"values":'||array_to_json(blob[301:400])||',"chunk":"'||(row.data->'chunk')||'-4'||'","count":100}')::JSON,row.task_data,row.retry_max_count,row.retry_num,row.ignore_until,row.enqueued,row.started,row.finished,row.status,row.auto_enqueue,row.preparing_started,row.heartbeat,row.retry_delay_minutes,row.kill_timeout_minutes,row.warn_timeout_minutes),
        (row.name,row.task_name,row.queue_name,row.batch_id,row.step_num*10+5,row.task_name||'_0000'||row.step_num*10+5,('{"values":'||array_to_json(blob[401:500])||',"chunk":"'||(row.data->'chunk')||'-5'||'","count":'||array_length(blob[401:500],1)||'}')::JSON,row.task_data,row.retry_max_count,row.retry_num,row.ignore_until,row.enqueued,row.started,row.finished,row.status,row.auto_enqueue,row.preparing_started,row.heartbeat,row.retry_delay_minutes,row.kill_timeout_minutes,row.warn_timeout_minutes);
      DELETE FROM jq_current_subtasks WHERE id = row.id;
    END LOOP;
  RETURN;
END;
$$;

SELECT refactor_store_photos();
DROP FUNCTION refactor_store_photos(VOID);

UPDATE jq_subtask_config
SET
  kill_timeout_minutes = 15,
  warn_timeout_minutes = 10
WHERE name LIKE '%_store_photo';
