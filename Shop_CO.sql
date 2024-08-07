/* 

1. Import the dataset and do usual exploratory analysis steps like checking the
    structure & characteristics of the dataset.                              */


#  A. Data type of all columns in the “customers” table.

select column_name , data_type
from target-project-431704.shop_co.INFORMATION_SCHEMA.COLUMNS
where table_name = 'customers'



# B. Get the time range between which the orders were placed.


select min(order_purchase_timestamp) as first_order_date ,
       max(order_purchase_timestamp) as last_order_date
from `target-project-431704.shop_co.orders`


# C. Count the Cities & States of customers who ordered during the given period.

select count(distinct(customer_city )) as no_of_city , 
	   count(distinct(customer_state)) as no_of_state
from `shop_co.customers`






# 2.In-depth Exploration:




# A. Is there a growing trend in the no. of orders placed over the past years?

select extract(year FROM order_purchase_timestamp) as year , 
	   count(order_id) as no_of_order
from `target-project-431704.shop_co.orders`
group by year 
order by year



# B. Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
 
select extract(year FROM order_purchase_timestamp ) as year , 
	   format_datetime('%B' , order_purchase_timestamp ) as month ,count(order_id)
from `target-project-431704.shop_co.orders`
group by year , month
order by year asc



# C. During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night

select time_of_day , count(customer_id) as no_of_order
from (
select customer_id ,order_id ,  
        case 
        when extract(time from order_purchase_timestamp ) 
        between '00:00:00' and '06:00:00' then 'Dawn(0-6)'

        when extract(time from order_purchase_timestamp ) 
        between '07:00:00' and '12:00:00' then 'Morning(7-12)'

        when extract(time from order_purchase_timestamp) 
        between '13:00:00' and '18:00:00' then 'Afternon(13-18)'

        when extract(time from order_purchase_timestamp)
        between '19:00:00' and '23:00:00' then 'Night(19-23)' end as time_of_day 
from shop_co.orders ) a
where time_of_day is not null
group by time_of_day
order by no_of_order desc






# 3. Evolution of E-commerce orders in the Brazil region: 

# A. Get the month on month no. of orders placed in each state.

select customer_state , 
extract(year from order_purchase_timestamp) as year , 
extract(month from order_purchase_timestamp) as month , 
count(a.customer_id) as no_of_order
from    shop_co.customers   a
inner join     shop_co.orders   b
on a.customer_id = b.customer_id
group by customer_state, year ,month
order by year , month


# B. How are the customers distributed across all the states?

select customer_state , count(distinct(customer_id)) as no_of_customers
from `shop_co.customers`
group by customer_state


# 4.Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.

# A. Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only). 

select year,
			round( 100* (   ( lead(Total_financial_payment) over (order by year)-
			Total_financial_payment)   / Total_financial_payment ),1 ) as percent_increase
from 	(   
		select
 		      extract(year from o.order_purchase_timestamp) as year,
 		       sum(p.payment_value) as Total_financial_payment
 		from  shop_co.orders  o 
 		inner join shop_co.payments  p
 		on o.order_id = p.order_id
		where o.order_purchase_timestamp between '2017-01-01' and '2017-08-31'
		      or o.order_purchase_timestamp between '2018-01-01' and '2018-08-31'
		group by year
		order by year asc ) a


# B. Calculate the Total & Average value of order price for each state.

select customer_state as state ,
sum(price) as total_price , avg(price) as avg_price

from `shop_co.customers` a
join shop_co.orders b
on a.customer_id = b.customer_id
join shop_co.order_items c
on b.order_id = c.order_id
group by state



# C.Calculate the Total & Average value of order freight for each state.

select customer_state as state ,sum(freight_value) as total_price ,
 avg(freight_value) as avg_price
from `shop_co.customers` a
join shop_co.orders b
on a.customer_id = b.customer_id
join shop_co.order_items c
on b.order_id = c.order_id
group by state


# 5 .Analysis based on sales, freight and delivery time.

/* A.Find the no. of days taken to deliver each order from the order’s purchase date 
as delivery time. Also, calculate the difference (in days) between the estimated & actual delivery
date of an order.  */


select order_id,timestamp_diff( order_delivered_customer_date,order_purchase_timestamp , day ) as No_of_days_deliver , 
	   timestamp_diff(order_estimated_delivery_date, order_delivered_customer_date ,day) as estimate_day
from shop_co.orders
where order_delivered_customer_date is not null and 
	  order_estimated_delivery_date is not null
order by order_id


# B.Find out the top 5 states with the highest & lowest average freight value.

( select customer_state, 'High' as value_high_or_low , avg(freight_value) as average_value
from shop_co.customers a
join shop_co.orders b
on a.customer_id = b.customer_id
join shop_co.order_items c
on b.order_id = c.order_id
group by customer_state 
order by average_value desc
limit 5 )

union all

(select customer_state, 'Low' as value_high_or_low , avg(freight_value) as average_value
from shop_co.customers a
join shop_co.orders b
on a.customer_id = b.customer_id
join shop_co.order_items c
on b.order_id = c.order_id
group by customer_state 
order by average_value asc
limit 5 )
order by average_value desc


#C.Find out the top 5 states with the highest & lowest average delivery time


(select  customer_state ,'High' as status ,avg(timestamp_diff( order_delivered_customer_date ,   
 		 order_purchase_timestamp , day ) ) as avg_delivered
from shop_co.orders a
join shop_co.customers b
on a.customer_id = b.customer_id
group by customer_state 
order by avg_delivered desc
limit 5)

union all 

(select  customer_state ,'Low' as status ,avg(timestamp_diff( order_delivered_customer_date ,   
 		order_purchase_timestamp , day ) ) as avg_delivered
from shop_co.orders a
join shop_co.customers b
on a.customer_id = b.customer_id
group by customer_state 
order by avg_delivered asc
limit 5 )
order by avg_delivered desc


# D.Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.
   

select customer_state ,  avg(timestamp_diff(order_estimated_delivery_date , order_delivered_customer_date,day) ) as actual_order_day
from shop_co.orders a
join shop_co.customers b
on a.customer_id = b.customer_id
group by customer_state
order by actual_order_day asc
limit 5
 


