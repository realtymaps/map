UPDATE data_combined SET address =
  jsonb_set(address::jsonb, '{co}', (address#>'{lines,0}')::jsonb)#-'{lines,0}'#-'{careOf}'
  WHERE (address#>'{careOf}')::text is not null and (address#>'{co}')::text is null;

UPDATE data_combined SET address =
  jsonb_set(jsonb_set(address::jsonb, '{citystate}', (address#>'{lines,-1}')::jsonb), '{street}', (address#>'{lines,-2}')::jsonb)#-'{lines}'
  WHERE  (address#>'{lines}')::text is not null;

UPDATE data_combined SET address = jsonb_set(address::jsonb, '{zip}', to_jsonb('''' || substring((address->'citystate')::text from '(\d{5}-(\d{4})?)"$') || ''''))
  WHERE (address#>'{zip}')::text is null;

UPDATE data_combined SET address = jsonb_set(address::jsonb, '{citystate}', replace((address->'citystate')::text, replace(replace((address->'zip')::text, '''', ''), '"', ''), '')::jsonb)
  WHERE (address#>'{zip}')::text is not null;

UPDATE data_combined SET address = jsonb_set(address::jsonb, '{zip}', replace((address->'zip')::text, '''', '')::jsonb)
  WHERE (address#>'{zip}')::text is not null;

