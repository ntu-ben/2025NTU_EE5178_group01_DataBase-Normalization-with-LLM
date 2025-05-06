DROP DATABASE second_hand_furniture;
CREATE DATABASE second_hand_furniture;
USE second_hand_furniture;

CREATE TABLE User (
    user_id INT PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    category VARCHAR(255) NOT NULL
);

CREATE TABLE `Order` (
    order_id INT PRIMARY KEY,
    date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    user_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

CREATE TABLE Payment (
    payment_id INT PRIMARY KEY,
    method ENUM('CreditCard','BankTransfer') NOT NULL,
    status VARCHAR(50) NOT NULL,
    CHECK (method IN ('CreditCard', 'BankTransfer'))
);

CREATE TABLE Review (
    review_id INT,
    product_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    PRIMARY KEY (review_id, product_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id) ON DELETE CASCADE
);

INSERT INTO User (user_id, first_name, last_name, email) VALUES 
(1, 'John', 'Doe', 'john@example.com'),
(2, 'Jane', 'Smith', 'jane@gmail.com'),
(3, 'Alice', 'Chen', 'alice@example.com');

INSERT INTO Product (product_id, name, price, category) VALUES
(101, 'Wood Chair', 200, 'furniture,used'),
(102, 'Dining Table', 1500, 'furniture,new'),
(103, 'Lamp', 300, 'furniture,used');

INSERT INTO `Order` (order_id, date, total_amount, user_id) VALUES
(201, '2025-03-20', 1700, 1),
(202, '2025-03-22', 300, 2),
(203, '2025-03-25', 2000, 3);

INSERT INTO Payment VALUES
(501, 'CreditCard', 'completed'),
(502, 'BankTransfer', 'pending'),
(503, 'CreditCard', 'completed');

INSERT INTO Review VALUES
(1, 101, 4, 'Good condition'),
(2, 102, 5, 'Brand new'),
(3, 103, 3, 'Fair quality');

CREATE VIEW UserOrders AS
SELECT U.user_id, CONCAT(U.first_name, ' ', U.last_name) AS user_name, O.order_id, O.date, O.total_amount
FROM User U
JOIN `Order` O ON U.user_id = O.user_id;

CREATE VIEW ProductReviews AS
SELECT P.product_id, P.name, R.rating, R.comment
FROM Product P
JOIN Review R ON P.product_id = R.product_id;

CREATE TABLE PotentialCustomer (
    customer_id INT PRIMARY KEY,
    user_id INT,
    guest_id INT,
    customer_type ENUM('User', 'Guest'),
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    CHECK ((user_id IS NOT NULL AND customer_type='User') OR (user_id IS NULL AND customer_type='Guest'))
);

SELECT * FROM User;
SELECT * FROM Product;
SELECT * FROM `Order`;
SELECT * FROM Payment;
SELECT * FROM Review;
SELECT * FROM PotentialCustomer;

-- 檢視 views 的內容
SELECT * FROM UserOrders;
SELECT * FROM ProductReviews;

DROP DATABASE second_hand_furniture;