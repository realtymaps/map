-- new index for new field as it will be used
DROP INDEX data_normalization_config_data_source_id_list_ordering_idx;
CREATE INDEX ON data_normalization_config (data_source_id, data_type, list ASC, ordering ASC);
