-- column to point to cdn shard for specific images
-- this also is the only photos column that should be exposed to the frontend
-- deterministic cdn shards algo:
-- md5 on filename IE: 2294695_0.jpeg, then ascii integer of first md5 char
-- NOTE: This will always uses the cdn for the first file name in photos. If you want all photos remove where pairs.key = '0'.
ALTER TABLE data_combined add column cdn_photo text NOT NULL DEFAULT '';

UPDATE data_combined up
  SET
  cdn_photo=query.cdn_photo
  FROM
  (select s.data_source_id, s.data_source_uuid,
        c.value->>'url'
        || '/api/photos/resize' || chr(63)
        || 'data_source_id=' || s.data_source_id
        || '&data_source_uuid=' || s.data_source_uuid cdn_photo
          from (
          select data_source_id, data_source_uuid, pairs.value->>'url' url
          FROM data_combined, jsonb_each(data_combined.photos) pairs
          where pairs.key = '0') s
          JOIN config_keystore c on (c.value->>'id')::int = ascii(md5(regexp_replace(s.url, '^.+[/\\]', ''))) % 2
          AND c.namespace = 'cdn_shards' AND c.value->>'id' is not null
  ) query
WHERE photos != '{}' AND up.data_source_id = query.data_source_id and up.data_source_uuid = query.data_source_uuid;
