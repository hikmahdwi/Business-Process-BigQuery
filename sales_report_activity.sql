WITH reportA As(
  SELECT calling.dateCall, idSalesCall, calling.salesCall, meeting.meetDate, idSalesMeet, meeting.salesMeeting FROM (
    SELECT CAST(modifiedAt as DATE) as dateCall, assignedUserId as idSalesCall,  
    COUNT(DISTINCT id) as salesCall 
    FROM `bp_aptana.bp_call` WHERE status = "Held"
    GROUP BY dateCall, assignedUserId) calling
  FULL OUTER JOIN (
    SELECT CAST(modifiedAt as DATE) as meetDate, assignedUserId as idSalesMeet,
    COUNT(DISTINCT id) as salesMeeting 
    FROM `bp_aptana.bp_meeting` WHERE status = "Held"
    GROUP BY meetDate, assignedUserId) meeting
  ON calling.dateCall = meeting.meetDate AND calling.idSalesCall = meeting.idSalesMeet
), 

callMeet AS ( SELECT (
  CASE
    WHEN dateCall is null THEN meetDate
    ELSE dateCall
  END) dateCallMeet, (
  CASE 
    WHEN idSalesCall is null THEN idSalesMeet
    ELSE idSalesCall
  END) salIdCallMeet, 
salesCall, salesMeeting
FROM reportA),

reportB As(
  SELECT quote.quoteDate, salesIdQuote, quote.salesQuotes, soa.soaDate, salesIdSoa, soa.salesSoa FROM (
    SELECT IF(approveDate is null, DATETIME_TRUNC(modifiedAt, DAY), DATETIME_TRUNC(CAST(approveDate AS DATETIME), DAY)) as quoteDate, assignedUserId as salesIdQuote, 
    COUNT(DISTINCT id) as salesQuotes
    FROM `bp_aptana.bp_quotes` WHERE status = "Approved"
    GROUP BY quoteDate, assignedUserId) quote
  FULL OUTER JOIN (
    SELECT IF(approveDate is null, DATETIME_TRUNC(modifiedAt, DAY), DATETIME_TRUNC(CAST(approveDate AS DATETIME), DAY)) as soaDate, assignedUserId as salesIdSoa, 
    COUNT(DISTINCT id) as salesSoa
    FROM `bp_aptana.bp_soa` WHERE status = "Approved"
    GROUP BY soaDate, assignedUserId) soa
  ON quote.quoteDate = soa.soaDate AND quote.salesIdQuote = soa.salesIdSoa
),

quoteSoa AS ( SELECT (
  CASE
    WHEN quoteDate is null THEN soaDate
    ELSE quoteDate
  END) dateQuoteSoa, (
  CASE 
    WHEN salesIdQuote is null THEN salesIdSoa
    ELSE salesIdQuote
  END) salIdQuoteSoa, 
salesQuotes, salesSoa
FROM reportB),

salesActivity AS (
  SELECT 
    (CASE WHEN dateCallMeet is null THEN dateQuoteSoa ELSE dateCallMeet END) theDate, 
    (CASE WHEN salIdCallMeet is null THEN salIdQuoteSoa ELSE salIdCallMeet END) salesId, 
    salesCall,salesMeeting,salesQuotes,salesSoa,
  FROM (
    SELECT callMeet.*, quoteSoa.* 
    FROM callMeet FULL OUTER JOIN quoteSoa
    ON callMeet.dateCallMeet = quoteSoa.dateQuoteSoa AND callMeet.salIdCallMeet = quoteSoa.salIdQuoteSoa)
),

salesIdentity AS (
  SELECT id, name, defaultTeamName FROM `bp_aptana.bp_user`
)

SELECT sa.theDate, sa.salesId, 
  IF(sa.salesCall is null, 0, sa.salesCall) as salesCall, 
  IF(sa.salesMeeting is null, 0, sa.salesMeeting) as salesMeeting,
  IF(sa.salesQuotes is null, 0, sa.salesQuotes) as salesQuotes,
  IF(sa.salesSoa is null, 0, sa.salesSoa) as salesSoa,
  si.name, si.defaultTeamName 
FROM salesActivity sa 
LEFT JOIN salesIdentity si ON sa.salesId = si.id 
WHERE sa.salesId != "65af611ef12663080" AND sa.salesId != "657a7f77efd8884f3"AND sa.salesId != "657a7f0a273be88fb"