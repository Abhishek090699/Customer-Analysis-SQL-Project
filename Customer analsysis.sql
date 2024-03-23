drop database if exists customer_analysis;

create database customer_analysis;
use customer_analysis;

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-02-09'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;          
select * from product;       
select * from goldusers_signup;     
select * from users;     

# What is the total amount spent by each customer ?
SELECT 
    s.userid, SUM(p.price) AS Total_amount_spent
FROM
    sales s
        INNER JOIN
    product p ON s.product_id = p.product_id
GROUP BY s.userid
ORDER BY s.userid;

# How many days has each customer visited the store?
SELECT 
    userid, COUNT(DISTINCT created_date) AS No_of_visits
FROM
    sales
GROUP BY userid
ORDER BY userid;

# What was the first product purchased by each customer?
Select userid, created_date,product_id from (
SELECT *, rank() over(partition by userid order by created_date) rnk from sales) a 
where rnk=1;

# What is the most purchased product on menu and how many times was it purchased by all customers?
SELECT 
    userid,product_id,COUNT(product_id) AS total_purchase
FROM
    sales
WHERE
    product_id = (SELECT 
            product_id
        FROM
            sales
        GROUP BY product_id
        ORDER BY COUNT(product_id) DESC
        LIMIT 1)
GROUP BY userid, product_id
ORDER BY userid;

# Which item was the most popular for each customer?
select userid,product_id,cnt from
(select *, rank() over(partition by userid order by cnt desc) rnk from 
(select userid, product_id, count(product_id) as cnt from sales group by userid, product_id) a) b 
where rnk=1;

# Which item was purchased first by customer after they became gold member?
Select userid,product_id,created_date,gold_signup_date from
(Select *, rank() over(partition by userid order by created_date) rnk from
(Select s.userid, s.product_id, s.created_date, g.gold_signup_date from sales s inner join goldusers_signup g 
on s.userid=g.userid  where s.created_date >= g.gold_signup_date) a) b where rnk=1;

# Which item was purchased just before the customer became gold member?
Select userid,product_id,created_date,gold_signup_date from
(Select *, rank() over(partition by userid order by created_date desc) rnk from 
(Select s.userid, s.product_id, s.created_date, g.gold_signup_date from sales s inner join goldusers_signup g 
on s.userid=g.userid  where s.created_date <= g.gold_signup_date) a) b where rnk=1;

# What is the total orders and amount spent by each customer before they became member?
select userid, count(created_date) as total_orders, sum(price) as total_sales from 
(Select s.userid, s.product_id, s.created_date, g.gold_signup_date, p.price 
from sales s inner join goldusers_signup g on s.userid=g.userid inner join product p on s.product_id= p.product_id 
where s.created_date <= g.gold_signup_date) a group by userid order by userid; 
 
 # If buying each product generates points, e.g. 5Rs= 2 Points and each product has different purchasing points 
 # for e.g for p1 5RS=1 Point, for p2 10Rs= 5 Point and p3 5Rs= 1 Point , Calculate points collected by each customer 
 # and for which product most points have been given till now.
select *, round(total_amount/each_point_money,0) as total_points from (select *, case when product_id=1 then 5 
when product_id=2 then 2 when product_id=3 then 5 else 0 end as each_point_money 
from (Select s.userid, s.product_id, sum(p.price) as total_amount from sales s inner join product p 
on s.product_id=p.product_id group by s.userid, s.product_id) a) b order by userid, total_points desc;

# Calculating total points
select userid, sum(total_points) as total_points_earned from (select *, round(total_amount/each_point_money,0) as total_points from 
(select *, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as each_point_money 
from (Select s.userid, s.product_id, sum(p.price) as total_amount from sales s inner join product p 
on s.product_id=p.product_id group by s.userid, s.product_id) a) b) c group by userid order by userid;

# Calculating total money earned from points
select userid, sum(total_points)* 2.5 as total_money_earned from (select *, round(total_amount/each_point_money,0) as total_points 
from (select *, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as each_point_money 
from (Select s.userid, s.product_id, sum(p.price) as total_amount from sales s inner join product p 
on s.product_id=p.product_id group by s.userid, s.product_id) a) b) c group by userid order by userid;

# Calculating product with most points earned
select product_id,total_points_earned from (select *, rank() over(order by total_points_earned desc) rnk 
from (select product_id, sum(total_points) as total_points_earned 
from (select *, round(total_amount/each_point_money,0) as total_points 
from (select *, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as each_point_money 
from (Select s.userid, s.product_id, sum(p.price) as total_amount from sales s inner join product p 
on s.product_id=p.product_id group by s.userid, s.product_id) a) b) c group by product_id) d) e where rnk=1;

# In the first one year after a customer joins the gold program (including joining date) irrespective 
# of what customer has purchased they earn 5 points for every 10Rs spent. Who earned more 1 or 3 and 
# what was their points earnings in their first year? 
select a.*, p.price* 0.5 as total_points from (Select s.userid, s.product_id, s.created_date, g.gold_signup_date 
from sales s inner join goldusers_signup g on s.userid=g.userid  
where s.created_date >= g.gold_signup_date and s.created_date <= date_add(g.gold_signup_date, interval 1 year)) a 
inner join product p on a.product_id=p.product_id ;



 









