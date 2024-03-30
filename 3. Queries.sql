#A3.2 Assignment
#Andrea Wupuy

USE mban_a32_aws_services;

#1. Type of service Popularity: Users per type of service offered 
WITH both_t AS
(
SELECT 
	ca.user_id AS user_,
    ca.action_date AS action_d,
    ca.action_name AS action_n,
    ca.error_message AS error_m,
    ca.device AS device,
    (CASE WHEN ps.action_date IS NULL THEN 0 ELSE ps.action_date END) as suscription_date,
    (CASE WHEN ps.action_date IS NOT NULL THEN 1 ELSE 0 END) as suscribers_,
    (CASE WHEN ca.action_name LIKE '%success%' THEN 1 ELSE 0 END) as success_,
    (CASE WHEN ca.action_name LIKE '%fail%' THEN 1 ELSE 0 END) as fail_,
    (CASE WHEN ca.action_name LIKE '%fail%' THEN 'fail' 
    WHEN ca.action_name LIKE '%success%' THEN 'success' 
    ELSE 'prime' END) as type_sf,
	(CASE 
    WHEN ca.action_name LIKE '%annual_prime%' THEN 'annual_prime'
    WHEN ca.action_name LIKE '%monthly_prime%' THEN 'monthly_prime'
    WHEN ca.action_name LIKE '%one-medical%' THEN 'one_medical'
    WHEN ca.action_name LIKE '%giftcards%' THEN 'giftcards'
    WHEN ca.action_name LIKE '%prime-video-channels%' THEN 'prime_video'
    WHEN ca.action_name LIKE '%quarterly_prime%' THEN 'quarterly_prime'
    WHEN ca.action_name LIKE '%lifetime_prime%' THEN 'lifetime_prime'
    WHEN ca.action_name LIKE '%faster-delivery%' THEN 'quarterly_prime'
    WHEN ca.action_name LIKE '%amazon-music%' THEN 'amazon_music'
    ELSE 'landing'
    END) as type_action
FROM checkout_actions AS ca
LEFT JOIN prime_subscriptions AS ps
ON ca.user_id = ps.user_id
GROUP BY ca.user_id
)
,

checkout AS
(
SELECT
type_action,
COUNT(user_) AS users_at_checkout,
COUNT(user_) 
	/ (SELECT COUNT(user_) FROM both_t WHERE type_action NOT LIKE 'landing')
    AS percentfail_checkout
FROM both_t
WHERE type_action NOT LIKE 'landing'
GROUP BY type_action
ORDER BY users_at_checkout DESC
)

SELECT
type_action,
users_at_checkout,
percentfail_checkout,
SUM(percentfail_checkout)
OVER (
ORDER BY users_at_checkout DESC
  ) AS cumulative_percentfail_checkout
FROM checkout
GROUP BY type_action
ORDER BY users_at_checkout DESC
;
#The most popular subscription types are annual and monthly, accounting for 92.48% of total checkouts. 


#2. Checkout Percentage: Out of the total users, how many get to the "checkout section"
SELECT
COUNT(user_id) 
	/ (SELECT COUNT(user_id) FROM checkout_actions) 
    AS per_success,
COUNT(user_id)
FROM checkout_actions
WHERE action_name LIKE '%checkout%'
;
#Only 34.56% of the customers make it to the checking section


#3. Fail in Checkout Percentage: From the users that get to the "checkout section", how many have errors?
SELECT
COUNT(user_id) 
	/ (SELECT COUNT(user_id) FROM checkout_actions WHERE action_name LIKE '%checkout%') 
    AS per_success,
COUNT(user_id)
FROM checkout_actions
WHERE action_name LIKE '%checkout%'
AND action_name LIKE '%fail%'
;
# 68.34% of the users that go to the checkout section have an error message.


#4. Total error messages received
SELECT 
	count(user_id) AS total_errors
FROM checkout_actions 
WHERE action_name LIKE '%fail%'
;
#Total errors: 2,962 


#5. Top 5 errors messages: count of users per error messages
WITH both_t AS
(
SELECT 
	ca.user_id AS user_,
    ca.action_date AS action_d,
    ca.action_name AS action_n,
    ca.error_message AS error_m,
    ca.device AS device,
    (CASE WHEN ps.action_date IS NULL THEN 0 ELSE ps.action_date END) as suscription_date,
    (CASE WHEN ps.action_date IS NOT NULL THEN 1 ELSE 0 END) as suscribers_,
    (CASE WHEN ca.action_name LIKE '%success%' THEN 1 ELSE 0 END) as success_,
    (CASE WHEN ca.action_name LIKE '%fail%' THEN 1 ELSE 0 END) as fail_,
    (CASE WHEN ca.action_name LIKE '%fail%' THEN 'fail' 
    WHEN ca.action_name LIKE '%success%' THEN 'success' 
    ELSE 'prime' END) as type_sf,
	(CASE 
    WHEN ca.action_name LIKE '%annual_prime%' THEN 'annual_prime'
    WHEN ca.action_name LIKE '%monthly_prime%' THEN 'monthly_prime'
    WHEN ca.action_name LIKE '%one-medical%' THEN 'one_medical'
    WHEN ca.action_name LIKE '%giftcards%' THEN 'giftcards'
    WHEN ca.action_name LIKE '%prime-video-channels%' THEN 'prime_video'
    WHEN ca.action_name LIKE '%quarterly_prime%' THEN 'quarterly_prime'
    WHEN ca.action_name LIKE '%lifetime_prime%' THEN 'lifetime_prime'
    WHEN ca.action_name LIKE '%faster-delivery%' THEN 'quarterly_prime'
    WHEN ca.action_name LIKE '%amazon-music%' THEN 'amazon_music'
    ELSE 'landing'
    END) as type_action,
	(CASE 
    WHEN ca.action_name LIKE '%annual_prime%' THEN 'annual_prime'
    WHEN ca.action_name LIKE '%monthly_prime%' THEN 'monthly_prime'
    WHEN ca.action_name LIKE '%quarterly_prime%' THEN 'quarterly_prime'
    WHEN ca.action_name LIKE '%lifetime_prime%' THEN 'lifetime_prime'
    ELSE 0
    END) as main_services
FROM checkout_actions AS ca
LEFT JOIN prime_subscriptions AS ps
ON ca.user_id = ps.user_id
GROUP BY ca.user_id
)

SELECT
 COUNT(user_) AS users_total,
 error_m
FROM both_t
WHERE error_m IS NOT NULL
GROUP BY error_m
ORDER BY users_total DESC
LIMIT 5;
# It is estimated that 69% of the 2962 total errors are mainly due to user mistakes, such as the number field, the year and the last name not 
# being filled out correctly, each of which has 1220, 684 and 148 errors.

#6. Is there seasonality? Users per month
WITH both_t AS 
(
SELECT 
	ca.user_id AS user_,
    ca.action_date AS action_d,
    ca.action_name AS action_n,
    ca.error_message AS error_m,
    ca.device AS device,
    ps.action_date AS suscription_date,
    (CASE WHEN ps.action_date IS NOT NULL THEN 1 ELSE 0 END) as suscribers_,
    (CASE WHEN ca.action_name LIKE '%success%' THEN 1 ELSE 0 END) as success_,
    (CASE WHEN ca.action_name LIKE '%fail%' THEN 1 ELSE 0 END) as fail_,
    (CASE WHEN ca.action_name LIKE '%fail%' THEN 'fail' 
    WHEN ca.action_name LIKE '%success%' THEN 'success' 
    ELSE 'prime' END) as type_sf,
	(CASE 
    WHEN ca.action_name LIKE '%annual_prime%' THEN 'annual_prime'
    WHEN ca.action_name LIKE '%monthly_prime%' THEN 'monthly_prime'
    WHEN ca.action_name LIKE '%one-medical%' THEN 'one_medical'
    WHEN ca.action_name LIKE '%giftcards%' THEN 'giftcards'
    WHEN ca.action_name LIKE '%prime-video-channels%' THEN 'prime_video'
    WHEN ca.action_name LIKE '%quarterly_prime%' THEN 'quarterly_prime'
    WHEN ca.action_name LIKE '%lifetime_prime%' THEN 'lifetime_prime'
    WHEN ca.action_name LIKE '%faster-delivery%' THEN 'quarterly_prime'
    WHEN ca.action_name LIKE '%amazon-music%' THEN 'amazon_music'
    ELSE 'landing'
    END) as type_action
FROM checkout_actions AS ca
LEFT JOIN prime_subscriptions AS ps
ON ca.user_id = ps.user_id
GROUP BY ca.user_id
)

SELECT
	MONTH(action_d) AS month_1,
    COUNT(user_) AS users_,
    SUM(success_) AS succes_,
    SUM(fail_) AS fail_
FROM both_t
WHERE MONTH(action_d) IS NOT NULL
GROUP BY MONTH(action_d)
ORDER BY MONTH(action_d) ASC
;
#November is the peak month for errors with 1702. 
