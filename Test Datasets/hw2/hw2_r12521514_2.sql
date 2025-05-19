
CREATE DATABASE GameDevProjectMgmt;
USE GameDevProjectMgmt;

-- Project
CREATE TABLE Project (
    project_id INT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    budget DECIMAL(12, 2) CHECK (budget > 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CHECK (end_date >= start_date)
);

-- Developer
CREATE TABLE Developer (
    developer_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    skill_set VARCHAR(255) NOT NULL
);

-- Game
CREATE TABLE Game (
    game_id INT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    genre VARCHAR(20) CHECK (genre IN ('action', 'RPG', 'shooting')) NOT NULL,
    platform VARCHAR(100) NOT NULL
);

-- Task (moved developer_id here before data insertions)
CREATE TABLE Task (
    task_id INT PRIMARY KEY,
    task_name VARCHAR(100) NOT NULL,
    deadline DATE NOT NULL,
    description TEXT,
    developer_id INT,
    CHECK (CHAR_LENGTH(task_name) >= 3),
    FOREIGN KEY (developer_id) REFERENCES Developer(developer_id)
);

-- Client
CREATE TABLE Client (
    client_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    company VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- Publisher
CREATE TABLE Publisher (
    publisher_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    company VARCHAR(100) NOT NULL
);

-- Software Tool
CREATE TABLE SoftwareTool (
    tool_id INT PRIMARY KEY,
    tool_name VARCHAR(100) NOT NULL,
    license_type VARCHAR(50) NOT NULL
);

-- =========================
-- Weak Entity and Specializations
-- =========================

-- Milestone (Weak entity, depends on Project)
CREATE TABLE Milestone (
    milestone_id INT,
    project_id INT,
    milestone_name VARCHAR(100) NOT NULL,
    due_date DATE NOT NULL,
    PRIMARY KEY (milestone_id, project_id),
    FOREIGN KEY (project_id) REFERENCES Project(project_id)
        ON DELETE CASCADE
);

-- Full-time Developer
CREATE TABLE FullTimeDeveloper (
    developer_id INT PRIMARY KEY,
    office_location VARCHAR(100) NOT NULL,
    FOREIGN KEY (developer_id) REFERENCES Developer(developer_id)
        ON DELETE CASCADE
);

-- Freelancer (multi-valued)
CREATE TABLE Freelancer (
    developer_id INT,
    contract_sign_date DATE NOT NULL,
    PRIMARY KEY (developer_id, contract_sign_date),
    FOREIGN KEY (developer_id) REFERENCES Developer(developer_id)
        ON DELETE CASCADE
);

-- Employee
CREATE TABLE Employee (
    developer_id INT PRIMARY KEY,
    FOREIGN KEY (developer_id) REFERENCES Developer(developer_id)
        ON DELETE CASCADE
);

-- Product Manager (simplified to avoid redundancy)
CREATE TABLE ProductManager (
    developer_id INT PRIMARY KEY,
    FOREIGN KEY (developer_id) REFERENCES Developer(developer_id)
        ON DELETE CASCADE
);

-- Business Partner (union)
CREATE TABLE BusinessPartner (
    partner_id INT PRIMARY KEY,
    type VARCHAR(20) CHECK (type IN ('Client', 'Publisher')) NOT NULL
);

-- =========================
-- Relationships
-- =========================

-- Project-Developer (M:N)
CREATE TABLE ProjectDeveloper (
    project_id INT,
    developer_id INT,
    PRIMARY KEY (project_id, developer_id),
    FOREIGN KEY (project_id) REFERENCES Project(project_id),
    FOREIGN KEY (developer_id) REFERENCES Developer(developer_id)
);

-- Game-Project (1:N)
ALTER TABLE Game
ADD project_id INT,
ADD FOREIGN KEY (project_id) REFERENCES Project(project_id);

-- Client-Project (1:N)
ALTER TABLE Project
ADD client_id INT,
ADD FOREIGN KEY (client_id) REFERENCES Client(client_id);

-- Software Tool-Project (M:N)
CREATE TABLE ProjectTool (
    project_id INT,
    tool_id INT,
    PRIMARY KEY (project_id, tool_id),
    FOREIGN KEY (project_id) REFERENCES Project(project_id),
    FOREIGN KEY (tool_id) REFERENCES SoftwareTool(tool_id)
);

-- Task dependencies (recursive)
CREATE TABLE TaskDependency (
    task_id INT,
    depends_on_task_id INT,
    PRIMARY KEY (task_id, depends_on_task_id),
    FOREIGN KEY (task_id) REFERENCES Task(task_id),
    FOREIGN KEY (depends_on_task_id) REFERENCES Task(task_id)
);

-- Insert sample data

INSERT INTO Client VALUES 
(401, 'PlayHub', 'PlayHub Co.', '111-222-3333', 'games@playhub.com'),
(402, 'NextGen', 'NextGen Ltd.', '555-888-7777', 'contact@nextgen.com'),
(403, 'VR Solutions', 'VRS Inc.', '222-333-4444', 'contact@vrs.com');

INSERT INTO Publisher VALUES 
(501, 'GameForge', 'GF International'),
(502, 'NextPlay', 'NextPlay Ltd');

INSERT INTO BusinessPartner VALUES 
(401, 'Client'),
(403, 'Client'),
(501, 'Publisher');

INSERT INTO Project VALUES 
(10, 'Cyber Heist', 95000.00, '2024-04-01', '2025-03-31', 403),
(11, 'Dragon Legacy', 110000.00, '2024-05-15', '2025-04-30', 402),
(12, 'Skyline Racer', 85000.00, '2024-06-01', '2025-02-28', 401);

INSERT INTO Developer VALUES 
(201, 'Dave', 'dave@studio.com', 'Unreal, Blueprint'),
(202, 'Emma', 'emma@studio.com', '3D Modeling, Blender'),
(203, 'Frank', 'frank@studio.com', 'Gameplay Design, C#'),
(204, 'Grace', 'grace@studio.com', 'UI/UX, Figma');

INSERT INTO FullTimeDeveloper VALUES 
(201, 'HQ - Room 10'),
(204, 'HQ - Room 11');

INSERT INTO Freelancer VALUES 
(202, '2024-03-10'),
(202, '2024-09-01'),
(203, '2024-04-15');

INSERT INTO Employee VALUES 
(201),
(204);

INSERT INTO ProductManager VALUES (201);

INSERT INTO Game VALUES 
(301, 'Digital Uprising', 'action', 'Console', 10),
(302, 'Winged Realms', 'RPG', 'PC', 11),
(303, 'Turbo Trails', 'shooting', 'Mobile', 12);

INSERT INTO Task VALUES 
(401, 'Main Menu Design', '2024-07-10', 'Create interactive UI with animations', 204),
(402, 'Enemy AI', '2024-08-15', 'Build adaptive enemy logic', 201),
(403, '3D Car Models', '2024-07-01', 'Design vehicles for Skyline Racer', 202),
(404, 'Combat System', '2024-09-05', 'Implement player combat interactions', 203);

INSERT INTO SoftwareTool VALUES 
(701, 'Blender', 'Open Source'),
(702, 'Figma', 'Freemium'),
(703, 'Godot Engine', 'Open Source');

INSERT INTO Milestone VALUES 
(1, 10, 'Vertical Slice Ready', '2024-09-30'),
(2, 11, 'Playable Alpha', '2024-11-15'),
(3, 12, 'Closed Beta Test', '2025-01-10');

INSERT INTO ProjectDeveloper VALUES 
(10, 201),
(10, 202),
(11, 203),
(12, 204),
(12, 202);

INSERT INTO ProjectTool VALUES 
(10, 701),
(11, 702),
(12, 703);

INSERT INTO TaskDependency VALUES 
(402, 401),
(404, 402),
(403, 401);

-- =========================
-- Views
-- =========================

CREATE VIEW DeveloperTasks AS
SELECT d.name AS DeveloperName, t.task_name, t.deadline
FROM Developer d
LEFT JOIN Task t ON d.developer_id = t.developer_id;

CREATE VIEW ProjectMilestones AS
SELECT p.title AS ProjectTitle, m.milestone_name, m.due_date
FROM Project p
JOIN Milestone m ON p.project_id = m.project_id;


DROP DATABASE GameDevProjectMgmt;