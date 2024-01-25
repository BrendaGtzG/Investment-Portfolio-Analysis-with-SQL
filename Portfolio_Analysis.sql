USE invest;

-- Code developed by Eji and Brenda in order to analize the portfolio of the selected clients and provide investment advice.

CREATE VIEW team61 AS -- I contributed with this view to my team so I could call it in the code below where the assets were included to see how diversified their portfolio was
SELECT 	transact.dates AS 'date',
        transact.ticker,
        transact.Major_Asset,
		transact.Minor_Asset,
        transact.price,
        ROUND(transact.quantity * transact.price,2) AS AUM,
         ROUND((transact.price - transact.lagged_price) / transact.lagged_price, 2) AS returns
FROM (
SELECT 
				pdn.date AS dates, pdn.ticker AS ticker, pdn.value AS price, sm.major_asset_class AS Major_Asset, sm.minor_asset_class AS Minor_Asset, 
                hc.value AS Fund, hc.quantity AS Quantity,
                sm.security_name AS S_Name,
                LAG(pdn.value, 250) OVER(
									PARTITION BY pdn.ticker
                                    ORDER BY pdn.date
									) AS lagged_price
FROM customer_details AS cd
INNER JOIN account_dim AS a
	ON cd.customer_id = a.client_id
INNER JOIN holdings_current AS hc
	ON a.account_id = hc.account_id
INNER JOIN security_masterlist AS sm
	ON hc.ticker = sm.ticker
INNER JOIN pricing_daily_new AS pdn
	ON sm.ticker = pdn.ticker
 WHERE (cd.customer_id = 44 OR cd.customer_id = 11 OR cd.customer_id = 120) /* Added this clause to get the a list of all the securities those clients invested in throughout the year.
 The idea is to merge those client's portfolios to see what were the securities with higher risk adjusted returns and recommend them to invest in those securities this year.
 We also used this code per client and identified the securities with the lowest performance so the final advice is to trade those securities for the ones with the best 
 performance last year since we asume they will provide a good return as well this year.*/
		AND pdn.price_type = 'Adjusted'
        AND pdn.date BETWEEN '2019/09/09' AND '2022/09/09')
-- ORDER BY cd.customer_id) 
AS transact
ORDER BY returns DESC;

SELECT sub1.*, sm.major_asset_class -- I decided to include the major_asset_class in order to deep dive into the kind of assets the clients invested into the last year
FROM (SELECT ticker, COUNT(ticker) AS quantity, ROUND(AVG(returns),2) as mu, ROUND(STD(returns),2) as sigma, ROUND(AVG(returns)/std(returns),2) as risk_adj_returns
FROM team61 -- Here I call the view created above (in the first code) and used the code Prof. Thomas taught in class in order to see mu, sigma and the risk adjusted returns
GROUP BY ticker) AS sub1
LEFT JOIN security_masterlist AS sm
ON sub1.ticker = sm.ticker
ORDER BY risk_adj_returns; -- We decided to order it this way in order to spot the top type of assets