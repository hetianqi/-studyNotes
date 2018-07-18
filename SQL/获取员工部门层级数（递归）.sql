;WITH cte AS
(
	SELECT t1.DepId,
		t1.AdminID
	FROM oDepartment t1
	WHERE t1.DepId = (
		SELECT DepId
		FROM eEmployee
		WHERE Badge = '006403'
	)
	UNION ALL    
	SELECT t2.DepId,
		t2.AdminID
	FROM oDepartment t2
	JOIN cte 
		ON t2.DepID = cte.AdminID
)
SELECT DepId FROM cte