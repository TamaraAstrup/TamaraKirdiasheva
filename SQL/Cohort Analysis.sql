-- Analysis of the distribution of the first customer purchases and the distribution of number of purchases

select    count (*) as cnt
        , is_trial
        , name_partner
        , rank_user
from (
        select cl.*
             , name_partner
             , row_number () over (order by date_purchase) as rn_all -- ranking the number of all purchases
             , row_number () over (partition by user_id order by date_purchase) as rank_user -- ranking the number of all purchases by user
        from skycinema.client_sign_up cl
             left join skycinema.partner_dict as pr 
             on cl.partner = pr.id_partner
    ) t
    group by is_trial
            , name_partner
            , rank_user
-- The result of this query is a selection of data with a ranking of users and counting of rows for each combination of values is_trial, name_partner and rank_user.


-- Calculating the vintage customer lifetime value (CLV) by partner.
select t.*
      ,cnt_2 / cnt_1 as rr_2 -- сustomer retention from the 1st to the 2nd purchase
      ,cnt_3 / cnt_1 as rr_3 -- сustomer retention from the 1st to the 3nd purchase
      ,cnt_4 / cnt_1 as rr_4 -- сustomer retention from the 1st to the 4nd purchase
      ,cnt_5 / cnt_1 as rr_5 -- сustomer retention from the 1st to the 5nd purchase
      ,cnt_6 / cnt_1 as rr_6 -- сustomer retention from the 1st to the 6nd purchase
from (
    select  name_partner
            , sum(case when rank_user = 1 then 1 else 0 end)::float as cnt_1 -- count the number of customers who have reached a certain number of purchases
            , sum(case when rank_user = 2 then 1 else 0 end)::float as cnt_2
            , sum(case when rank_user = 3 then 1 else 0 end)::float as cnt_3
            , sum(case when rank_user = 4 then 1 else 0 end)::float as cnt_4
            , sum(case when rank_user = 5 then 1 else 0 end)::float as cnt_5
            , sum(case when rank_user = 6 then 1 else 0 end)::float as cnt_6
    from (
        select  cl.*
               , name_partner
               , row_number () over (partition by user_id order by date_purchase) as rank_user
        from skycinema.client_sign_up cl 
            left join skycinema.partner_dict pr
                on cl.partner = pr.id_partner
        ) tt
    group by name_partner
    ) t
    -- The result of this query is a table with calculated the CLV and counted the number of purchases by partner

    