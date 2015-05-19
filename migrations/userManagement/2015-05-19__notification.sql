CREATE TABLE IF NOT EXISTS notification (
  user_id INTEGER NOT NULL,
  type TEXT NOT NULL    --  [ sms | email ]  -- to be validated using util.validation.choice.coffee
);

ALTER TABLE notification
ADD FOREIGN KEY (user_id) 
REFERENCES auth_user(id);