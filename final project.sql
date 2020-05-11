DROP   DATABASE IF EXISTS db_consumer_panel;
 CREATE DATABASE db_consumer_panel;
 USE    db_consumer_panel;

DROP TABLE IF EXISTS Households;
CREATE TABLE Households(
hh_id                                                           BIGINT unsigned   NOT NULL,
hh_race                                                       INT unsigned NOT NULL,
hh_is_latinx                                                 INT unsigned NOT NULL,
hh_zip_code                                               INT unsigned NOT NULL,
#CHECK                                                      (hh_zip_code BETWEEN 10000 AND 99999),    
hh_state                                                     CHAR(2) NOT NULL,         
hh_income                                                  INT unsigned NOT NULL,
hh_size                                                       INT  unsigned NOT NULL,
hh_residence_type                                     INT  NOT NULL,                                            
PRIMARY KEY                                           (hh_id)                                                                             
);

drop table if exists Products;
CREATE TABLE Products(
brand_at_prod_id                                       VARCHAR(100),
department_at_prod_id                              VARCHAR(100),
prod_id                                                       VARCHAR(100) ,
group_at_prod_id                                       VARCHAR(100),
module_at_prod_id                                    VARCHAR(100) ,
amount_at_prod_id                                    FLOAT  ,
units_at_prod_id                                        CHAR(10) ,   
PRIMARY KEY                                           (prod_id)
);

drop table if exists Trips;
CREATE TABLE Trips(
hh_id                                                          BIGINT unsigned,
TC_date                                                     DATETIME,
TC_retailer_code                                       INT unsigned,
TC_retailer_code_store_code                   INT unsigned,
TC_retailer_code_store_zip3                    INT unsigned,
#CHECK                                                     (TC_retailer_code_store_zip3    BETWEEN 100 AND 999),      
TC_total_spent                                          FLOAT,
TC_id                                                         BIGINT unsigned, 
PRIMARY KEY                                         (TC_id)
);

drop table if exists Purchases;
CREATE TABLE  Purchases(
TC_id                                                         VARCHAR(100), 
quantity_at_TC_prod_id                            INT unsigned  ,
total_price_paid_at_TC_prod_id               FLOAT  ,
coupon_value_at_TC_prod_id                  FLOAT  ,
deal_flag_at_TC_prod_id                          INT unsigned,    
prod_id                                                      VARCHAR(100) NOT NULL
);



ALTER TABLE    Trips                   ADD CONSTRAINT FK_hh_id                         FOREIGN KEY (hh_id)                  REFERENCES    Households(hh_id);
ALTER TABLE    Purchases          ADD CONSTRAINT FK_TC_id                        FOREIGN KEY (TC_id)                 REFERENCES    Trips(TC_id);
#ALTER TABLE    Purchases          ADD CONSTRAINT FK_prod_id                      FOREIGN KEY (prod_id)              REFERENCES    Products(prod_id);

SELECT count(*) FROM Households;
SELECT count(*) FROM Products;
SELECT count(*) FROM Trips;
SELECT count(*) FROM Purchases;


# a.1. How many Store shopping trips are recorded in your database?
SELECT count(*) FROM Trips;
SELECT COUNT(TC_id) FROM Trips;

# a.2. How many Households appear in your database?
SELECT COUNT(distinct hh_id) FROM Households;

# a.3. How many Stores of different retailers appear in our data base?
SELECT SUM(num_ret_store) FROM (SELECT TC_retailer_code, COUNT(distinct TC_retailer_code_store_code) AS num_ret_store 
FROM Trips WHERE TC_retailer_code_store_code != "0"
GROUP BY TC_retailer_code) AS A;

# a.4. How many Different products are recorded?
SELECT COUNT(distinct prod_id)  FROM Products;

# a.4.i. How many Products per category and products per module
SELECT * FROM Products;
SELECT group_at_prod_id, COUNT(distinct prod_id) AS num_pro_cat FROM Products GROUP BY group_at_prod_id; 
SELECT module_at_prod_id, COUNT(distinct prod_id) AS num_pro_mod FROM Products GROUP BY module_at_prod_id; 

#a.4.ii. Plot the distribution of products and modules per department
SELECT department_at_prod_id, COUNT(distinct prod_id) AS num_pro_dep
FROM Products WHERE department_at_prod_id IS NOT NULL
GROUP BY department_at_prod_id;

# a.Transactions i. Total transactions and transactions realized under some kind of promotion.
SELECT * FROM Purchases;
SELECT COUNT(TC_id) FROM Purchases;
SELECT COUNT(TC_id) FROM Purchases WHERE coupon_value_at_TC_prod_id != "0";

# b. How many households do not shop at least once on a 3 month periods.
DROP TABLE IF EXISTS tableb;
CREATE TEMPORARY TABLE tableb
SELECT hh_id, concat(year(TC_date),  date_format(TC_date,'%m')) AS purchase_date FROM Trips;
SELECT * FROM tableb order by hh_id limit 50;

DROP TABLE IF EXISTS table1;
CREATE TEMPORARY TABLE table1
SELECT *, ROW_NUMBER() OVER (PARTITION BY hh_id ORDER BY purchase_date DESC) AS rank_decreasing FROM tableb;
SELECT * FROM table1 limit 10;

DROP TABLE IF EXISTS table2;
CREATE TEMPORARY TABLE table2
SELECT *, 1 + rank_decreasing AS new_rank FROM table1;
SELECT * FROM table2;

SELECT table1.hh_id, table1.purchase_date, table1.rank_decreasing, table2.purchase_date, table2.new_rank FROM table1 
LEFT JOIN table2
ON table1.hh_id = table2.hh_id AND table1.rank_decreasing= table2.new_rank
WHERE table2.purchase_date-table1.purchase_date = 3 or table2.purchase_date-table1.purchase_date = 91;

SELECT * FROM Trips LIMIT 100;
SELECT * FROM Households LIMIT 100;
SELECT * FROM Purchases LIMIT 100;
SELECT * FROM Products LIMIT 100;

SELECT COUNT(distinct tc_id) FROM purchases;
SELECT COUNT(distinct tc_id) FROM trips;







# Is the number of shopping trips per month correlated with the average number of items purchased?
SELECT hh_id, avg(num_trips),0 AS avg_num_trips FROM( 
SELECT hh_id, purchase_date, count(TC_id) AS num_trips FROM (
SELECT hh_id, concat(year(TC_date),  date_format(TC_date,'%m')) AS purchase_date, TC_id FROM Trips ORDER BY hh_id) AS A
GROUP BY hh_id,purchase_date ORDER BY hh_id) AS B
GROUP BY hh_id;


SELECT hh_id, num_trips/total_month as avg_trips FROM (
SELECT hh_id, count(distinct purchase_date) as total_month, count(TC_id) AS num_trips FROM (
SELECT hh_id, concat(year(TC_date),  date_format(TC_date,'%m')) AS purchase_date, TC_id FROM Trips ORDER BY hh_id) AS A
GROUP BY hh_id)AS B;


SELECT hh_id, count(distinct purchase_date) as total_month, count(distinct TC_id) AS num_trips FROM (
SELECT hh_id, concat(year(TC_date),  date_format(TC_date,'%m')) AS purchase_date, TC_id FROM Trips ORDER BY hh_id) AS A
GROUP BY hh_id;

select hh_id, count(tc_id) from trips group by hh_id;
# Is the average price paid per item correlated with the number of items purchased?





# Private Labeled products are the products with the same brand as the supermarket. In the data set they appear labeled as ‘CTL BR’
# i. What are the product categories that have proven to be more “Private labelled”
DROP TABLE IF EXISTS priv_prod;
SELECT department_at_prod_id, COUNT(brand_at_prod_id) AS num_priv_prod FROM (
SELECT * FROM Products WHERE brand_at_prod_id = 'CTL BR') AS A
WHERE department_at_prod_id IS NOT NULL
GROUP BY department_at_prod_id;


SELECT * FROM Products WHERE brand_at_prod_id = 'CTL BR';
# ii. Is the expenditure share in Private Labeled products constant across months?


# iii. Cluster households in three income groups, Low, Medium and High. Report the average monthly expenditure on grocery. Study the % of private label share in their monthly expenditures. Use visuals to represent the intuition you are suggesting.







