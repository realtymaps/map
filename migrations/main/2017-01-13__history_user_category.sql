CREATE TABLE history_user_category (
  id serial,
  name text NOT NULL,
  code varchar(10),
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);


INSERT INTO history_user_category (code, name)
VALUES
('soft', 'Software'),
('cost', 'Cost'),
('help', 'Help'),
('realEstate', 'Real estate'),
('misc', 'Miscellaneous');
