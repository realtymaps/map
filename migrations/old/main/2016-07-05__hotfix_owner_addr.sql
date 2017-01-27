UPDATE data_combined SET owner_address =
  jsonb_set(owner_address::jsonb, '{co}', (owner_address#>'{lines,0}')::jsonb)#-'{lines,0}'#-'{careOf}'
  WHERE (owner_address#>'{careOf}')::text is not null and (owner_address#>'{co}')::text is null;

UPDATE data_combined SET owner_address =
  jsonb_set(jsonb_set(owner_address::jsonb, '{citystate}', (owner_address#>'{lines,-1}')::jsonb), '{street}', (owner_address#>'{lines,-2}')::jsonb)#-'{lines}'
  WHERE  (owner_address#>'{lines}')::text is not null;

UPDATE data_combined SET owner_address = jsonb_set(owner_address::jsonb, '{zip}', to_jsonb('''' || substring((owner_address->'citystate')::text from '(\d{5}-(\d{4})?)"$') || ''''))
  WHERE (owner_address#>'{zip}')::text is null;

UPDATE data_combined SET owner_address = jsonb_set(owner_address::jsonb, '{citystate}', replace((owner_address->'citystate')::text, replace(replace((owner_address->'zip')::text, '''', ''), '"', ''), '')::jsonb)
  WHERE (owner_address#>'{zip}')::text is not null;

UPDATE data_combined SET owner_address = jsonb_set(owner_address::jsonb, '{zip}', replace((owner_address->'zip')::text, '''', '')::jsonb)
  WHERE (owner_address#>'{zip}')::text is not null;
