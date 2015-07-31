UPDATE data_normalization_config SET transform = replace(transform, 'validation', 'validators');
UPDATE data_normalization_config SET transform = replace(transform, '"choices"', '"passUnmapped": true, "map"');
UPDATE data_normalization_config SET transform = replace(transform, 'choice', 'map');
