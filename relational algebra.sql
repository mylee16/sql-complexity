-- Relational Algebra

SELECT DISTINCT t.declaration_id, t.account_number
FROM `edenred.txns` t
JOIN `edenred.members_profile` mp ON t.account_number = mp.account_number
WHERE f_online = 1

-- Query time: 13.8 seconds
-- Performance: Good
