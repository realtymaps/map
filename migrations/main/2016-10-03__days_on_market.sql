ALTER TABLE data_combined
ADD COLUMN creation_date TIMESTAMP WITHOUT TIME ZONE,
ADD COLUMN days_on_market_cumulative INTEGER,
ADD COLUMN days_on_market_filter INTEGER;
