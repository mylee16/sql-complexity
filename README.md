# Title: SQL Join Efficiency

#8 different ways to write an SQL queries and the efficiency of each

Recently while working on Salesforce Marketing Cloud platform, Daniel and I came across an SQL query written by our external vendor in a form that we were rather unfamiliar with. It goes like this:

```
SELECT ace.cardNumber, ace.emailAddress
FROM ent."SG Extract" ace
WHERE EXISTS (SELECT de.Domain FROM [SG_Bounce_Disposable_Domains] de WHERE ace.emailAddress LIKE '%@'+ de.Domain + '%')
AND NOT EXISTS (SELECT ce.SubscriberKey FROM ent.[SG_opens_all] ce WHERE ace.cardNumber = ce.SubscriberKey)
```

Notice that two of its sub-queries reference the main table in the where table

(picture here)

This query performed very badly on Salesforce Marketing Cloud with long runtime and frequent timeout, giving us much frustration. Unlike Google Bigquery which we are familiar with, Salesforce Marketing Cloud have a much lower compute and cannot process the load of a complex query.

This prompted an intellectual curiosity within the team, `How many ways can we write an SQL query and what is the time complexity of each queries?`

We decided to replay an experiment based on a 1988 article by Fabian Pascal on Google Bigquery to compare the performance of different ways of writing an SQL query.

Method 1: Relational Algebra
The relational algebra is the most common way of writing a query and also the most natural and efficient way to do so.
```
SELECT DISTINCT t.declaration_id, t.account_number
FROM `edenred.txns` t
JOIN `edenred.members_profile` mp ON t.account_number = mp.account_number
WHERE f_online = 1
-- Query time: 13.8 seconds
-- Performance: Good
```
​Method 2: Uncorrelated Subquery
This query does the filter function by first creating a subquery list of account_number, followed by an IN function to filter account number in the subquery.
```
SELECT DISTINCT t.declaration_id, t.account_number
FROM `edenred.txns` t
WHERE t.account_number IN
(SELECT account_number FROM `edenred.members_profile` WHERE f_online = 1)
-- Query time: 20.5 seconds
-- Performance: Average
```

Method 3: Correlated Subquery
The EXISTS function can be used to search in an unfiltered subquery `SELECT *`, however for filter operation it requires a `where mp.account_number = t.account_number` embedded in the subquery which reduce efficiency.
```
SELECT DISTINCT t.declaration_id, t.account_number
FROM `edenred.txns` t
WHERE EXISTS
(SELECT * FROM `edenred.members_profile` mp WHERE mp.account_number = t.account_number AND f_online = 1)
-- Query time: 52.6 seconds
-- Performance: Worst
```

Method 4: Scalar Subquery in the WHERE clause
By using a subquery as a filter on the WHERE function, the query is able to filter f_online = 1. Quite a cool way of think but unfortunately it doesn't perform well.
```
SELECT DISTINCT t.declaration_id, t.account_number
FROM `edenred.txns` t
WHERE
(SELECT f_online FROM `edenred.members_profile` mp WHERE t.account_number = mp.account_number) = 1
-- Query time: 47.4 seconds
-- Performance: Worst
```

Method 5: Scalar Subquery in the SELECT clause
Another really interesting way of writing a query. This method uses a subquery in the SELECT function to extract the account_number from another table, but as the two tables have a many to many relation, we have to add in a filter to remove the nulls.
```
SELECT DISTINCT t.declaration_id
  , (SELECT mp.account_number FROM `edenred.members_profile` mp WHERE mp.account_number = t.account_number AND f_online =1) AS account_number
FROM `edenred.txns` t
WHERE (SELECT mp.account_number FROM `edenred.members_profile` mp WHERE mp.account_number = t.account_number AND f_online =1) IS NOT NULL
-- Query time: 45.4 seconds
-- Performance: Worst
```

Method 6: Aggregate function to check existence
Similar to Scalar Subquery this method uses a subquery in the WHERE function. The difference is that this method uses a subquery COUNT(*) with a filter of >1.
```
SELECT DISTINCT t.declaration_id, t.account_number
FROM `edenred.txns` t
WHERE (select COUNT(*) FROM `edenred.members_profile` mp WHERE mp.account_number = t.account_number AND f_online =1) >0
-- Query time: 19.9 seconds
-- Performance: Average
```

Method 7: Correlated subquery (double negative)
Similar to Correlates Subquery but uses a double negative.
```
SELECT DISTINCT t.declaration_id, t.account_number
FROM `edenred.txns` t
where NOT EXISTS (SELECT * FROM `edenred.members_profile` mp WHERE mp.account_number = t.account_number AND f_online !=1)
AND t.account_number IS NOT NULL
-- Query time: 26.4 seconds
-- Performance: Average
```

Method 8: Uncorrelated subquery (double negative)
Similar to Uncorrelated subquery but uses a double negative.
```
SELECT DISTINCT t.declaration_id, t.account_number
FROM `edenred.txns` t
where t.account_number NOT IN
(SELECT account_number FROM `edenred.members_profile` WHERE f_online != 1)
-- Query time: 39.0 seconds
-- Performance: Bad
```

In conclusion, the way we write our SQL query does have a big impact on the efficiency of the query. The most efficient query runs for 13.8 seconds compared to the least efficient query runtime of 52.6 seconds.

We re-wrote the inefficient query by our external vendor on Salesforce Marketing Cloud and we were able to reduce the run time from 45 mins + frequent timeout to 4 mins.

Bonus: Queries don't start from `SELECT` but `FROM`. Now we know why LIMIT doesn't reduce compute cost.
https://jvns.ca/blog/2019/10/03/sql-queries-don-t-start-with-select/ (thanks to Shawn for sharing this)


Reference
*1988 article by Fabian Pascal "SQL Redundancy and DBMS Performance" in the journal Database Programming & Design - http://www.dbdebunk.com/2013/02/language-redundancy-and-dbms.html
*Day 4: The Twelve Days of SQL: The way you write your query matters - https://iggyfernandez.wordpress.com/2011/12/04/day-4-the-twelve-days-of-sql-there-way-you-write-your-query-matters/
