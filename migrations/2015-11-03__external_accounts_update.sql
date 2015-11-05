
ALTER TABLE config_external_accounts ADD COLUMN url TEXT;
ALTER TABLE config_external_accounts ADD COLUMN environment TEXT;
ALTER TABLE config_external_accounts DROP COLUMN id;
CREATE INDEX ON config_external_accounts (name);
CREATE UNIQUE INDEX ON config_external_accounts (name, environment);

UPDATE config_external_accounts
  SET
    username = 'NgximUzHDCfMmFVv3h3Gbg==$$oDusRMRFqw36MyE7fw==$',
    password = 'z/tipYeaOU9rrZ8cyJHJSQ==$$/gecucU1ag==$',
    url = 'YRQ4iKv4N+AchZVT34L4Yw==$$X3UzwUTrkuqo9DxdDfo=$',
    other = NULL
  WHERE name = 'digimaps';


INSERT INTO config_external_accounts (name, username, password, url) VALUES (
  'corelogic',
  'nM5D6jjn9F92Swp4RfxcxA==$$pqq7/mAQwRJwFfJ+duc=$',
  '0/m0OTjQRVbo7xgZMWpWXA==$$taqwaMV4fdg0z60=$',
  'EjWVg3Mgq6QQFYNrmbXUtQ==$$E4ZrX56PFFUEC8nL7LeF$'
);
-- the below inserts generated via the new externalAccounts service
insert into "config_external_accounts" ("environment", "name", "other", "password", "url", "username") values (NULL, 'temp', NULL, '1BZRY1I0OAxguoWkQvd5RA==$$PFWgZw==$', '3LNbybmhaga8YeThXQokjg==$$5X+0dA==$', 'o/A0qL67ILgjR8JP3EGtdA==$$+d+Z1A==$');
insert into "config_external_accounts" ("environment", "name", "other", "password", "url", "username") values (NULL, 'swflmls', NULL, 'UBPYrimpP3n8YvJ+p6Umqg==$$L5Z9ss/xohQRQw==$', 'O8jStOPV8EGSPJsm9Fg8bg==$$SDNpM4o1bYYMURnLg5LTe+kRNMT0I1gSm6lNcNG5J2HRNsZMqgcIdnzI$', 'T82EYdhuBKw94NtsXH+mjg==$$8nZVBE/8kqnHhZPOnLm10HGH/Q==$');
insert into "config_external_accounts" ("environment", "name", "other", "password", "url", "username") values (NULL, 'GLVAR', NULL, 'e8UKAiZiVuELAyq5mO1EaQ==$$rAs72LuCQg==$', 'NtO/DW/kmThioxjRbzKbKg==$$9YNUbOSV7x6fd5seN4DFNDq9MKxddVel2ziR8yfyzcCT1ZbatEgV$', 'sUnHAmxj+PGu/hHWOmqdYg==$$KWXPuyIg5g==$');
insert into "config_external_accounts" ("environment", "name", "other", "password", "url", "username") values (NULL, 'MRED', NULL, 'uPxYOWzapz0KjRr51kx6jQ==$$dlqsBduXU2csFQ==$', '3x1YPEfj0aEIrZubZ5xiyw==$$VZ5XIAbNTtBPD4hwnKGOyuocsWw+pkGg1g53QiFgmum6QarT0VCiClZA+ynVMPU5KbqBpQ==$', 'HDvR8Ju3gsR0/8tXJqxO9A==$$aHeV/60/OSsqWflYSmpiafni$');
insert into "config_external_accounts" ("api_key", "environment", "name", "other", "username") values ('dfrBNIZ87NdKu08Ai5Ox+A==$$ex0wW9bqwGlFT2FMi1XA2Zc6ZUvBmrdYGdMqD0MRF8Q9nrHIV8ShcZq4pk82XgzfzrfHNqiOOEtnJ/d6N0vIcXfMFW2w$', NULL, 'mapbox', '{"upload_key":"yirhkNW3dXrzmdQNdhBOoA==$$6DAYHGr7dERv2ybws108yVB/oGyQ9kbkB4HDQseYAR9br9MDz/rtw4B79voVudNOuR5+6z5SltRKErTr25sXosM/yMVF$","email":"je9PttopRdhSrJsm0oGsNQ==$$7PcwagnNYvmJjhLt1rE9nR55$","main_map":"q6KcZp2Zkf2xyUiKYlLuMg==$$KXWLkaXmGyhAyFm2RFxjmc4Psg==$"}', 'Bt4rLTWhV/gH88Wq59M5OA==$$T1xgJqt9dNayOA==$');
insert into "config_external_accounts" ("environment", "name", "other", "password", "username") values (NULL, 'gmail', NULL, 'u9fDVZjO1CDIsHKun5ou/w==$$VUaqUSzF/DbF3anh$', '1psVljm3BYxquJsh++4cOg==$$jPGSVfsoqq29nyMJOaqD2BKR$');
insert into "config_external_accounts" ("api_key", "environment", "name", "other", "username") values ('3OL+iqeksEj5BO3MtbT44g==$$57uZYbZc9EcVfL6goT9hQJinDqa4MiInIkgT+1G8gt4=$', NULL, 'twilio', '{"number":"TWtx4ZfWyai7kC/X31A+mw==$$ROLGm9aMqlJAOD3l$"}', 'qUAEIQZbPGOh72tZR5tR1g==$$lYQPuGoLTCWe/izRjDLtqNzhBESvGoYN7R2AKWA6d34TNQ==$');
insert into "config_external_accounts" ("api_key", "environment", "name", "other") values ('hYtNUhNZZrS0iqWxSqptTg==$$IfU0GO2h/CU4UAj5KA0em3DV0Z6rud3W8r81WoCQbq+U3HenRQ/e8w==$', NULL, 'lob', '{"test_api_key":"/YzdG+RxcH2EytZEybXxBw==$$8HfodNthIe+a8+ZIRBFtMyVZV5LZ8ENdwFwSMAVXLvDa0MmpYJ9YuQ==$"}');
insert into "config_external_accounts" ("api_key", "environment", "name", "other") values ('yEOfUyY62mgTSMYZKHeJ7w==$$i3XBKUgLAy5buh79nGjtDuflS5DZ03cLE4dz+234kQJwbxgULh+eXg==$', 'production', 'lob', '{"test_api_key":"7KFaCDqJuHiQjUjXvFpvQQ==$$u+mzqs0v4uI3x+XzGn3OxAW13ldRDr7Eb9Z6rIHuJ0f82HqvW9Sbmw==$"}');
insert into "config_external_accounts" ("api_key", "environment", "name", "other", "username") values ('4ZVqEu5ljv/p0Pql3ACK2w==$$WNdFzq8Lbmtes1y9/aGhTDVubBtSjh8CAG0Oz+9LUTpnCKhDoqd/vQ==$', NULL, 'cartodb', '{"api_key_to_us":"OS63qCRArt+CwAr+FjQunQ==$$My5V4phYiB8osLIhOR9Arv8EZC26SgGXKR4s9RCkh194U7T5$","maps":"aVdswRH0WOvprT7DHAgkgw==$$Qn8=$"}', 'yMScIqih2DJy3Sn/YPoYTA==$$1qaYD2H8SkL3xg==$');

insert into "config_external_accounts" ("api_key", "environment", "name", "other") values ('jn5Q+Sb+qSS02fq7r2QZLQ==$$nOoYDWU1R/pwZw74N0CMPmCO9fuU6SdoFlrn4iH3OY14HdJPuffo$', 'production', 'googlemaps', NULL);
insert into "config_external_accounts" ("api_key", "environment", "name", "other", "password", "url", "username") values ('cE0K9JpN0gVBbrRDpNjHcw==$$jGJwvdAwOwP0rQl9gDmXPA+i3SsZ+GRLZmkE3X2XMVvDCk63dFnnqA==$', 'production', 'lob', '{"test_api_key":"8MfcNdNXtCLEv5864FqOZA==$$cQWnqYTWw8xIA7tUU9gewHtyKeUVs3S1piZc7IFVEnKnJQ+fnFLjDw==$"}', NULL, NULL, NULL);


UPDATE jq_task_config
  SET data = '{}'
  WHERE name = 'parcel_update';

UPDATE jq_task_config
  SET data = '{}'
  WHERE name = 'corelogic';

ALTER TABLE config_mls DROP COLUMN username;
ALTER TABLE config_mls DROP COLUMN password;
ALTER TABLE config_mls DROP COLUMN url;
