/* create and use database */
CREATE DATABASE AnimeDB;
USE AnimeDB;

/* info */
CREATE TABLE self (
    StuID varchar(10) NOT NULL,
    Department varchar(10) NOT NULL,
    SchoolYear int DEFAULT 1,
    Name varchar(10) NOT NULL,
    PRIMARY KEY (StuID)
);

INSERT INTO self
VALUES ('r12921a13', '電機所', 2, '王靖婷');

SELECT DATABASE();
SELECT * FROM self;


/* create table */
CREATE TABLE Animation_Studio (
    name VARCHAR(100) NOT NULL,
    foundation_date DATE NOT NULL,
    num_of_workers INT NOT NULL CHECK (num_of_workers >= 0),
    PRIMARY KEY (name)
);

CREATE TABLE Comic_Author (
    name VARCHAR(100) NOT NULL,
    birthday DATE NOT NULL,
    education VARCHAR(100) NOT NULL,
    PRIMARY KEY (name)
);

CREATE TABLE Screen_Writer (
    name VARCHAR(100) NOT NULL,
    birthday DATE NOT NULL,
    education VARCHAR(100) NOT NULL,
    PRIMARY KEY (name)
);

CREATE TABLE Animation (
	id INT NOT NULL CHECK (id > 0),
    title VARCHAR(100) NOT NULL,
    description VARCHAR(100) DEFAULT 'unknown',
    PRIMARY KEY (id)
);

CREATE TABLE Animation_Main_Character (
    main_character VARCHAR(100) NOT NULL DEFAULT '小明',
    id INT NOT NULL CHECK (id > 0),
    PRIMARY KEY (id, main_character),
    FOREIGN KEY (id) REFERENCES Animation(id) ON DELETE CASCADE
);

CREATE TABLE Anime_Series (
    id INT NOT NULL CHECK (id > 0),
    company_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (id) REFERENCES Animation(id) ON DELETE CASCADE
);

CREATE TABLE Series (
    series_number INT NOT NULL DEFAULT 1 CHECK (series_number > 0),
    id INT NOT NULL CHECK (id > 0),
    num_of_episode INT NOT NULL DEFAULT 1 CHECK (num_of_episode > 0),
    series_name VARCHAR(100) NOT NULL,
    author_name VARCHAR(100),
    animation_studio_name VARCHAR(100),
    PRIMARY KEY (id, series_number),
    FOREIGN KEY (id) REFERENCES Anime_Series(id) ON DELETE CASCADE,
    FOREIGN KEY (author_name) REFERENCES Comic_Author(name) ON DELETE SET NULL,
    FOREIGN KEY (animation_studio_name) REFERENCES Animation_Studio(name) ON DELETE SET NULL
);

CREATE TABLE Anime_Movie (
    id INT NOT NULL CHECK (id > 0),
    company_name VARCHAR(100) NOT NULL,
    type VARCHAR(100) NOT NULL CHECK (type IN ('Adaption', 'Original')),
    PRIMARY KEY (id),
    FOREIGN KEY (id) REFERENCES Animation(id) ON DELETE CASCADE
);

CREATE TABLE Adaption (
    id INT NOT NULL CHECK (id > 0),
    author_name VARCHAR(100),
    animation_studio_name VARCHAR(100),
    PRIMARY KEY (id),
    FOREIGN KEY (id) REFERENCES Anime_Movie(id) ON DELETE CASCADE,
    FOREIGN KEY (author_name) REFERENCES Comic_Author(name) ON DELETE SET NULL,
    FOREIGN KEY (animation_studio_name) REFERENCES Animation_Studio(name) ON DELETE SET NULL
);

CREATE TABLE Original (
    id INT NOT NULL CHECK (id > 0),
    sequal_id INT,
    author_name VARCHAR(100),
    screenwriter_name VARCHAR(100),
    PRIMARY KEY (id),
    FOREIGN KEY (id) REFERENCES Anime_Movie(id) ON DELETE CASCADE,
    FOREIGN KEY (sequal_id) REFERENCES Original (id) ON DELETE SET NULL,
    FOREIGN KEY (author_name) REFERENCES Comic_Author(name) ON DELETE SET NULL,
    FOREIGN KEY (screenwriter_name) REFERENCES Screen_Writer (name) ON DELETE SET NULL
);


CREATE TABLE Creator (
    name VARCHAR(100) NOT NULL,
    comment VARCHAR(100) NOT NULL,
    evaluation VARCHAR(100) NOT NULL,
    representative_work VARCHAR(100) NOT NULL,
    entity_type ENUM('Customer', 'Supplier', 'Employee') NOT NULL,
    PRIMARY KEY (name),
    FOREIGN KEY (name) REFERENCES Animation_Studio(name) ON DELETE CASCADE,
    FOREIGN KEY (name) REFERENCES Comic_Author(name) ON DELETE CASCADE,
    FOREIGN KEY (name) REFERENCES Screen_Writer(name) ON DELETE CASCADE
);


/* insert */
INSERT INTO Animation_Studio
VALUES 
('Mappa', '2011-06-14', '250'),
('ufotable', '2000-10-10', '200'),
('BONES', '1998-10-10', '80');

INSERT INTO Comic_Author
VALUES 
('岸本齊史', '1974-11-08', '九州產業大學'),
('尾田榮一郎', '1975-01-01', '九州東方藍大學'),
('鳥山明', '1955-04-05', '高中');

INSERT INTO Screen_Writer
VALUES 
('富岡純廣', '1967-11-25', '無'),
('小太刀右京', '1979-04-01', '無'),
('米村正二', '1964-01-01', '無');




/* create two views (Each view should be based on two tables.)*/
CREATE VIEW view1 AS
SELECT Adaption.id, Adaption.animation_studio_name, Animation_Studio.foundation_date
FROM Adaption, Animation_Studio
WHERE Adaption.animation_studio_name = Animation_Studio.name;

CREATE VIEW view2 AS
SELECT Anime_Series.id, Series.num_of_episode, Series.series_name
FROM Anime_Series, Series
WHERE Anime_Series.id = Series.id;


/* select from all tables and views */
SELECT * FROM Animation_Studio;
SELECT * FROM Comic_Author;
SELECT * FROM Screen_Writer;
SELECT * FROM Animation;
SELECT * FROM Animation_Main_Character;
SELECT * FROM Anime_Series;
SELECT * FROM Series;
SELECT * FROM Anime_Movie;
SELECT * FROM Adaption;
SELECT * FROM Original;
SELECT * FROM Creator;
SELECT * FROM view1;
SELECT * FROM view2;


/* drop database */
DROP DATABASE AnimeDB;
