--Relational Algebra
select distinct t.declaration_id, t.account_number
from `edenred.txns` t
join `edenred.members_profile` mp on t.account_number = mp.account_number
where f_online = 1
-- Query time: 13.8 seconds
-- Performance: Good

--Uncorrelated Subquery
select distinct t.declaration_id, t.account_number
from `edenred.txns` t
where t.account_number IN
(select account_number from `edenred.members_profile` where f_online = 1)
-- Query time: 20.5 seconds
-- Performance: Average

--Correlated Subquery
select distinct t.declaration_id, t.account_number
from `edenred.txns` t
where EXISTS
(select * from `edenred.members_profile` mp where mp.account_number = t.account_number and f_online = 1)
-- Query time: 52.6 seconds
-- Performance: Worst

--Scalar Subquery in the where clause
select distinct t.declaration_id, t.account_number
from `edenred.txns` t
where
(select f_online from `edenred.members_profile` mp where t.account_number = mp.account_number) = 1
-- Query time: 47.4 seconds
-- Performance: Worst

--Scalar Subquery in the SELECT clause
select distinct t.declaration_id, (select mp.account_number from `edenred.members_profile` mp where mp.account_number = t.account_number and f_online =1) as account_number
from `edenred.txns` t
where (select mp.account_number from `edenred.members_profile` mp where mp.account_number = t.account_number and f_online =1) IS NOT NULL
-- Query time: 45.4 seconds
-- Performance: Worst

-- Aggregate function to check existence
select distinct t.declaration_id, t.account_number
from `edenred.txns` t
where (select count(*) from `edenred.members_profile` mp where mp.account_number = t.account_number and f_online =1) >0
-- Query time: 19.9 seconds
-- Performance: Average

-- Correlated subquery (double negative)
select distinct t.declaration_id, t.account_number
from `edenred.txns` t
where NOT EXISTS (select * from `edenred.members_profile` mp where mp.account_number = t.account_number and f_online !=1)
and t.account_number IS NOT NULL
-- Query time: 26.4 seconds
-- Performance: Average

-- Uncorrelated subquery (double negative)
select distinct t.declaration_id, t.account_number
from `edenred.txns` t
where t.account_number NOT IN
(select account_number from `edenred.members_profile` where f_online != 1)
-- Query time: 39.0 seconds
-- Performance: Bad

-- Resource: https://iggyfernandez.wordpress.com/2011/12/04/day-4-the-twelve-days-of-sql-there-way-you-write-your-query-matters/
