-- Victor Jonsson Vicjo972, Erika Hansson Eriha368, Oscar Schwartz Blicke Oscbl470
-- 1. List all employees
SELECT * FROM jbemployee;
-- 2. List names from department ordered alphabetically
SELECT NAME FROM jbdept ORDER BY NAME ASC;
-- 3 List all parts out of stock QOH = 0
SELECT NAME, QOH
FROM jbparts
WHERE QOH = 0
ORDER BY NAME ASC;

-- 4. List employees with salary between 9000-10000
SELECT NAME, SALARY
FROM jbemployee
WHERE SALARY>=9000 AND SALARY<=10000 
ORDER BY SALARY ASC;

-- 5. List age of employees
SELECT NAME, STARTYEAR-BIRTHYEAR
FROM jbemployee
ORDER BY STARTYEAR-BIRTHYEAR ASC;

-- 6. Employees with last name ending in son
SELECT * 
FROM jbemployee
WHERE NAME LIKE '%son,%';

-- 7. Which items have been delivered by Fisher-Price? Use a sub-query
SELECT NAME
FROM jbitem
WHERE SUPPLIER IN (SELECT ID FROM jbsupplier WHERE NAME = 'Fisher-Price');

-- 8. Same as above without sub-query
SELECT jbitem.NAME, jbsupplier.NAME
FROM jbitem, jbsupplier
WHERE SUPPLIER = jbsupplier.ID AND jbsupplier.NAME = 'Fisher-Price'; 

-- 9. Show all cities that have suppliers located in them, using a sub-query in the where clause.
SELECT *
FROM jbcity
WHERE ID IN (SELECT CITY FROM jbsupplier); 

-- 10. Name and color of all parts that are heavier than a card reader, using a sub-query.
SELECT NAME, COLOR
FROM jbparts
WHERE WEIGHT > (SELECT WEIGHT FROM jbparts WHERE NAME = 'card reader');

-- 11. Same as above without sub-query
SELECT E.NAME AS 'NAME',
	E.COLOR AS 'COLOR'
FROM jbparts E, jbparts S
WHERE E.WEIGHT > S.WEIGHT AND S.NAME = 'card reader';

-- 12. Average weight of black parts?
SELECT AVG(WEIGHT) AS 'AVG of black parts'
FROM jbparts
WHERE COLOR = 'black';

-- 13. Total weight of all parts that 
SELECT jbsupplier.NAME, SUM(jbparts.WEIGHT*jbsupply.QUAN)
FROM jbcity, jbsupplier, jbsupply, jbparts
WHERE jbcity.STATE = 'Mass' AND jbcity.ID = jbsupplier.CITY AND jbsupply.SUPPLIER = jbsupplier.ID AND jbsupply.PART = jbparts.ID
GROUP BY jbsupplier.NAME;

-- 14 Create a table with items that cost rest than the average price for items 
CREATE TABLE lessitem ( 
ID integer, 
NAME VARCHAR(20), 
DEPT integer, 
PRICE integer, 
QOH integer, 
SUPPLIER integer, 

constraint pk_workson 
primary key(ID), 
constraint fk_works_emp 
FOREIGN KEY(ID) references jbitem(ID)); 

INSERT INTO lessitem(ID, NAME, DEPT, PRICE, QOH, SUPPLIER) 
SELECT ID, NAME, DEPT, PRICE, QOH, SUPPLIER 
FROM jbitem 
WHERE jbitem.PRICE < (SELECT AVG(PRICE) FROM jbitem); 

-- 15 Create a view with items that costs less than the average price for items 
CREATE VIEW item_view2 AS 
SELECT NAME, PRICE 
FROM jbitem 
WHERE PRICE < (SELECT AVG(PRICE) FROM jbitem); 

-- 16 Theory answer is in other document along with code and answers. 
-- A table is static and a view is dynamic. Static means that it can only 
-- be changed before running the program whilst dynamic means that it can be changed whilst running the program (showcased by that views are always up-to-date).  

-- 17  Create a view that calculates the total cost of each debit
CREATE VIEW debit_view2 AS 
SELECT jbdebit.ID, SUM(jbitem.PRICE*jbsale.QUANTITY) 
FROM jbdebit, jbsale, jbitem 
WHERE jbdebit.ID = jbsale.DEBIT AND jbsale.ITEM = jbitem.ID 
GROUP BY jbdebit.ID; 

-- 18 Same as 17 however only using right, inner or left join 
Create view debit_view6 AS 
SELECT jbdebit.ID, SUM(jbitem.PRICE*jbsale.QUANTITY) 
FROM ((jbdebit 
LEFT JOIN jbsale ON jbdebit.ID = jbsale.debit) 
LEFT JOIN jbitem ON jbsale.item = jbitem.id) 
group by jbdebit.id; 
select * from debit_view6; 

-- Theory question
-- Motivation: 
-- Inner join, we want to use inner join because the relevant data must be present in both relations. 
-- However in this case left and right would also work too since there are solely matching values 
-- between the tables. We do not have a tuple who has an attribute that is left out, 
-- meaning when inner join is performed the whole table is taken.  

-- 19 Delete all suppliers in Los Angeles
SET SQL_SAFE_UPDATES = 0;

delete from jbsale
where item in (select id from jbitem where supplier in (select id from jbsupplier where city in (select id from jbcity where name = "Los Angeles")));
delete from jbitem
where supplier in (select id from jbsupplier where city in (select id from jbcity where name = "Los Angeles"));
delete from jbsupplier 
where city in (select id from jbcity where name = "Los Angeles"); 

-- b)
-- Dependent tuples
-- '100582', '26', '1' from jbsale 
-- '26', 'Earrings', '14', '1000', '20', '199' from jbitem
-- '115', 'Gold Ring', '14', '4995', '10', '199' from jbitem 
-- '199', 'Koret', '900' from jbsupplier 
-- These tuples are dependent on the supplier koret, so if we remove Koret, 
-- we first have to remove the tuples above.  We do this manually by using delete and where clause which connects it to “Los angeles” in jbcity. 


-- 20
CREATE VIEW jbsale_supply_v5(supplier, item, quantity) AS
SELECT jbsupplier.name, jbitem.name, jbsale.quantity
FROM ((jbsupplier 
INNER JOIN jbitem on jbsupplier.id = jbitem.supplier)
LEFT JOIN jbsale on jbsale.item = jbitem.id);


SELECT supplier, sum(quantity) AS sum FROM jbsale_supply_v5
GROUP BY supplier;


	 




