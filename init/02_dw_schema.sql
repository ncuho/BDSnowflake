CREATE SCHEMA IF NOT EXISTS petstore_dw;


CREATE TABLE petstore_dw.dim_country (
    country_id   SERIAL       PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    CONSTRAINT uq_country UNIQUE (country_name)
);


CREATE TABLE petstore_dw.dim_city (
    city_id    SERIAL       PRIMARY KEY,
    city_name  VARCHAR(100) NOT NULL,
    state_name VARCHAR(100),              
    country_id INT          NOT NULL REFERENCES petstore_dw.dim_country(country_id)
);
CREATE UNIQUE INDEX uq_city
    ON petstore_dw.dim_city (city_name, COALESCE(state_name, ''), country_id);


CREATE TABLE petstore_dw.dim_location (
    location_id SERIAL       PRIMARY KEY,
    address     VARCHAR(300),
    postal_code VARCHAR(20),
    city_id     INT          REFERENCES petstore_dw.dim_city(city_id),     
    country_id  INT          NOT NULL REFERENCES petstore_dw.dim_country(country_id)
);


CREATE TABLE petstore_dw.dim_date (
    date_id     SERIAL      PRIMARY KEY,
    full_date   DATE        NOT NULL,
    day         SMALLINT    NOT NULL,
    month       SMALLINT    NOT NULL,
    month_name  VARCHAR(20) NOT NULL,
    quarter     SMALLINT    NOT NULL,
    year        SMALLINT    NOT NULL,
    day_of_week SMALLINT    NOT NULL,
    day_name    VARCHAR(20) NOT NULL,
    CONSTRAINT uq_date UNIQUE (full_date)
);


CREATE TABLE petstore_dw.dim_pet_breed (
    breed_id          SERIAL       PRIMARY KEY,
    breed_name        VARCHAR(200) NOT NULL,
    pet_type_name     VARCHAR(100) NOT NULL,   
    pet_category_name VARCHAR(100) NOT NULL, 
    CONSTRAINT uq_pet_breed UNIQUE (breed_name, pet_type_name)
);


CREATE TABLE petstore_dw.dim_pet (
    pet_id   SERIAL       PRIMARY KEY,
    pet_name VARCHAR(100),
    breed_id INT          NOT NULL REFERENCES petstore_dw.dim_pet_breed(breed_id)
);


CREATE TABLE petstore_dw.dim_product_category (
    product_category_id   SERIAL       PRIMARY KEY,
    product_category_name VARCHAR(100) NOT NULL,
    CONSTRAINT uq_product_category UNIQUE (product_category_name)
);


CREATE TABLE petstore_dw.dim_brand (
    brand_id   SERIAL       PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL,
    CONSTRAINT uq_brand UNIQUE (brand_name)
);


CREATE TABLE petstore_dw.dim_product (
    product_id          INT           PRIMARY KEY,  
    product_name        VARCHAR(200)  NOT NULL,
    product_category_id INT           NOT NULL REFERENCES petstore_dw.dim_product_category(product_category_id),
    brand_id            INT           REFERENCES petstore_dw.dim_brand(brand_id),
    price               NUMERIC(10,2),
    weight              NUMERIC(10,2),
    color               VARCHAR(50),
    size                VARCHAR(50),      
    material            VARCHAR(100),
    description         TEXT,
    rating              NUMERIC(3,2),
    reviews             INTEGER,
    release_date        DATE,
    expiry_date         DATE
);


CREATE TABLE petstore_dw.dim_customer (
    customer_id INT          PRIMARY KEY,
    first_name  VARCHAR(100),
    last_name   VARCHAR(100),
    age         INTEGER,
    email       VARCHAR(200),
    location_id INT          REFERENCES petstore_dw.dim_location(location_id),
    pet_id      INT          REFERENCES petstore_dw.dim_pet(pet_id)
);


CREATE TABLE petstore_dw.dim_seller (
    seller_id   INT          PRIMARY KEY,
    first_name  VARCHAR(100),
    last_name   VARCHAR(100),
    email       VARCHAR(200),
    location_id INT          REFERENCES petstore_dw.dim_location(location_id)
);


CREATE TABLE petstore_dw.dim_store (
    store_id    SERIAL       PRIMARY KEY,
    store_name  VARCHAR(200) NOT NULL,
    phone       VARCHAR(50),
    email       VARCHAR(200),
    location_id INT          REFERENCES petstore_dw.dim_location(location_id),
    CONSTRAINT uq_store UNIQUE (store_name, location_id)
);


CREATE TABLE petstore_dw.dim_supplier (
    supplier_id   SERIAL       PRIMARY KEY,
    supplier_name VARCHAR(200) NOT NULL,
    contact_name  VARCHAR(200),
    email         VARCHAR(200),
    phone         VARCHAR(50),
    location_id   INT          REFERENCES petstore_dw.dim_location(location_id)
);
CREATE UNIQUE INDEX uq_supplier
    ON petstore_dw.dim_supplier (supplier_name, COALESCE(email, ''));


CREATE TABLE petstore_dw.fact_sales (
    sale_id     SERIAL        PRIMARY KEY,
    date_id     INT           NOT NULL REFERENCES petstore_dw.dim_date(date_id),
    customer_id INT           NOT NULL REFERENCES petstore_dw.dim_customer(customer_id),
    seller_id   INT           NOT NULL REFERENCES petstore_dw.dim_seller(seller_id),
    product_id  INT           NOT NULL REFERENCES petstore_dw.dim_product(product_id),
    store_id    INT           NOT NULL REFERENCES petstore_dw.dim_store(store_id),
    supplier_id INT           NOT NULL REFERENCES petstore_dw.dim_supplier(supplier_id),
    quantity    INTEGER       NOT NULL,
    total_price NUMERIC(10,2) NOT NULL
);


DO $$ BEGIN
    RAISE NOTICE '[petstore_dw] DDL: схема снежинка создана (14 таблиц)';
END$$;