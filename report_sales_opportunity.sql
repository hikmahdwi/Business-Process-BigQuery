WITH oppParent AS (
  SELECT opp_sal.id, opp_sal.opportunityNumber, opp_sal.assignedUserName as salesName, user.defaultTeamName as teamName, opp_sal.brand
  FROM (SELECT opp.id, opp.opportunityNumber, opp.assignedUserName, opp.assignedUserId, acc.brand FROM `bp_aptana.bp_opportunities` opp
    LEFT JOIN `bp_aptana.bp_account` acc
    ON opp.accountId = acc.id) opp_sal
  LEFT JOIN `bp_aptana.bp_user` user
  ON opp_sal.assignedUserId = user.id
),

oppCall AS (
  SELECT COUNT(id) as salesCall, parentId FROM `bp_aptana.bp_call` 
  WHERE status = "Held" GROUP BY parentId
),

oppMeet AS (
  SELECT COUNT(id) as salesMeet, parentId FROM `bp_aptana.bp_meeting`
  WHERE status = "Held" GROUP BY parentId
),

parentData AS (
  SELECT oppca.id, oppca.opportunityNumber, oppca.salesName, oppca.teamName, oppca.brand, oppca.salesCall, oppm.salesMeet
  FROM (SELECT oppa.id, oppa.opportunityNumber, oppa.salesName, oppa.teamName, oppa.brand, oppc.salesCall
    FROM oppParent oppa
    LEFT JOIN oppCall oppc
    ON oppa.id = oppc.parentId) oppca
  LEFT JOIN oppMeet oppm ON oppca.id = oppm.parentId
),

quosoa AS (
  SELECT IF(quo.approveDate is null, CAST(quo.modifiedAt as STRING), quo.approveDate) as quoteDate, quo.opportunityId, 
  quo.id as quoId, soa.id as soaId, IF(soa.approveDate is null, CAST(soa.modifiedAt as STRING), soa.approveDate) as soaDate
  FROM `bp_aptana.bp_quotes` quo
  LEFT JOIN `bp_aptana.bp_soa` soa
  ON quo.id = soa.quoteId
),

dateData AS (
  SELECT quosoa.*, IF(inv.approveDate is null, CAST(inv.modifiedAt as STRING), inv.approveDate) as invDate
  FROM quosoa LEFT JOIN `bp_aptana.bp_invoice` inv 
  ON quosoa.quoId = inv.quoteId AND quosoa.soaId = inv.salesOrderId
)

SELECT pd.id, pd.opportunityNumber, pd.salesName, pd.teamName, pd.brand, 
  IF(pd.salesCall is null, 0, pd.salesCall) as salesCall,
  IF(pd.salesMeet is null, 0, pd.salesMeet) as salesMeet,
  IF(dd.quoteDate is null, "-", dd.quoteDate) as quoteDate,
  IF(dd.soaDate is null, "-", dd.soaDate) as soaDate, 
  IF(dd.invDate is null, "-", dd.invDate) as invDate
FROM parentData pd
LEFT JOIN dateData dd ON pd.id = dd.opportunityId