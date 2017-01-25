CREATE TABLE history_user_subcategory (
  id serial,
  name text NOT NULL,
  code varchar(30),
  category_id int4 NOT NULL,
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);


-- ('bug', 'Bug'),
-- Realestate
-- ('coverage', 'Coverage'),

INSERT INTO history_user_subcategory (code, name, category_id)
VALUES
('bug', 'Bug', (select id from history_user_category where code = 'soft')),
('feature', 'Feature', (select id from history_user_category where code = 'soft'));

INSERT INTO history_user_subcategory (code, name, category_id)
VALUES
('expensive', 'Too Expensive', (select id from history_user_category where code = 'cost')),
('bulk', 'Bulk Discount', (select id from history_user_category where code = 'cost')),
('promotion', 'Possible Promotions', (select id from history_user_category where code = 'cost'));


INSERT INTO history_user_subcategory (code, name, category_id)
VALUES
('missingLoc', 'Missing Location', (select id from history_user_category where code = 'realEstate')),
('invalidRealEstate', 'Invalid Property (Locaiton, Price etc.)', (select id from history_user_category where code = 'realEstate'));

ALTER TABLE history_user_subcategory
ADD CONSTRAINT fk_history_user_subcategory_category
FOREIGN KEY (category_id)
REFERENCES history_user_category (id)
ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE;
