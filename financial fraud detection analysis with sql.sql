SELECT * FROM finance.cc_data;
use finance;
/* 1.0
The total number of transactions in the cc_data table
*/
select count(trans_num)
from cc_data;

/*2.0
The top 10 most frequent merchants in the cc_data table */
select merchant, count(trans_num)
from cc_data
group by 1
order by 2 DESC
LIMIT 10;

/*3.0
The average transaction amount for each category of transactions
 in the cc_data table
 */
 select category, round(avg(amt),2) as avg_transaction_amt
 from cc_data
 group by 1
 order by 2 DESC;
 
 /*4.0
The number of fraudulent transactions and the percentage of total 
transactions that they represent 
*/

select 
     count(*) as total_transaction,
     sum(case when is_fraud = 1 then 1 else 0 end) as fraud_transaction,
     (sum(case when is_fraud = 1 then 1 else 0 end)/count(*)*100) as percentage_fraud_transaction
from cc_data;

/*5.0
Joined the cc_data and location_data tables to identify the latitude and longitude of 
each transaction
*/
select c.cc_num, c.trans_num, c.state, c.city, c.street, l.lat, l.long, c.amt
from cc_data as c join location_data as l on c.cc_num = l.cc_num;

/*6.0
The city with the highest population in the location_data table
*/

SELECT city, MAX(city_pop) AS population
FROM cc_data
GROUP BY city
ORDER BY population DESC
LIMIT 10;



/*Using Data Aggregation with SQL: */

/*7.0
The total amount spent across all transactions in the cc_data table 
*/
select sum(amt) as total_amount_spent
from cc_data;

/*8.0
Transactions occurred in each category in the cc_data table
*/
select category, count(trans_num) as transaction_count
from cc_data
group by category
order by transaction_count DESC;

/*9.0
Average transaction amount for each gender in the cc_data table
*/
select gender, round(avg(amt),2) as average_transaction_amount 
from cc_data
group by gender;









 




