/* create and use database */ 
CREATE DATABASE heritage_railway;
USE heritage_railway;

/* info */ 
CREATE TABLE self (
    StuID varchar(10) NOT NULL,
    Department varchar(10) NOT NULL,
    SchoolYear int DEFAULT 1,
    Name varchar(10) NOT NULL,
    PRIMARY KEY (StuID)
);

INSERT INTO self
VALUES ('b10303016', '經濟系', 4, '莊煥彬');

SELECT DATABASE();
SELECT * FROM self;

/* create table (一次性創建，不要後續再額外設置constraint) */
CREATE TABLE trains(
    running_date DATE DEFAULT '1970-01-01',
    train_id VARCHAR(5),
    train_type VARCHAR(5) NOT NULL,
    origin VARCHAR(20) NOT NULL,
    destination VARCHAR(20) NOT NULL,
    driver_id VARCHAR(10) NOT NULL,
    conductor_id VARCHAR(10) NOT NULL,
    PRIMARY KEY (running_date, train_id)
);
CREATE TABLE attendants(
    running_date DATE DEFAULT '1970-01-01',
    train_id VARCHAR(5),
    seq INT NOT NULL,
    attendants_id VARCHAR(10) NOT NULL,
    PRIMARY KEY (running_date, train_id, seq),
    FOREIGN KEY (running_date, train_id) REFERENCES trains(running_date, train_id)
);
CREATE TABLE timetable(
    running_date DATE DEFAULT '1970-01-01',
    train_id VARCHAR(5),
    station_sequence INT,
    station_name VARCHAR(20) NOT NULL,
    arrival_time TIME,
    drparture_time TIME,
    pass_time TIME,
    meet_train_running_date DATE,
    meet_train_id VARCHAR(5),
    PRIMARY KEY (running_date, train_id, station_sequence),
    FOREIGN KEY (running_date, train_id) REFERENCES trains(running_date, train_id),
    FOREIGN KEY (meet_train_running_date, meet_train_id) REFERENCES timetable(running_date, train_id)
);

CREATE TABLE insurance(
    insurance_id VARCHAR(20) PRIMARY KEY,
    insurance_premium INT NOT NULL DEFAULT 0,
    sum_assured INT NOT NULL DEFAULT 0
);
CREATE TABLE rolling_stock(
    rsid VARCHAR(20) PRIMARY KEY,
    body_length DECIMAL(5,2) NOT NULL,
    last_mantainance_date DATE,
    is_locomotive BOOLEAN DEFAULT 0,
    is_passenger_carriage BOOLEAN,
    is_engineering_carriage BOOLEAN,
    insurance_id VARCHAR(40),
    cannot_couple_with VARCHAR(20),
    CHECK (is_locomotive + is_passenger_carriage + is_engineering_carriage = 1),
    FOREIGN KEY (insurance_id) REFERENCES insurance(insurance_id),
    FOREIGN KEY (cannot_couple_with) REFERENCES rolling_stock(rsid)
);

CREATE TABLE locomotive(
    rsid VARCHAR(20) PRIMARY KEY,
    traction_limit INT,
    engine_type VARCHAR(40) NOT NULL,
    engine_usable BOOLEAN DEFAULT 1,
    FOREIGN KEY (rsid) REFERENCES rolling_stock(rsid)
);
CREATE TABLE passenger_carriage(
    rsid VARCHAR(20) PRIMARY KEY,
    seating_capacity INT NOT NULL DEFAULT 0,
    standing_capacity INT NOT NULL DEFAULT 0,
    door_amt INT NOT NULL DEFAULT 0,
    FOREIGN KEY (rsid) REFERENCES rolling_stock(rsid)
);
CREATE TABLE engineering_carriage(
    rsid VARCHAR(20) PRIMARY KEY,
    functions SET('covered', 'panel', 'caboose'),
    in_use BOOLEAN NOT NULL DEFAULT 0,
    FOREIGN KEY (rsid) REFERENCES rolling_stock(rsid)
);

CREATE TABLE train_composition(
    running_date DATE DEFAULT '1970-01-01',
    train_id VARCHAR(5),
    carriage_sequence INT,
    rsid VARCHAR(20) NOT NULL,
    PRIMARY KEY (running_date, train_id, carriage_sequence),
    FOREIGN KEY (running_date, train_id) REFERENCES trains(running_date, train_id),
    FOREIGN KEY (rsid) REFERENCES rolling_stock(rsid)
);

CREATE TABLE employee(
    employee_id VARCHAR(6) PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    working_hours INT NOT NULL DEFAULT 0,
    insurance_id VARCHAR(40),
    FOREIGN KEY (insurance_id) REFERENCES insurance(insurance_id)
);
CREATE TABLE volunteer(
    employee_id VARCHAR(6) PRIMARY KEY,
    meal_allowance INT NOT NULL DEFAULT 0,
    traffic_allowance INT NOT NULL DEFAULT 0,
    licence SET('driving', 'conducting'),
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
);
CREATE TABLE part_time_worker(
    employee_id VARCHAR(6) PRIMARY KEY,
    salary INT NOT NULL DEFAULT 0,
    general_training BOOLEAN NOT NULL DEFAULT 0,
    broadcaster_training BOOLEAN NOT NULL DEFAULT 0,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) 
);

CREATE TABLE employee_service(
    running_date DATE DEFAULT '1970-01-01',
    train_id VARCHAR(5),
    employee_id VARCHAR(6) NOT NULL,
    rsid VARCHAR(20) NOT NULL,
    PRIMARY KEY (running_date, train_id, employee_id),
    FOREIGN KEY (running_date, train_id) REFERENCES trains(running_date, train_id),
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id),
    FOREIGN KEY (rsid) REFERENCES rolling_stock(rsid)
);

/* insert */
INSERT INTO trains VALUES 
('2025-03-27', '1001', 'Tour', 'Station A', 'Station C', '25001', '25002'),
('2025-03-27', '1002', 'Tour', 'Station C', 'Station A', '25001', '25002'),
('2025-03-27', '1003', 'Tour', 'Station A', 'Station C', '25003', '25004'),
('2025-03-27', '1004', 'Tour', 'Station C', 'Station A', '25003', '25004');

INSERT INTO attendants VALUES
('2025-03-27', '1001', 1, '25501'),
('2025-03-27', '1001', 2, '25502'),
('2025-03-27', '1001', 3, '25503'),
('2025-03-27', '1002', 1, '25501'),
('2025-03-27', '1002', 2, '25502'),
('2025-03-27', '1002', 3, '25503'),
('2025-03-27', '1003', 1, '25504'),
('2025-03-27', '1003', 2,  '25505'),
('2025-03-27', '1003', 3, '25506'),
('2025-03-27', '1004', 1,  '25504'),
('2025-03-27', '1004', 2, '25505'),
('2025-03-27', '1004', 3, '25506');

INSERT INTO timetable VALUES
('2025-03-27', '1001', 1, 'Station A', NULL, '10:00:00', NULL, NULL, NULL),
('2025-03-27', '1001', 2, 'Station B', '10:03:00', '10:05:00', NULL, NULL, NULL),
('2025-03-27', '1001', 3, 'Station C', '10:08:00', NULL, NULL, NULL, NULL),
('2025-03-27', '1002', 1, 'Station C', NULL, '10:10:00', NULL, NULL, NULL),
('2025-03-27', '1002', 2, 'Station B', '10:13:00', '10:15:00', NULL, NULL, NULL),
('2025-03-27', '1002', 3, 'Station A', '10:18:00', NULL, NULL, NULL, NULL),
('2025-03-27', '1003', 1, 'Station A', NULL, '10:10:00', NULL, NULL, NULL),
('2025-03-27', '1003', 2, 'Station B', '10:13:00', '10:15:00', NULL, NULL, NULL),
('2025-03-27', '1003', 3, 'Station C', '10:18:00', NULL, NULL, NULL, NULL),
('2025-03-27', '1004', 1, 'Station C', NULL, '10:20:00', NULL, NULL, NULL),
('2025-03-27', '1004', 2, 'Station B', '10:23:00', '10:25:00', NULL, NULL, NULL),
('2025-03-27', '1004', 3, 'Station A', '10:28:00', NULL, NULL, NULL, NULL);

UPDATE timetable SET 
meet_train_running_date = '2025-03-27', meet_train_id = '1003'
WHERE running_date = '2025-03-27' AND train_id = '1002' AND station_sequence = 2;

UPDATE timetable SET 
meet_train_running_date = '2025-03-27', meet_train_id = '1002'
WHERE running_date = '2025-03-27' AND train_id = '1003' AND station_sequence = 2;

INSERT INTO insurance VALUES
('202503001', 100, 1000000),
('202503002', 500, 5000000),
('202503003', 500, 5000000);

INSERT INTO rolling_stock VALUES
('20C10001', 10, NULL, 0, 1, 0, '202503002', NULL),
('20C10002', 10, NULL, 0, 1, 0, '202503002', NULL),
('20C10003', 10, NULL, 0, 1, 0, '202503002', NULL),
('30G10001', 15, NULL, 0, 1, 0, '202503002', NULL),
('30G10002', 15, NULL, 0, 1, 0, '202503002', NULL),
('3CK501', 6.5, NULL, 0, 1, 0, '202503002', NULL),
('D101', 5, '2025-01-01', 1, 0, 0, '202503003', NULL),
('D102', 5, '2025-01-01', 1, 0, 0, '202503003', NULL),
('D103', 5, '2025-01-01', 1, 0, 0, '202503002', NULL),
('D104', 5, NULL, 1, 0, 0, NULL, NULL),
('10F101', 7, NULL, 0, 0, 1, NULL, NULL),
('10F102', 7, NULL, 0, 0, 1, NULL, NULL),
('15GK201', 7, NULL, 0, 0, 1, NULL, NULL);

UPDATE rolling_stock SET
cannot_couple_with = '15GK201'
WHERE rsid = '3CK501';

UPDATE rolling_stock SET
cannot_couple_with = '3CK501'
WHERE rsid = '15GK201';

INSERT INTO locomotive VALUES
('D101', 200 ,'Diesel', 1),
('D102', 200 ,'Diesel', 1),
('D103', 200 ,'Diesel', 1),
('D104', 200 ,'Diesel', 1);

INSERT INTO passenger_carriage VALUE
('20C10001', 30, 10, 4),
('20C10002', 30, 10, 4),
('20C10003', 30, 10, 4),
('30G10001', 20, 20, 6),
('30G10002', 20, 20, 6),
('3CK501', 5, 10, 2);

INSERT INTO engineering_carriage VALUE
('10F101', (''), 1),
('10F102', (''), 0),
('15GK201', ('covered,panel,caboose'), 1);

INSERT INTO train_composition VALUE
('2025-03-27', '1001', 1, 'D101'),
('2025-03-27', '1001', 2, '20C10001'),
('2025-03-27', '1001', 3, '20C10002'),
('2025-03-27', '1001', 4, '30G10001'),
('2025-03-27', '1001', 5, 'D102'),
('2025-03-27', '1002', 1, 'D101'),
('2025-03-27', '1002', 2, '20C10001'),
('2025-03-27', '1002', 3, '20C10002'),
('2025-03-27', '1002', 4, '30G10001'),
('2025-03-27', '1002', 5, 'D102'),
('2025-03-27', '1003', 1, 'D103'),
('2025-03-27', '1003', 2, '3CK501'),
('2025-03-27', '1003', 3, '30G10002'),
('2025-03-27', '1003', 4, '20C10003'),
('2025-03-27', '1003', 5, 'D104'),
('2025-03-27', '1004', 1, 'D103'),
('2025-03-27', '1004', 2, '3CK501'),
('2025-03-27', '1004', 3, '30G10002'),
('2025-03-27', '1004', 4, '20C10003'),
('2025-03-27', '1004', 5, 'D104');

INSERT INTO employee VALUE
('25001', 'Employee A', 100, '202503001'),
('25002', 'Employee B', 90, '202503001'),
('25003', 'Employee I', 50, NULL),
('25004', 'Employee J', 40, NULL),
('25501', 'Employee C', 72, '202503001'),
('25502', 'Employee D', 48, '202503001'),
('25503', 'Employee E', 40, '202503001'),
('25504', 'Employee F', 16, '202503001'),
('25505', 'Employee G', 24, '202503001'),
('25506', 'Employee H', 16, '202503001');

INSERT INTO volunteer VALUE
('25001', 800, 0, ('driving,conducting')),
('25002', 800, 1000, ('driving,conducting')),
('25003', 720, 0, ('driving,conducting')),
('25004', 48, 0, ('conducting'));

INSERT INTO part_time_worker VALUE
('25001', 4000, 1, 1),
('25002', 2000, 1, 1),
('25501', 14400, 1, 1),
('25502', 9600, 1, 1),
('25503', 8000, 1, 0),
('25504', 3200, 1, 0),
('25505', 4800, 1, 1),
('25506', 3200, 1, 0);

INSERT INTO employee_service VALUE
('2025-03-27', '1001', '25001', 'D101'),
('2025-03-27', '1001', '25501', '20C10001'),
('2025-03-27', '1001', '25502', '20C10002'),
('2025-03-27', '1001', '25503', '30G10001'),
('2025-03-27', '1001', '25002', 'D102'),
('2025-03-27', '1002', '25001', 'D101'),
('2025-03-27', '1002', '25501', '20C10001'),
('2025-03-27', '1002', '25502', '20C10002'),
('2025-03-27', '1002', '25503', '30G10001'),
('2025-03-27', '1002', '25002', 'D102'),
('2025-03-27', '1003', '25004', 'D103'),
('2025-03-27', '1003', '25504', '3CK501'),
('2025-03-27', '1003', '25505', '30G10002'),
('2025-03-27', '1003', '25506', '20C10003'),
('2025-03-27', '1003', '25003', 'D104'),
('2025-03-27', '1004', '25004', 'D103'),
('2025-03-27', '1004', '25504', '3CK501'),
('2025-03-27', '1004', '25505', '30G10002'),
('2025-03-27', '1004', '25506', '20C10003'),
('2025-03-27', '1004', '25003', 'D104');


/* create two views */
CREATE VIEW EMPLOYEE_INSURANCE
AS SELECT E.employee_id, E.name, I.insurance_id, I.insurance_premium, I.sum_assured 
FROM employee AS E, insurance AS I
WHERE E.insurance_id = I.insurance_id;

CREATE VIEW WORKER_IN_CARRIAGE
AS SELECT TC.running_date, TC.train_id, TC.carriage_sequence, TC.rsid, E.employee_id, E.name
FROM employee AS E, train_composition AS TC, employee_service AS ES
WHERE TC.running_date = ES.running_date AND TC.train_id = ES.train_id AND TC.rsid = ES.rsid AND  E.employee_id = ES.employee_id
ORDER BY train_id, carriage_sequence;

/* select from all tables and views */
SELECT * FROM trains;
SELECT * FROM attendants;
SELECT * FROM timetable;
SELECT * FROM rolling_stock;
SELECT * FROM locomotive;
SELECT * FROM passenger_carriage;
SELECT * FROM engineering_carriage;
SELECT * FROM train_composition;
SELECT * FROM employee;
SELECT * FROM volunteer;
SELECT * FROM part_time_worker;
SELECT * FROM employee_service;
SELECT * FROM insurance;
SELECT * FROM EMPLOYEE_INSURANCE;
SELECT * FROM WORKER_IN_CARRIAGE;

/* drop database */
DROP DATABASE heritage_railway;