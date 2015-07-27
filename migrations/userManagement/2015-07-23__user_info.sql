alter table auth_user add column company_id int;
ALTER TABLE auth_user ADD CONSTRAINT "fk_auth_user_company_id" FOREIGN KEY (company_id)
REFERENCES company (id) ON UPDATE CASCADE ON DELETE SET NULL;

alter table company add column name varchar;
