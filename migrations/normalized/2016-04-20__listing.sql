ALTER TABLE listing drop column cdn_photo;
ALTER TABLE listing add column cdn_photo text NOT NULL DEFAULT '';
