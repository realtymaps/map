CREATE UNIQUE INDEX  lookup_us_states_code_idx ON lookup_us_states USING btree(code);
CREATE UNIQUE INDEX  lookup_us_states_name_idx ON lookup_us_states USING btree(name);
