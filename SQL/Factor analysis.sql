-- Task_1_Research the sampling

-- Build various groupings and study the null values in the sample.
-- Build the distribution of the number of bonds for each currency.
-- Build the distribution of the number of bonds for each bond issuу per month.
-- Build the distribution of the number of bonds for each bond duration.


-- The distribution of the number of bonds for each currency  

select  currency
      , count(id_oblig) as cnt_cur
from skyfinance.obligation
group by currency
having currency is not null

-- The distribution of the number of bonds for each bond issue per month        
with ipm as
        (
        select  date_trunc('month', issue_date) as month
        , count(currency) as cnt_cur
        from skyfinance.obligation
        group by month
        )
select *
from ipm
where month is not null
order by month

-- The distribution of the number of bonds for each bond duration        

with ipm as
        (
        select  length_month
              , count(currency) as cnt_cur
        from skyfinance.obligation
        group by length_month
        )
select *
from ipm
where length_month is not null
order by length_month

select *
from skyfinance.obligation

select*
from skyfinance.oblig_dict 

-- Task_2 Docoding type of obligation
-- The *class* field in the *skyfinance.obligation* table shows the bond class (type) identifier.
-- Decipher the identifiers using the *skyfinance.oblig_dict* table.

select  a.*
      , name_oblig
from skyfinance.obligation a
join skyfinance.oblig_dict b
on a.class = b.id_oblig


-- Tasks_3 Risk and return
-- The market rule says: the higher the return of a financial instrument, the higher the associated risk.

-- What is the safest currency?
-- What is the safest bond class?
-- Which "class-currency" segment is the safest and, conversely, the most profitable?
-- You are given a list of "risk ratings" of various currencies: -- Euro - 0.59
                                                                 -- Dollar - 0.72
                                                                 -- Ruble - 0.86
                                                                 -- Yen - 0.32
-- Is the return on our portfolio instruments really adequate to the market, considering the inverse relationship between risk and return?

-- Define the safest currency

with  rr as
        (
        select    currency
                , avg(interest_rate) as avg_rate
        from skyfinance.obligation
        group by currency
        )
select *
from rr
where currency is not null
order by avg_rate

-- Define the safest bond class

with sfc as
        (
        select  class
              , avg(interest_rate) as avg_rate
        from skyfinance.obligation
        group by class
        )
select *
from sfc
where class is not null
order by avg_rate

-- The safest bond class is 100.


Define the most profitable "class-currency" segment  

with prfc as
        (
        select  currency
                , class
                , avg(interest_rate) as avg_rate
        from skyfinance.obligation
        group by   currency
                 , class
        )
select *
from prfc
where class is not null and currency is not null
order by avg_rate

-- Task_4: Conversion of portfolio into rubles
-- Examine the *skyfinance.exchange_rate* table. Using it, you need to calculate the value of the entire portfolio in rubles.
-- Each bond must be converted into rubles at the exchange rate on the day the bond is issued.
-- If such a date is not in the *exchange_rate* table, then calculate the rate on that day as the average rate for the entire table.
-- Also add a field that will show how many rubles (based on the day of issue) the bond will bring in profit over its entire life.
-- To do this, you need to multiply the life expectancy by the interest rate by the nominal ruble value (based on the day of issue).

with prfrub as
    (
    select    avg(exchange_rate_euro) as avg_euro
            , avg(exchange_rate_usd) as avg_usd
            , avg(exchange_rate_yen) as avg_yen
    from skyfinance.exchange_rate
    )
select  *,
        (case   when currency = 'USD' AND date is not null then nominal_value * exchange_rate_usd
                when currency = 'USD' AND date is null then nominal_value * (select avg_usd from prfrub)
                when currency = 'EUR' AND date is not null then nominal_value * exchange_rate_euro
                when currency = 'EUR' AND date is null then nominal_value * (select avg_euro from prfrub)
                when currency = 'YEN' AND date is not null then nominal_value * exchange_rate_yen
                when currency = 'YEN' AND date is null then nominal_value * (select avg_yen from prfrub)
                else nominal_value
        end) as rur_value
        , length_month * interest_rate * (case   when currency = 'USD' AND date is not null then nominal_value * exchange_rate_usd
                when currency = 'USD' AND date is null then nominal_value * (select avg_usd from prfrub)
                when currency = 'EUR' AND date is not null then nominal_value * exchange_rate_euro
                when currency = 'EUR' AND date is null then nominal_value * (select avg_euro from prfrub)
                when currency = 'YEN' AND date is not null then nominal_value * exchange_rate_yen
                when currency = 'YEN' AND date is null then nominal_value * (select avg_yen from prfrub)
                else nominal_value
        end) as profit
from skyfinance.obligation bon
    left join skyfinance.exchange_rate exr
    on bon.issue_date = exr.date
where currency is not null
order by profit desc

