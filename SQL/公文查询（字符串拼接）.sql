SELECT t1.ObjectID InstaceId,
	t1.SequenceNo,
	t1.InstanceName,
	t2.Code CreateBy,
	t2.[Name] CreateByName,
	t1.StartTime,
	(
		CASE WHEN t1.FinishTime = '9999-12-31 23:59:59.000'
		THEN null
		ELSE t1.FinishTime
		END
	) FinishTime,
	t3.ActivityDisplayName,
	(
		SELECT STUFF(
			(SELECT ',' + t5.[Name]
			FROM OT_WorkItem t4
			JOIN OT_User t5
				ON t5.ObjectID = t4.Participant
			WHERE t4.InstanceId = t3.InstanceId
				AND t4.TokenId = t3.TokenId
			FOR XML PATH('')),
			1,
			1,
			''
		)
	) Approvers
FROM OT_InstanceContext t1
JOIN OT_User t2
	ON t2.ObjectID = t1.Originator
LEFT JOIN OT_WorkItem t3
	ON t3.InstanceId = t1.ObjectID
	AND t3.TokenId = t1.NextTokenId - 1
WHERE t1.WorkflowCode IN ('885','817')
GROUP BY t1.ObjectID,
	t1.SequenceNo,
	t1.InstanceName,
	t2.Code,
	t2.[Name],
	t1.StartTime,
	t1.FinishTime,
	t3.ActivityDisplayName,
	t3.InstanceId,
	t3.TokenId