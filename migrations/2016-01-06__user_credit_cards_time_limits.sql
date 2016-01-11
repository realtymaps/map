CREATE TABLE user_credit_cards (
	id serial,
	auth_user_id int4,
	token varchar,
	last4 varchar,
	brand varchar,
	country varchar,
	exp_month varchar,
	exp_year varchar,
	last_charge_amount int4,
	last_charge_time TIMESTAMP WITHOUT TIME ZONE,
	rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
	rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
	PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE,
	CONSTRAINT fk_user_credit_cards_auth_user_id FOREIGN KEY (auth_user_id) REFERENCES auth_user (id) ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (OIDS=FALSE);


CREATE TRIGGER update_modified_time_user_credit_cards
BEFORE UPDATE ON user_credit_cards
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();
