ALTER TABLE history_user
ADD CONSTRAINT fk_history_user_category
FOREIGN KEY (category_id)
REFERENCES history_user_category (id)
ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE history_user
ADD CONSTRAINT fk_history_user_subcategory
FOREIGN KEY (subcategory_id)
REFERENCES history_user_subcategory (id)
ON DELETE CASCADE NOT DEFERRABLE INITIALLY IMMEDIATE;


ALTER TABLE history_user ALTER COLUMN category_id SET NOT NULL;
ALTER TABLE history_user ALTER COLUMN subcategory_id SET NOT NULL;
