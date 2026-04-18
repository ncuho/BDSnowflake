CREATE OR REPLACE FUNCTION petstore_dw.parse_date(p TEXT)
RETURNS DATE LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    IF p IS NULL OR trim(p) = '' THEN RETURN NULL; END IF;
    RETURN TO_DATE(trim(p), 'MM/DD/YYYY');
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END;$$;


INSERT INTO petstore_dw.dim_country (country_name)
SELECT DISTINCT country
FROM (
    SELECT NULLIF(TRIM(customer_country), '') AS country FROM raw.mock_data
    UNION
    SELECT NULLIF(TRIM(seller_country),   '') FROM raw.mock_data
    UNION
    SELECT NULLIF(TRIM(store_country),    '') FROM raw.mock_data
    UNION
    SELECT NULLIF(TRIM(supplier_country), '') FROM raw.mock_data
) t
WHERE country IS NOT NULL
ORDER BY country
ON CONFLICT (country_name) DO NOTHING;


INSERT INTO petstore_dw.dim_city (city_name, state_name, country_id)
SELECT DISTINCT
    TRIM(m.store_city),
    NULLIF(TRIM(m.store_state), ''),
    c.country_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country c ON c.country_name = TRIM(m.store_country)
WHERE TRIM(m.store_city) <> '' AND m.store_city IS NOT NULL
ON CONFLICT DO NOTHING;


INSERT INTO petstore_dw.dim_city (city_name, state_name, country_id)
SELECT DISTINCT
    TRIM(m.supplier_city),
    NULL,
    c.country_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country c ON c.country_name = TRIM(m.supplier_country)
WHERE TRIM(m.supplier_city) <> '' AND m.supplier_city IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM petstore_dw.dim_city dc
       WHERE dc.city_name  = TRIM(m.supplier_city)
         AND dc.country_id = c.country_id
  );


INSERT INTO petstore_dw.dim_location (address, postal_code, city_id, country_id)
SELECT DISTINCT
    NULL::VARCHAR,
    NULLIF(TRIM(m.customer_postal_code), ''),
    NULL::INT,
    c.country_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country c ON c.country_name = TRIM(m.customer_country)
WHERE m.customer_country IS NOT NULL AND TRIM(m.customer_country) <> '';


INSERT INTO petstore_dw.dim_location (address, postal_code, city_id, country_id)
SELECT DISTINCT
    NULL::VARCHAR,
    NULLIF(TRIM(m.seller_postal_code), ''),
    NULL::INT,
    c.country_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country c ON c.country_name = TRIM(m.seller_country)
WHERE m.seller_country IS NOT NULL AND TRIM(m.seller_country) <> '';


INSERT INTO petstore_dw.dim_location (address, postal_code, city_id, country_id)
SELECT DISTINCT
    NULLIF(TRIM(m.store_location), ''),
    NULL::VARCHAR,
    ci.city_id,
    c.country_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country c  ON c.country_name = TRIM(m.store_country)
JOIN petstore_dw.dim_city    ci ON ci.city_name    = TRIM(m.store_city)
                                AND ci.country_id   = c.country_id
WHERE m.store_name IS NOT NULL AND TRIM(m.store_name) <> '';


INSERT INTO petstore_dw.dim_location (address, postal_code, city_id, country_id)
SELECT DISTINCT
    NULLIF(TRIM(m.supplier_address), ''),
    NULL::VARCHAR,
    ci.city_id,
    c.country_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country c  ON c.country_name = TRIM(m.supplier_country)
JOIN petstore_dw.dim_city    ci ON ci.city_name    = TRIM(m.supplier_city)
                                AND ci.country_id   = c.country_id
                                AND ci.state_name  IS NULL
WHERE m.supplier_name IS NOT NULL AND TRIM(m.supplier_name) <> '';


INSERT INTO petstore_dw.dim_date (
    full_date, day, month, month_name,
    quarter, year, day_of_week, day_name
)
SELECT DISTINCT
    d,
    EXTRACT(DAY     FROM d)::SMALLINT,
    EXTRACT(MONTH   FROM d)::SMALLINT,
    TO_CHAR(d, 'Month'),
    EXTRACT(QUARTER FROM d)::SMALLINT,
    EXTRACT(YEAR    FROM d)::SMALLINT,
    EXTRACT(DOW     FROM d)::SMALLINT + 1,
    TO_CHAR(d, 'Day')
FROM (
    SELECT petstore_dw.parse_date(sale_date)            AS d FROM raw.mock_data
    UNION
    SELECT petstore_dw.parse_date(product_release_date) FROM raw.mock_data
    UNION
    SELECT petstore_dw.parse_date(product_expiry_date)  FROM raw.mock_data
) dates
WHERE d IS NOT NULL
ORDER BY d
ON CONFLICT (full_date) DO NOTHING;


INSERT INTO petstore_dw.dim_pet_breed (breed_name, pet_type_name, pet_category_name)
SELECT DISTINCT
    TRIM(m.customer_pet_breed),
    TRIM(m.customer_pet_type),
    TRIM(m.pet_category)
FROM raw.mock_data m
WHERE m.customer_pet_breed IS NOT NULL AND TRIM(m.customer_pet_breed) <> ''
  AND m.customer_pet_type  IS NOT NULL AND TRIM(m.customer_pet_type)  <> ''
  AND m.pet_category        IS NOT NULL AND TRIM(m.pet_category)        <> ''
ON CONFLICT (breed_name, pet_type_name) DO NOTHING;


INSERT INTO petstore_dw.dim_pet (pet_name, breed_id)
SELECT DISTINCT
    TRIM(m.customer_pet_name),
    pb.breed_id
FROM raw.mock_data m
JOIN petstore_dw.dim_pet_breed pb
    ON  pb.breed_name    = TRIM(m.customer_pet_breed)
    AND pb.pet_type_name = TRIM(m.customer_pet_type)
WHERE m.customer_pet_name IS NOT NULL AND TRIM(m.customer_pet_name) <> '';


INSERT INTO petstore_dw.dim_product_category (product_category_name)
SELECT DISTINCT TRIM(product_category)
FROM raw.mock_data
WHERE product_category IS NOT NULL AND TRIM(product_category) <> ''
ON CONFLICT (product_category_name) DO NOTHING;


INSERT INTO petstore_dw.dim_brand (brand_name)
SELECT DISTINCT TRIM(product_brand)
FROM raw.mock_data
WHERE product_brand IS NOT NULL AND TRIM(product_brand) <> ''
ON CONFLICT (brand_name) DO NOTHING;


INSERT INTO petstore_dw.dim_product (
    product_id, product_name, product_category_id, brand_id,
    price, weight, color, size, material,
    description, rating, reviews, release_date, expiry_date
)
SELECT DISTINCT ON (m.sale_product_id)
    m.sale_product_id,
    TRIM(m.product_name),
    pc.product_category_id,
    b.brand_id,
    m.product_price,
    m.product_weight,
    NULLIF(TRIM(m.product_color),    ''),
    NULLIF(TRIM(m.product_size),     ''),
    NULLIF(TRIM(m.product_material), ''),
    m.product_description,
    m.product_rating,
    m.product_reviews,
    petstore_dw.parse_date(m.product_release_date),
    petstore_dw.parse_date(m.product_expiry_date)
FROM raw.mock_data m
JOIN petstore_dw.dim_product_category pc
    ON pc.product_category_name = TRIM(m.product_category)
LEFT JOIN petstore_dw.dim_brand b
    ON b.brand_name = TRIM(m.product_brand)
WHERE m.sale_product_id IS NOT NULL
ORDER BY m.sale_product_id, m.id
ON CONFLICT (product_id) DO NOTHING;


INSERT INTO petstore_dw.dim_customer (
    customer_id, first_name, last_name, age, email, location_id, pet_id
)
SELECT DISTINCT ON (m.sale_customer_id)
    m.sale_customer_id,
    TRIM(m.customer_first_name),
    TRIM(m.customer_last_name),
    m.customer_age,
    TRIM(m.customer_email),
    loc.location_id,
    p.pet_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country c
    ON c.country_name = TRIM(m.customer_country)
LEFT JOIN petstore_dw.dim_location loc
    ON  loc.country_id  = c.country_id
    AND loc.city_id    IS NULL
    AND loc.address    IS NULL
    AND COALESCE(loc.postal_code, '') = COALESCE(NULLIF(TRIM(m.customer_postal_code), ''), '')
LEFT JOIN petstore_dw.dim_pet_breed pb
    ON  pb.breed_name    = TRIM(m.customer_pet_breed)
    AND pb.pet_type_name = TRIM(m.customer_pet_type)
LEFT JOIN petstore_dw.dim_pet p
    ON  p.pet_name = TRIM(m.customer_pet_name)
    AND p.breed_id = pb.breed_id
WHERE m.sale_customer_id IS NOT NULL
ORDER BY m.sale_customer_id, m.id
ON CONFLICT (customer_id) DO NOTHING;


INSERT INTO petstore_dw.dim_seller (
    seller_id, first_name, last_name, email, location_id
)
SELECT DISTINCT ON (m.sale_seller_id)
    m.sale_seller_id,
    TRIM(m.seller_first_name),
    TRIM(m.seller_last_name),
    TRIM(m.seller_email),
    loc.location_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country c
    ON c.country_name = TRIM(m.seller_country)
LEFT JOIN petstore_dw.dim_location loc
    ON  loc.country_id  = c.country_id
    AND loc.city_id    IS NULL
    AND loc.address    IS NULL
    AND COALESCE(loc.postal_code, '') = COALESCE(NULLIF(TRIM(m.seller_postal_code), ''), '')
WHERE m.sale_seller_id IS NOT NULL
ORDER BY m.sale_seller_id, m.id
ON CONFLICT (seller_id) DO NOTHING;


INSERT INTO petstore_dw.dim_store (store_name, phone, email, location_id)
SELECT DISTINCT ON (m.store_name, m.store_city, m.store_location)
    TRIM(m.store_name),
    NULLIF(TRIM(m.store_phone), ''),
    NULLIF(TRIM(m.store_email), ''),
    loc.location_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country  c   ON c.country_name  = TRIM(m.store_country)
JOIN petstore_dw.dim_city     ci  ON ci.city_name    = TRIM(m.store_city)
                                  AND ci.country_id   = c.country_id
JOIN petstore_dw.dim_location loc ON loc.city_id     = ci.city_id
                                  AND COALESCE(loc.address, '') =
                                      COALESCE(NULLIF(TRIM(m.store_location), ''), '')
WHERE m.store_name IS NOT NULL AND TRIM(m.store_name) <> ''
ORDER BY m.store_name, m.store_city, m.store_location, m.id
ON CONFLICT (store_name, location_id) DO NOTHING;


INSERT INTO petstore_dw.dim_supplier (
    supplier_name, contact_name, email, phone, location_id
)
SELECT DISTINCT ON (m.supplier_name, m.supplier_email)
    TRIM(m.supplier_name),
    NULLIF(TRIM(m.supplier_contact), ''),
    NULLIF(TRIM(m.supplier_email),   ''),
    NULLIF(TRIM(m.supplier_phone),   ''),
    loc.location_id
FROM raw.mock_data m
JOIN petstore_dw.dim_country  c   ON c.country_name  = TRIM(m.supplier_country)
JOIN petstore_dw.dim_city     ci  ON ci.city_name    = TRIM(m.supplier_city)
                                  AND ci.country_id   = c.country_id
                                  AND ci.state_name  IS NULL
JOIN petstore_dw.dim_location loc ON loc.city_id     = ci.city_id
                                  AND COALESCE(loc.address, '') =
                                      COALESCE(NULLIF(TRIM(m.supplier_address), ''), '')
WHERE m.supplier_name IS NOT NULL AND TRIM(m.supplier_name) <> ''
ORDER BY m.supplier_name, m.supplier_email, m.id
ON CONFLICT DO NOTHING;


INSERT INTO petstore_dw.fact_sales (
    date_id, customer_id, seller_id, product_id,
    store_id, supplier_id, quantity, total_price
)
SELECT
    dd.date_id,
    m.sale_customer_id,
    m.sale_seller_id,
    m.sale_product_id,
    ds.store_id,
    dsupp.supplier_id,
    m.sale_quantity,
    m.sale_total_price
FROM raw.mock_data m
JOIN petstore_dw.dim_date dd
    ON dd.full_date = petstore_dw.parse_date(m.sale_date)
JOIN petstore_dw.dim_country  sc
    ON sc.country_name  = TRIM(m.store_country)
JOIN petstore_dw.dim_city     sci
    ON sci.city_name    = TRIM(m.store_city)
    AND sci.country_id  = sc.country_id
JOIN petstore_dw.dim_location sloc
    ON sloc.city_id     = sci.city_id
    AND COALESCE(sloc.address, '') = COALESCE(NULLIF(TRIM(m.store_location), ''), '')
JOIN petstore_dw.dim_store    ds
    ON ds.store_name    = TRIM(m.store_name)
    AND ds.location_id  = sloc.location_id
JOIN petstore_dw.dim_country  supc
    ON supc.country_name  = TRIM(m.supplier_country)
JOIN petstore_dw.dim_city     supci
    ON supci.city_name    = TRIM(m.supplier_city)
    AND supci.country_id  = supc.country_id
    AND supci.state_name IS NULL
JOIN petstore_dw.dim_location suploc
    ON suploc.city_id     = supci.city_id
    AND COALESCE(suploc.address, '') = COALESCE(NULLIF(TRIM(m.supplier_address), ''), '')
JOIN petstore_dw.dim_supplier dsupp
    ON dsupp.supplier_name = TRIM(m.supplier_name)
    AND dsupp.location_id  = suploc.location_id
WHERE m.sale_customer_id IS NOT NULL
  AND m.sale_seller_id   IS NOT NULL
  AND m.sale_product_id  IS NOT NULL
  AND petstore_dw.parse_date(m.sale_date) IS NOT NULL;