CREATE TABLE products (
    product_id CHAR(6) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    stock_quantity INT DEFAULT 0,
);

CREATE TABLE salesman (
    salesman_id CHAR(6) PRIMARY KEY,
    full_name VARCHAR(50) NOT NULL,
    phone VARCHAR(13),
	CONSTRAINT chk_phone_format CHECK (phone LIKE '08%' AND LEN(phone) BETWEEN 3 AND 13)

);

CREATE TABLE delivery (
    delivery_id CHAR(6) PRIMARY KEY,
    delivery_date DATE DEFAULT GETDATE(),
    salesman_id CHAR(6) NULL,
    product_id CHAR(6) NOT NULL,
    quantity INT NOT NULL,
    created_at DATE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_delivery_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON UPDATE CASCADE,
    CONSTRAINT fk_delivery_salesman FOREIGN KEY (salesman_id) REFERENCES salesman(salesman_id) ON UPDATE CASCADE
);

CREATE TRIGGER tr_after_delivery_insert
ON delivery
AFTER INSERT
AS
BEGIN
    -- Update stock quantity in products table
    UPDATE p
    SET p.stock_quantity = p.stock_quantity - i.quantity
    FROM products p
    INNER JOIN inserted i ON p.product_id = i.product_id
    
    -- Optional: Add validation to prevent negative stock
    IF EXISTS (SELECT 1 FROM products WHERE stock_quantity < 0)
    BEGIN
        ROLLBACK TRANSACTION
        RAISERROR('Stok tidak mencukupi untuk melakukan delivery', 16, 1)
        RETURN
    END
END



select * from products
select * from salesman
select * from delivery


-- Create sequences for salesman and products
CREATE SEQUENCE seq_salesman_id
    START WITH 1
    INCREMENT BY 1;

CREATE SEQUENCE seq_product_id
    START WITH 1
    INCREMENT BY 1;

-- Create trigger for salesman table to auto-generate IDs with 'SLS' prefix
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_before_salesman_insert')
    DROP TRIGGER tr_before_salesman_insert;

CREATE TRIGGER tr_before_salesman_insert
ON salesman
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO salesman (
        salesman_id,
        full_name,
        phone
    )
    SELECT 
        'SLS' + RIGHT('000' + CAST(NEXT VALUE FOR seq_salesman_id AS VARCHAR(3)), 3),
        i.full_name,
        i.phone
    FROM inserted i;
END;

-- Create trigger for products table to auto-generate IDs with 'PRD' prefix
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_before_product_insert')
    DROP TRIGGER tr_before_product_insert;

CREATE TRIGGER tr_before_product_insert
ON products
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO products (
        product_id,
        product_name,
        stock_quantity
    )
    SELECT 
        'PRD' + RIGHT('000' + CAST(NEXT VALUE FOR seq_product_id AS VARCHAR(3)), 3),
        i.product_name,
        COALESCE(i.stock_quantity, 0)
    FROM inserted i;
END;

-- Create a sequence to generate incremental numbers for delivery_id
CREATE SEQUENCE seq_delivery_id
    START WITH 1
    INCREMENT BY 1;

-- Drop existing trigger if it exists
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_before_delivery_insert')
    DROP TRIGGER tr_before_delivery_insert;

-- Create a trigger that will set delivery_id with 'DEL' prefix before insert
CREATE TRIGGER tr_before_delivery_insert
ON delivery
INSTEAD OF INSERT
AS
BEGIN
    -- Insert into delivery table with modified delivery_id
    INSERT INTO delivery (
        delivery_id, 
        delivery_date, 
        salesman_id, 
        product_id, 
        quantity,
        created_at
    )
    SELECT 
        'DEL' + RIGHT('000' + CAST(NEXT VALUE FOR seq_delivery_id AS VARCHAR(3)), 3),
        i.delivery_date,
        i.salesman_id,
        i.product_id,
        i.quantity,
        COALESCE(i.created_at, CURRENT_TIMESTAMP)
    FROM inserted i;
END;

-- Now you can insert without specifying delivery_id or with a placeholder
INSERT INTO salesman (full_name, phone)
VALUES 
    ('Joko Widodo', '081122334455'),
    ('Siti Nurhaliza', '085566778899');

-- Insert products without specifying product_id
INSERT INTO products (product_name, stock_quantity)
VALUES 
    ('Macbook Pro M3', 15),
    ('iPhone 15 Pro', 30);

select * FROM delivery;
select * FROM salesman;
select * FROM products;