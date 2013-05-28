

DROP TABLE WS1_PlanChange;
DROP TABLE WS1_Plan;
DROP TABLE WS1_Customer;
DROP TABLE WS1_Car;


-- Reprezentace vozidla

CREATE TABLE WS1_Car (
  id NUMBER PRIMARY KEY,
  name VARCHAR(40) NOT NULL
);


-- Reprezentace zákazníka

CREATE TABLE WS1_Customer (
  id NUMBER PRIMARY KEY,
  name VARCHAR(40) NOT NULL,
  email VARCHAR(40)
);


-- Reprezentace plánu (šablona obsluhy)
-- Každý plán musí mít unikátního zákazníka, vozidlo, den výjezdu a datum
-- platnosti plánu, které reprezentuje sloupec 'valid'.

CREATE TABLE WS1_Plan (
  id NUMBER PRIMARY KEY,
  customer_id NUMBER REFERENCES WS1_Customer(id) NOT NULL,
  car_id NUMBER REFERENCES WS1_Car(id) NOT NULL,
  day NUMBER CHECK (day BETWEEN 1 AND 7),
  valid DATE DEFAULT SYSDATE NOT NULL,
  CONSTRAINT cc_template_unique
    UNIQUE (car_id, customer_id, day, valid)
);


-- Reprezentace změn v plánu
-- Změnit se může datum obsluhy (new_date), auto (car_id) nebo může být
-- plánovaná obsluha úplně zrušena (canceled)

CREATE TABLE WS1_PlanChange (
  id NUMBER PRIMARY KEY,
  customer_id NUMBER REFERENCES WS1_Customer(id) NOT NULL,
  car_id NUMBER REFERENCES WS1_Car(id) NOT NULL,
  planed_date DATE NOT NULL,
  new_date DATE,
  canceled DATE,
  CONSTRAINT cc_reservation_unique
    UNIQUE (customer_id, car_id, planed_date)
);


INSERT INTO WS1_Car (id, name) VALUES (1, 'Auto 1');
INSERT INTO WS1_Car (id, name) VALUES (2, 'Auto 2');

INSERT INTO WS1_Customer (id, name, email)
  VALUES (1, 'Firma 1', 'firma1@gmail.com');
INSERT INTO WS1_Customer (id, name, email)
  VALUES (2, 'Firma 2', 'firma2@gmail.com');
INSERT INTO WS1_Customer (id, name, email)
  VALUES (3, 'Firma 3', 'firma3@gmail.com');
INSERT INTO WS1_Customer (id, name, email)
  VALUES (4, 'Firma 4', 'firma4@gmail.com');

INSERT INTO WS1_Plan (id, customer_id, car_id, day, valid)
  VALUES (1, 1, 1, 1, DATE '2013-06-01');
INSERT INTO WS1_Plan (id, customer_id, car_id, day, valid)
  VALUES (2, 2, 2, 2, DATE '2013-06-01');
INSERT INTO WS1_Plan (id, customer_id, car_id, day, valid)
  VALUES (3, 1, 1, 3, DATE '2013-06-01');
INSERT INTO WS1_Plan (id, customer_id, car_id, day, valid)
  VALUES (4, 3, 2, 3, DATE '2013-06-01');
INSERT INTO WS1_Plan (id, customer_id, car_id, day, valid)
  VALUES (5, 4, 2, 4, DATE '2013-06-01');
INSERT INTO WS1_Plan (id, customer_id, car_id, day, valid)
  VALUES (6, 1, 1, 5, DATE '2013-06-01');
INSERT INTO WS1_Plan (id, customer_id, car_id, day, valid)
  VALUES (7, 2, 2, 5, DATE '2013-06-01');

INSERT INTO WS1_PlanChange (id, customer_id, car_id, planed_date, canceled)
  VALUES (1, 1, 1, DATE '2013-06-10', SYSDATE);
INSERT INTO WS1_PlanChange (id, customer_id, car_id, planed_date, new_date)
  VALUES (2, 1, 2, DATE '2013-06-10', DATE '2013-06-11');


(SELECT car_id, customer_id  -- vyber plány pro daný den
  FROM WS1_Plan
  WHERE day = to_char(DATE '2013-06-11', 'D')
    AND DATE '2013-06-11' > valid
UNION
SELECT car_id, customer_id  -- zahrň plány, které jsou díky změnám nově platné
  FROM WS1_PlanChange
  WHERE (planed_date = DATE '2013-06-11' AND new_date IS NULL)
     OR new_date = DATE '2013-06-11')
MINUS
SELECT car_id, customer_id  -- odeber plány, které byly zrušeny nebo odloženy
  FROM WS1_PlanChange
  WHERE (new_date IS NOT NULL AND new_date != DATE '2013-06-11')
     OR canceled IS NOT NULL;
