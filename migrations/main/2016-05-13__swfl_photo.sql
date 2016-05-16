UPDATE config_mls
SET
  listing_data = '{"db": "Property", "field": "LastChangeTimestamp", "table": "RES", "photoRes": {"width": "1024", "height": "768"}, "queryTemplate": "[(__FIELD_NAME__=]YYYY-MM-DD[T]HH:mm:ss[+)]"}'
WHERE
  id = 'swflmls';
