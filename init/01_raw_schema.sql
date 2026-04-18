CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.mock_data (
    id                   INTEGER,
    customer_first_name  VARCHAR(100),
    customer_last_name   VARCHAR(100),
    customer_age         INTEGER,
    customer_email       VARCHAR(200),
    customer_country     VARCHAR(100),
    customer_postal_code VARCHAR(20),
    customer_pet_type    VARCHAR(50),
    customer_pet_name    VARCHAR(100),
    customer_pet_breed   VARCHAR(200),
    seller_first_name    VARCHAR(100),
    seller_last_name     VARCHAR(100),
    seller_email         VARCHAR(200),
    seller_country       VARCHAR(100),
    seller_postal_code   VARCHAR(20),
    product_name         VARCHAR(200),
    product_category     VARCHAR(100),
    product_price        NUMERIC(10,2),
    product_quantity     INTEGER,
    sale_date            TEXT,
    sale_customer_id     INTEGER,
    sale_seller_id       INTEGER,
    sale_product_id      INTEGER,
    sale_quantity        INTEGER,
    sale_total_price     NUMERIC(10,2),
    store_name           VARCHAR(200),
    store_location       VARCHAR(300),
    store_city           VARCHAR(100),
    store_state          VARCHAR(100),
    store_country        VARCHAR(100),
    store_phone          VARCHAR(50),
    store_email          VARCHAR(200),
    pet_category         VARCHAR(100),
    product_weight       NUMERIC(10,2),
    product_color        VARCHAR(50),
    product_size         VARCHAR(50),
    product_brand        VARCHAR(100),
    product_material     VARCHAR(100),
    product_description  TEXT,
    product_rating       NUMERIC(3,2),
    product_reviews      INTEGER,
    product_release_date TEXT,      
    product_expiry_date  TEXT,         
    supplier_name        VARCHAR(200),
    supplier_contact     VARCHAR(200),
    supplier_email       VARCHAR(200),
    supplier_phone       VARCHAR(50),
    supplier_address     VARCHAR(300),
    supplier_city        VARCHAR(100),
    supplier_country     VARCHAR(100)
);


\copy raw.mock_data FROM '/data/MOCK_DATA.csv'  WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy raw.mock_data FROM '/data/MOCK_DATA (1).csv'  WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy raw.mock_data FROM '/data/MOCK_DATA (2).csv'  WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy raw.mock_data FROM '/data/MOCK_DATA (3).csv'  WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy raw.mock_data FROM '/data/MOCK_DATA (4).csv'  WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy raw.mock_data FROM '/data/MOCK_DATA (5).csv'  WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy raw.mock_data FROM '/data/MOCK_DATA (6).csv'  WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy raw.mock_data FROM '/data/MOCK_DATA (7).csv'  WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy raw.mock_data FROM '/data/MOCK_DATA (8).csv'  WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy raw.mock_data FROM '/data/MOCK_DATA (9).csv' WITH (FORMAT CSV, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');


DO $$
BEGIN
    RAISE NOTICE '[raw] mock_data загружено: % строк (ожидается ~10000)',
        (SELECT COUNT(*) FROM raw.mock_data);
END$$;