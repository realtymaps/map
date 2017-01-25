
-- more descriptive names
ALTER TABLE history_user RENAME TO history_user_feedback;
ALTER TABLE history_user_category RENAME TO lookup_user_feedback_category;
ALTER TABLE history_user_subcategory RENAME TO lookup_user_feedback_subcategory;


-- don't use VARCHAR(x), just use TEXT.  TEXT is actually more performant.  See the beige tip box here:
-- https://www.postgresql.org/docs/current/static/datatype-character.html
ALTER TABLE lookup_user_feedback_category ALTER COLUMN code TYPE TEXT;
ALTER TABLE lookup_user_feedback_subcategory ALTER COLUMN code TYPE TEXT;


-- we don't need to edit rows
DROP TRIGGER update_modified_time_history_user ON history_user_feedback;
ALTER TABLE history_user_feedback DROP COLUMN rm_modified_time;


-- descriptive ids are easier to use and search
ALTER TABLE lookup_user_feedback_subcategory ADD COLUMN category TEXT;
UPDATE lookup_user_feedback_subcategory
SET category = (SELECT code FROM lookup_user_feedback_category WHERE id = lookup_user_feedback_subcategory.category_id);
ALTER TABLE lookup_user_feedback_subcategory ALTER COLUMN category SET NOT NULL;
ALTER TABLE lookup_user_feedback_subcategory DROP COLUMN category_id;

ALTER TABLE history_user_feedback ADD COLUMN category TEXT;
UPDATE history_user_feedback
SET category = (SELECT code FROM lookup_user_feedback_category WHERE id = history_user_feedback.category_id);
ALTER TABLE history_user_feedback ALTER COLUMN category SET NOT NULL;
ALTER TABLE history_user_feedback DROP COLUMN category_id;

ALTER TABLE history_user_feedback ADD COLUMN subcategory TEXT;
UPDATE history_user_feedback
SET subcategory = (SELECT code FROM lookup_user_feedback_subcategory WHERE id = history_user_feedback.subcategory_id);
ALTER TABLE history_user_feedback ALTER COLUMN subcategory SET NOT NULL;
ALTER TABLE history_user_feedback DROP COLUMN subcategory_id;

ALTER TABLE lookup_user_feedback_category DROP COLUMN id;
ALTER TABLE lookup_user_feedback_category RENAME COLUMN code TO id;
ALTER TABLE lookup_user_feedback_category ADD PRIMARY KEY (id);
ALTER TABLE lookup_user_feedback_subcategory DROP COLUMN id;
ALTER TABLE lookup_user_feedback_subcategory RENAME COLUMN code TO id;
ALTER TABLE lookup_user_feedback_subcategory ADD PRIMARY KEY (id);


-- denormalizing user email for search purposes
ALTER TABLE history_user_feedback ADD COLUMN auth_user_email TEXT;
UPDATE history_user_feedback SET auth_user_email = (SELECT email FROM auth_user WHERE auth_user.id = history_user_feedback.auth_user_id);
ALTER TABLE history_user_feedback ALTER COLUMN auth_user_email SET NOT NULL;


-- I left off the foreign key constraint because it will cause us problems; if we ever wanted to make some option
-- unavailable (maybe because we've implemented the feature being requested, like bulk discounts), we wouldn't be able
-- to just delete it from the subcategory table without killing off the user feedback requests for it.


-- now we can see the result of those changes: easier to insert new values now ('deactivation' broke varchar(10) before,
-- and now it doesn't require subselects to get ids)
INSERT INTO lookup_user_feedback_category (name, id) VALUES
  ('Deactivation', 'deactivation');
INSERT INTO lookup_user_feedback_subcategory (name, id, category) VALUES
  ('Costs too much', 'price', 'deactivation'),
  ('Can''t do what I want it to', 'features', 'deactivation'),
  ('Too hard to use', 'user friendliness', 'deactivation'),
  ('Data is incomplete or incorrect', 'data integrity', 'deactivation'),
  ('Counties and/or MLSs I need aren''t supported', 'location support', 'deactivation'),
  ('Other', 'other', 'deactivation');

UPDATE lookup_user_feedback_category SET id = 'software' WHERE id = 'soft';
UPDATE lookup_user_feedback_subcategory SET category = 'software' WHERE category = 'soft';
