ALTER TABLE user_events_queue add column daily_processed boolean DEFAULT false;
ALTER TABLE user_events_queue add column onDemand_processed boolean DEFAULT false;
