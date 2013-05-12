
-- PV003 project
-- Topic: Bookstore

-- Drop Tables

DROP TABLE loans;
DROP TABLE inventory;
DROP TABLE books;
DROP TABLE people;


-- Drop Sequences

DROP SEQUENCE loans_seq;
DROP SEQUENCE books_seq;
DROP SEQUENCE people_seq;


-- Create Tables

CREATE TABLE people (
  id NUMBER PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  birthday DATE
);

CREATE TABLE books (
  id NUMBER PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  author VARCHAR(50) NOT NULL,
  isbn VARCHAR(20) NOT NULL
);

CREATE TABLE inventory (
  book_id NUMBER PRIMARY KEY,
  quantity NUMBER CHECK(quantity > 0),
  available NUMBER CHECK(available >= 0),
    CONSTRAINT availability
      CHECK(quantity >= available),
    CONSTRAINT fk_inventory_book
      FOREIGN KEY (book_id) REFERENCES books(id)
        ON DELETE CASCADE
);

CREATE TABLE loans (
  id NUMBER PRIMARY KEY,
  book_id NUMBER,
  person_id NUMBER,
  overdue NUMBER,
  borrowed DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_loan_book
      FOREIGN KEY (book_id) REFERENCES books(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_loan_person
      FOREIGN KEY (person_id) REFERENCES people(id)
        ON DELETE CASCADE
);


-- Create Sequences

CREATE SEQUENCE people_seq;
CREATE SEQUENCE books_seq;
CREATE SEQUENCE loans_seq;


-- Create Triggers

CREATE OR REPLACE TRIGGER insert_loan
  AFTER INSERT ON loans
  FOR EACH ROW
  BEGIN
    UPDATE inventory
      SET available = available - 1
      WHERE book_id = :new.book_id;
  END;
/

CREATE OR REPLACE TRIGGER delete_loan
  AFTER DELETE ON loans
  FOR EACH ROW
  BEGIN
    UPDATE inventory
      SET available = available + 1
      WHERE book_id = :old.book_id;
  END;
/


-- Create Procedures

CREATE OR REPLACE PROCEDURE calc_overdue IS
  CURSOR delay IS
    SELECT id, trunc(months_between(SYSDATE, borrowed)) overdue
      FROM loans
      WHERE add_months(SYSDATE, -1) > borrowed;
  BEGIN
    FOR loan IN delay LOOP
      UPDATE loans
        SET overdue = loan.overdue
        WHERE id = loan.id;
    END LOOP;
END calc_overdue;
/


-- Insert Data

INSERT INTO books VALUES (books_seq.NEXTVAL, 'A Storm of Swords', 'George R. R. Martin', '111-333');
INSERT INTO inventory VALUES (books_seq.CURRVAL, 5, 5);

INSERT INTO books VALUES (books_seq.NEXTVAL, 'Thinking with Type', 'Ellen Lupton', '222-444');
INSERT INTO inventory VALUES (books_seq.CURRVAL, 1, 1);

INSERT INTO books VALUES (books_seq.NEXTVAL, 'A Dance with Dragons', 'George R. R. Martin', '333-555');
INSERT INTO inventory VALUES (books_seq.CURRVAL, 10, 10);

INSERT INTO books VALUES (books_seq.NEXTVAL, 'Expert Python Programming', 'Tarek Ziadé', '444-666');
INSERT INTO inventory VALUES (books_seq.CURRVAL, 2, 2);


INSERT INTO people VALUES (people_seq.NEXTVAL, 'Robb', 'Stark', DATE '1995-01-02');

INSERT INTO people VALUES (people_seq.NEXTVAL, 'Eddard', 'Stark', DATE '1980-02-02');
INSERT INTO loans VALUES (loans_seq.NEXTVAL, 1, people_seq.CURRVAL, NULL, DATE '2013-05-05');
INSERT INTO loans VALUES (loans_seq.NEXTVAL, 3, people_seq.CURRVAL, NULL, DATE '2013-03-25');

INSERT INTO people VALUES (people_seq.NEXTVAL, 'Hizdahr', 'Loraq', DATE '1987-09-23');
INSERT INTO loans VALUES (loans_seq.NEXTVAL, 3, people_seq.CURRVAL, NULL, DATE '2013-04-30');

INSERT INTO people VALUES (people_seq.NEXTVAL, 'Tormund', 'Giantsbane', DATE '1989-01-10');
INSERT INTO loans VALUES (loans_seq.NEXTVAL, 2, people_seq.CURRVAL, NULL, DATE '2013-02-08');
INSERT INTO loans VALUES (loans_seq.NEXTVAL, 4, people_seq.CURRVAL, NULL, DATE '2013-05-08');


EXECUTE calc_overdue;


COLUMN FIRST_NAME FORMAT A20;
COLUMN LAST_NAME FORMAT A20;


SELECT first_name, last_name, count(person_id)
  FROM people
  LEFT OUTER JOIN loans
    ON people.id = loans.person_id
  GROUP BY person_id, first_name, last_name;
