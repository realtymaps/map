alter table user_account_images rename to user_blobs;

alter table user_blobs add column auth_user_id int;
alter table user_blobs add column company_id int;


alter table user_blobs
  ADD CONSTRAINT user_blobs_auth_user_id_fk FOREIGN KEY (auth_user_id)
  REFERENCES auth_user (id) ON UPDATE CASCADE ON DELETE CASCADE;

alter table user_blobs
  ADD CONSTRAINT user_blobs_company_id_fk FOREIGN KEY (company_id)
  REFERENCES user_company (id) ON UPDATE CASCADE ON DELETE CASCADE;


update user_blobs
  set auth_user_id = auth_user.id
FROM auth_user
where auth_user.account_image_id = user_blobs.id;

update user_blobs
  set company_id = user_company.id
FROM user_company
where user_company.account_image_id = user_blobs.id;
