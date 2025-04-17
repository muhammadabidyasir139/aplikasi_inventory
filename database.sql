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

-- Insert dummy data into products table
INSERT INTO products (product_id, product_name, stock_quantity)
VALUES 
    ('PRD001', 'Laptop ASUS TUF Gaming', 25),
    ('PRD002', 'Samsung Galaxy S23', 40);

-- Insert dummy data into salesman table
INSERT INTO salesman (salesman_id, full_name, phone)
VALUES 
    ('SLS001', 'Budi Santoso', '081234567890'),
    ('SLS002', 'Dewi Anggraini', '085678901234');

-- Insert dummy data into delivery table
INSERT INTO delivery (delivery_id, delivery_date, salesman_id, product_id, quantity)
VALUES 
    ('DEL001', '2025-03-10', 'SLS001', 'PRD001', 2),
    ('DEL002', '2025-03-13', 'SLS002', 'PRD002', 5);

select * from products
select * from salesman
select * from delivery

INSERT INTO delivery (delivery_id, delivery_date, salesman_id, product_id, quantity)
VALUES 
    ('DEL001', '2025-03-10', 'SLS001', 'PRD001', 2),
    ('DEL002', '2025-03-13', 'SLS002', 'PRD002', 5);