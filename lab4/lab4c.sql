SET FOREIGN_KEY_CHECKS=0; 
UNLOCK TABLES;
-- 
DROP TABLE IF EXISTS flight CASCADE;
DROP TABLE IF EXISTS weekly_schedule CASCADE;
DROP TABLE IF EXISTS year CASCADE;
DROP TABLE IF EXISTS day CASCADE;
DROP TABLE IF EXISTS route CASCADE;
DROP TABLE IF EXISTS airport CASCADE;
DROP TABLE IF EXISTS contact CASCADE;
DROP TABLE IF EXISTS passenger CASCADE;
DROP TABLE IF EXISTS credit_card CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS booking CASCADE;
DROP TABLE IF EXISTS ticket CASCADE;
DROP TABLE IF EXISTS passenger_reservation CASCADE;

SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE flight
   (flight_number INT AUTO_INCREMENT,
    weekly_flight_id INT,
    nr_seats INT DEFAULT 40,
    booked_seats INT DEFAULT 0,
    week INT,
    CONSTRAINT pk_flight PRIMARY KEY(flight_number)) ENGINE=InnoDB;

CREATE TABLE weekly_schedule
   (id INT AUTO_INCREMENT,
    departure_airport VARCHAR(3),
    arrival_airport VARCHAR(3),
    year INT,
    day VARCHAR(10),
    departure_time TIME,
    CONSTRAINT pk_weekly_schedule PRIMARY KEY(id)) ENGINE=InnoDB;
    
CREATE TABLE year
   (year INT,
    profit_factor DOUBLE,
    CONSTRAINT pk_year PRIMARY KEY(year)) ENGINE=InnoDB;
    
CREATE TABLE day
   (year INT,
    day VARCHAR(10),
    weekly_factor DOUBLE,
    CONSTRAINT pk_day PRIMARY KEY(year, day)) ENGINE=InnoDB;
    
CREATE TABLE route
   (departure_airport VARCHAR(3),
    arrival_airport VARCHAR(3),
    year INT,
    route_price DOUBLE,
    CONSTRAINT pk_route PRIMARY KEY(departure_airport, arrival_airport, year)) ENGINE=InnoDB;
    
CREATE TABLE airport
   (airport_code VARCHAR(3),
    name VARCHAR(30),
    country VARCHAR(30),
    CONSTRAINT pk_airport PRIMARY KEY(airport_code)) ENGINE=InnoDB;
    
CREATE TABLE contact
   (passport_number INT,
	reservation_number INT,
    email VARCHAR(30),
    phone BIGINT,
    CONSTRAINT pk_contact PRIMARY KEY(passport_number)) ENGINE=InnoDB;
    
CREATE TABLE passenger
   (passport_number INT,
	name VARCHAR(30),
    CONSTRAINT pk_passenger PRIMARY KEY(passport_number)) ENGINE=InnoDB;

CREATE TABLE credit_card
   (credit_card_number BIGINT,
	credit_card_name VARCHAR(30),
    CONSTRAINT pk_credit_card PRIMARY KEY(credit_card_number)) ENGINE=InnoDB;
    
    
CREATE TABLE reservation
   (reservation_number INT,
	flight INT,
    nr_passengers INT DEFAULT 0,
    contact INT,
    CONSTRAINT pk_reservation PRIMARY KEY(reservation_number)) ENGINE=InnoDB;
    
CREATE TABLE booking
   (reservation_number INT,
	price DOUBLE,
    credit_card BIGINT,
    passenger_id INT,
    CONSTRAINT pk_booking PRIMARY KEY(reservation_number)) ENGINE=InnoDB;
    
CREATE TABLE ticket
   (passport_number INT,
	reservation_number INT,
    ticket_nr INT,
    CONSTRAINT pk_ticket PRIMARY KEY(passport_number, reservation_number)) ENGINE=InnoDB;
    
    
CREATE TABLE passenger_reservation
   (passport_number INT,
	reservation_number INT,
    CONSTRAINT pk_contains  PRIMARY KEY(passport_number, reservation_number)) ENGINE=InnoDB;
        
SELECT 'Creating foreign keys' AS 'Message';
ALTER TABLE flight ADD CONSTRAINT fk_weekly_flight FOREIGN KEY (weekly_flight_id) REFERENCES weekly_schedule(id);
ALTER TABLE weekly_schedule ADD CONSTRAINT fk_route FOREIGN KEY (departure_airport, arrival_airport, year) REFERENCES route(departure_airport, arrival_airport, year);
ALTER TABLE weekly_schedule ADD CONSTRAINT fk_year FOREIGN KEY (year) REFERENCES year(year);
ALTER TABLE weekly_schedule ADD CONSTRAINT fk_year_day FOREIGN KEY (year, day) REFERENCES day(year,day);
ALTER TABLE route ADD CONSTRAINT fk_departure_airport FOREIGN KEY (departure_airport) REFERENCES airport(airport_code);
ALTER TABLE route ADD CONSTRAINT fk_arrival_airport FOREIGN KEY (arrival_airport) REFERENCES airport(airport_code);
ALTER TABLE contact ADD CONSTRAINT fk_passport_number FOREIGN KEY (passport_number) REFERENCES passenger(passport_number);
ALTER TABLE reservation ADD CONSTRAINT fk_contact FOREIGN KEY (contact) REFERENCES contact(passport_number);
ALTER TABLE reservation ADD CONSTRAINT fk_flight FOREIGN KEY (flight) REFERENCES flight(flight_number);

ALTER TABLE booking ADD CONSTRAINT fk_reservation FOREIGN KEY (reservation_number) REFERENCES reservation(reservation_number);
ALTER TABLE booking ADD CONSTRAINT fk_credit_card FOREIGN KEY (credit_card) REFERENCES credit_card(credit_card_number);

ALTER TABLE ticket ADD CONSTRAINT fk_booking_ticket FOREIGN KEY (reservation_number) REFERENCES booking(reservation_number);
ALTER TABLE ticket ADD CONSTRAINT fk_passport_ticket FOREIGN KEY (passport_number) REFERENCES passenger(passport_number);    

ALTER TABLE passenger_reservation ADD CONSTRAINT fk_reserv FOREIGN KEY (reservation_number) REFERENCES reservation(reservation_number) ON DELETE CASCADE;
ALTER TABLE passenger_reservation ADD CONSTRAINT fk_pass FOREIGN KEY (passport_number) REFERENCES passenger(passport_number);


DROP PROCEDURE IF EXISTS addYear;
DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP PROCEDURE IF EXISTS addRoute;
DROP PROCEDURE IF EXISTS addFlight;
DROP PROCEDURE IF EXISTS addReservation;
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addPayment;
DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;
DROP TRIGGER IF EXISTS uniqueTicketNr;
DROP VIEW IF EXISTS allFlights;



delimiter //
CREATE PROCEDURE addYear(IN year INT, IN factor DOUBLE)
BEGIN
INSERT INTO year (year, profit_factor)
VALUES (year, factor);
END; //

CREATE PROCEDURE addDay(IN year INT, IN day VARCHAR(10), IN factor DOUBLE)
BEGIN
INSERT INTO day (year, day, weekly_factor)
VALUES (year, day, factor);
END; //

CREATE PROCEDURE addDestination(IN airport_code VARCHAR(3), IN name VARCHAR(30), IN country VARCHAR(30))
BEGIN
INSERT INTO airport (airport_code, name, country)
VALUES (airport_code, name, country);
END; //

CREATE PROCEDURE addRoute(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN year INT, IN routeprice DOUBLE)
BEGIN
INSERT INTO route (departure_airport, arrival_airport, year, route_price)
VALUES (departure_airport_code, arrival_airport_code, year, routeprice);
END; //

CREATE PROCEDURE addFlight(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN year INT, IN day VARCHAR(10), IN departure_time TIME)
BEGIN
DECLARE counter INT;
DECLARE flight_id INT;
SET counter := 1;

INSERT INTO weekly_schedule(departure_airport, arrival_airport, year, day, departure_time) VALUES (departure_airport_code, arrival_airport_code, year, day, departure_time);

SET flight_id := LAST_INSERT_ID();-- (SELECT weekly_schedule.id FROM weekly_schedule WHERE (weekly_schedule.year = year AND weekly_schedule.day = day AND weekly_schedule.departure_airport = departure_airport_code 
-- AND weekly_schedule.arrival_airport = arrival_airport_code AND weekly_schedule.departure_time = departure_time));

WHILE counter <= 52 DO
    INSERT INTO flight (weekly_flight_id, week) VALUES (flight_id, counter);
    SELECT counter;
    SET counter := counter + 1;
END WHILE;

END; //

CREATE PROCEDURE addReservation(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN year INT, 
IN week INT, IN day VARCHAR(10), IN departure_time TIME, IN number_of_passengers INT, OUT output_reservation_nr INT)
BEGIN
DECLARE flight_id INT;

IF(number_of_passengers > 40)THEN
	SELECT "NOT OK. Number of passengers on the reservation exceeds available seats." AS "Message";
ELSE
	SET output_reservation_nr := (FLOOR(RAND()*(99999999-1+1))+1);

	SET flight_id := (SELECT flight_number FROM flight, weekly_schedule WHERE flight.weekly_flight_id = weekly_schedule.id 
	AND weekly_schedule.departure_airport = departure_airport_code
	AND weekly_schedule.arrival_airport = arrival_airport_code
	AND weekly_schedule.year = year
	AND flight.week = week
	AND weekly_schedule.day = day AND weekly_schedule.departure_time = departure_time);
	
    IF (flight_id IS NOT NUlL) THEN
		INSERT INTO reservation (reservation_number, flight)
		VALUES (output_reservation_nr, flight_id);
		SELECT "OK. Reservation added." AS "Message", (SELECT output_reservation_nr as "output reservation");
        
	ELSE 
		SELECT "There exists no flight with those flight details" AS "Message";
	END IF;
END IF;
END; //

CREATE PROCEDURE addPassenger(IN reservation_number INT, IN passport_number INT, IN name VARCHAR(30))
BEGIN
IF ((SELECT reservation_number FROM booking where booking.reservation_number = reservation_number) IS NOT NULL) THEN
	SELECT "Reservation has already been payed for. Can't add passenger" AS "Message";
ELSE
	IF ((SELECT reservation_number FROM reservation WHERE reservation_number = reservation.reservation_number) = reservation_number) THEN
		IF ((SELECT passport_number FROM passenger WHERE passport_number = passenger.passport_number) = passport_number) THEN
			INSERT INTO passenger_reservation(passport_number, reservation_number) VALUES (passport_number, reservation_number);
			SELECT "OK. Added reservation to existing passenger" AS "Message";
		ELSE
			INSERT INTO passenger(passport_number, name) VALUES (passport_number, name);
			INSERT INTO passenger_reservation(passport_number, reservation_number) VALUES (passport_number, reservation_number);
			SELECT "OK. Added new passenger and new reservation" AS "Message";
		END IF;
		
		UPDATE reservation
		SET nr_passengers := nr_passengers + 1
		WHERE reservation.reservation_number = reservation_number;
	ELSE
		SELECT "Reservation number doesn't exist" AS "Message";
	END IF;
END IF;



END; //

CREATE PROCEDURE addContact(IN reservation_number INT, IN passport_number INT, IN email VARCHAR(30), IN phone BIGINT)
BEGIN
IF ((SELECT passport_number FROM contact WHERE contact.email = email AND contact.passport_number = passport_number) = passport_number) THEN
	UPDATE reservation
    SET contact := passport_number
    WHERE reservation.reservation_number = reservation_number;
    SELECT "OK. Added reservation to exsisting contact" as "Message";
    
ELSEIF ((SELECT reservation_number FROM passenger_reservation WHERE reservation_number = passenger_reservation.reservation_number AND passport_number = passenger_reservation.passport_number) = reservation_number) THEN
	INSERT INTO contact(passport_number, reservation_number, email, phone) VALUES (passport_number, reservation_number, email, phone);

	UPDATE reservation
	SET contact := passport_number
	WHERE reservation.reservation_number = reservation_number;
    SELECT "OK. Added contact" as "Message";
    
    
ELSEIF ((SELECT reservation_number FROM passenger_reservation WHERE reservation_number = passenger_reservation.reservation_number) IS NULL) THEN
	SELECT "Reservation number doesn't exist" AS "Message";
ELSE
	SELECT "Passenger doesn't exist on reservation" AS "Message";
END IF;
END; //

CREATE PROCEDURE addPayment(IN reservation_number INT, IN cardholder_name VARCHAR(30), IN credit_card_number BIGINT)
BEGIN

IF ((SELECT reservation_number FROM reservation WHERE reservation.reservation_number = reservation_number) IS NULL) THEN
	SELECT "Reservation number doesn't exist" AS "Message";
ELSEIF ((SELECT contact FROM reservation WHERE reservation.reservation_number = reservation_number) IS NULL) THEN
	SELECT "Reservation has no contact" AS "Message";
ELSEIF (calculateFreeSeats((SELECT flight FROM reservation WHERE reservation.reservation_number = reservation_number)) <=
	(SELECT nr_passengers FROM reservation WHERE reservation.reservation_number = reservation_number)) THEN
	SELECT "Not enough free seats on the flight. Deleting reservation." AS "Message";
    DELETE FROM reservation WHERE reservation.reservation_number = reservation_number;
ELSEIF ((SELECT reservation_number FROM booking WHERE booking.reservation_number = reservation_number) = reservation_number) THEN
	SELECT "Reservation has already been payed" AS "Message";
ELSE
    IF ((SELECT credit_card_number FROM credit_card WHERE credit_card_number = credit_card.credit_card_number) IS NULL) THEN
		INSERT INTO credit_card(credit_card_number, credit_card_name) VALUES (credit_card_number, cardholder_name);
	END IF;
	INSERT INTO booking(reservation_number, credit_card, price)
    VALUES (reservation_number, credit_card_number, (SELECT nr_passengers FROM reservation 
    WHERE reservation.reservation_number = reservation_number)*calculatePrice((SELECT flight FROM reservation WHERE reservation.reservation_number = reservation_number)));

     UPDATE flight
		SET flight.booked_seats := flight.booked_seats + (SELECT nr_passengers FROM reservation WHERE reservation.reservation_number = reservation_number)
		WHERE flight.flight_number = (SELECT flight FROM reservation WHERE reservation.reservation_number = reservation_number);
	SELECT "OK. Payment added" AS "Message";
END IF;
END; //

CREATE FUNCTION calculateFreeSeats(flightnumber INT) RETURNS INT
BEGIN

RETURN (SELECT (nr_seats) FROM flight WHERE flight.flight_number = flightnumber) - (SELECT (booked_seats) FROM flight WHERE flight.flight_number = flightnumber);

END; //

CREATE FUNCTION calculatePrice(flightnumber INT) RETURNS DOUBLE
BEGIN
DECLARE TotalPrice DOUBLE;

SET TotalPrice := (SELECT (route.route_price*day.weekly_factor*((flight.booked_seats+1)/40)*year.profit_factor)
FROM route, weekly_schedule, day, flight, year
WHERE flightnumber = flight.flight_number
AND flight.weekly_flight_id = weekly_schedule.id 
AND weekly_schedule.departure_airport = route.departure_airport
AND weekly_schedule.arrival_airport = route.arrival_airport
AND weekly_schedule.year = route.year
AND weekly_schedule.year = year.year
AND weekly_schedule.year = day.year AND weekly_schedule.day = day.day);

RETURN ROUND(TotalPrice,3);
END; //


CREATE TRIGGER uniqueTicketNr
AFTER INSERT ON booking FOR EACH ROW
BEGIN
INSERT INTO ticket SELECT passenger_reservation.passport_number, passenger_reservation.reservation_number, FLOOR(RAND()*(99999999))+1 
FROM passenger_reservation WHERE passenger_reservation.reservation_number = NEW.reservation_number;
END; //

Delimiter ;

CREATE VIEW allFlights AS 
SELECT departure.name AS departure_city_name, destination.name AS destination_city_name, departure_time, weekly_schedule.day AS departure_day, flight.week AS departure_week,
weekly_schedule.year AS departure_year, calculateFreeSeats(flight.flight_number) AS nr_of_free_seats, calculatePrice(flight.flight_number) AS current_price_per_seat
FROM weekly_schedule, flight, airport AS departure, airport AS destination, route
WHERE flight.weekly_flight_id = weekly_schedule.ID AND weekly_schedule.departure_airport = route.departure_airport 
AND route.departure_airport = departure.airport_code AND weekly_schedule.arrival_airport = route.arrival_airport
AND route.arrival_airport = destination.airport_code;

-- THEORY QUESTIONS --

-- 8.
-- How can you protect the credit card information in the database from hackers? 
-- By using encryption with hashing to protect the information, or not storing the credit card information in the database
-- Give three advantages of using stored procedures in the database (and thereby execute them on the server) instead of writing the same functions in the frontend of the system (in for example java-script on a web-page)?
-- You reduce data transfer because you don?t have to jump between the client and the server. Reducing data transfer lowers communication costs. Reduce the workload on the users computer as well.
-- 
-- 9. Open two MySQL sessions. We call one of them A and the other one B. Write START TRANSACTION; in both terminals. 
-- a) In session A, add a new reservation.
-- ok.
-- b) Is this reservation visible in session B? Why? Why not? 
-- NO, is not visible. Because the change is not commited to the database.
-- c) What happens if you try to modify the reservation from A in B? Explain what happens and why this happens and how this relates to the concept of isolation of transactions.
-- Nothing happens, because the reservation does not exist in the database before it?s commited. It?s isolated before commit according to ACID properties ;)
-- 
-- 
-- 10. Is your BryanAir implementation safe when handling multiple concurrent transactions? 
-- 
-- Let two customers try to simultaneously book more seats than what are available on a flight and see what happens. This is tested by executing the testscripts available on the course-page using two different MySQL sessions. Note that you should not use explicit transaction control unless this is your solution on 10c. 
-- a) Did overbooking occur when the scripts were executed? If so, why? If not, why not? 
-- No, an overbooking did not occur. This is because the ?addPayment?-function of the second session checks if there are enough available seats on the flight and deletes the reservation if this is the case (which happened here).
-- 
-- b) Can an overbooking theoretically occur? If an overbooking is possible, in what order must the lines of code in your procedures/functions be executed. 
-- 
-- Theoretically an overbooking can occur if the addPayment-procedures are executed at the same time. Then, both bookings will go past the if-statements that checks for available flights before any of the ?transactions? makes a booking (updates the seats on the flight). 
-- 
-- More specifically: Both transactions go through each line in the procedure simultaneously (or close to since one transaction has to do it before the other) and both transactions go through the if-statements and end up in the update (write-function that creates a booking on the flight) further down in the procedure. This leads to an overbooking where the seats are calculated as: 40 - 21 - 21 = -2
-- 
-- c) Try to make the theoretical case occur in reality by simulating that multiple sessions call the procedure at the same time. To specify the order in which the lines of code are executed use the MySQL query SELECT sleep(5); which makes the session sleep for 5 seconds. Note that it is not always possible to make the theoretical case occur, if not, motivate why. 
-- 
-- We added a sleep(5) before creating a booking but after the if-statement that checks if there are enough seats on the flight. By doing this, both our transactions have enough time to go past the if-statement before the other transaction has created a booking.
-- 
-- d) Modify the testscripts so that overbookings are no longer possible using (some of) the commands START TRANSACTION, COMMIT, LOCK TABLES, UNLOCK TABLES, ROLLBACK, SAVEPOINT, and SELECT?FOR UPDATE. Motivate why your solution solves the issue, and test that this also is the case using the sleep implemented in 10c. Note that it is not ok that one of the sessions ends up in a deadlock scenario. Also, try to hold locks on the common resources for as short time as possible to allow multiple sessions to be active at the same time. Note that depending on how you have implemented the project it might be very hard to block the overbooking due to how transactions and locks are implemented in MySQL. If you have a good idea of how it should be solved but are stuck on getting the queries right, talk to your lab-assistant and he or she might help you get it right or allow you to hand in the exercise with pseudocode and a theoretical explanation.
-- 
-- We need to stop one of the transactions from checking the if-statements in addPayment() before another transaction has finished completing the booking further down in addPayment(). In order to do so, we will give the table reservation, flight, booking and credit_card an exclusive(write) lock. Since reservation has an exclusive lock, no other transaction is allowed to have a lock on it and therefore is not allowed to read the if-statements and go through it. When we are done with the first transaction we unlock all tables, allowing the other transaction to obtain the exclusive locks and go through addPayment(). 
-- 
-- Psuedo-code:
-- -- In booking script -- 
-- Write lock tables reservation, flight, credit_card and booking just before addPayment()
-- -- When addPayment() is done --
-- Unlock all tables
-- 




