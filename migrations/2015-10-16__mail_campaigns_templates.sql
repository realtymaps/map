DROP TABLE IF EXISTS user_mail_campaigns;
CREATE TABLE user_mail_campaigns (
  id SERIAL PRIMARY KEY,
  auth_user_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  lob_batch_id TEXT,
  name TEXT,
  count INTEGER,
  status TEXT, -- sent | pending | draft | ...
  content TEXT, -- full HTML5 content
  template_id INTEGER, -- initial template this is based on, for reference
  created TIMESTAMP NOT NULL,
  submitted TIMESTAMP
);
