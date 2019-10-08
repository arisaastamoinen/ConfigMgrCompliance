
CREATE VIEW vNonCompliantWorkstations
AS
SELECT 
	Col.Name AS CollectionName
	,RS.Name0 as 'Computername'
	,LI.Title AS SoftwareUpdateGroup
	,CASE
		WHEN UCSAll.Status = 0 THEN 'Unknown'
		WHEN UCSAll.Status = 1 or  UCSAll.Status = 3  THEN 'Compliant' -- 'Not Applicable'
		WHEN UCSAll.Status = 2 THEN 'Non-compliant' -- 'Required'
	END AS ComplianceStatus
	,CASE	
		WHEN USS.LastScanState = 0 THEN 'Scan state unknown'
		WHEN USS.LastScanState = 1 THEN 'Scan is waiting for catalog location'
		WHEN USS.LastScanState = 2 THEN 'Scan is running'
		WHEN USS.LastScanState = 3 THEN 'Scan completed'
		WHEN USS.LastScanState = 4 THEN 'Scan is pending retry'
		WHEN USS.LastScanState = 5 THEN 'Scan failed'
		WHEN USS.LastScanState = 6 THEN 'Scan completed with errors'
	END AS LastScanState
	,USS.LastScanTime
	,USS.LastStatusMessageID as LastStatusMessage
	,USS.LastErrorCode
	,CASE
		WHEN UCSAll.Status = 0 THEN 'Unknown'
		WHEN UCSAll.Status = 1 THEN 'Required'
		WHEN UCSAll.Status = 2 THEN 'Required'
		WHEN UCSAll.Status = 3 THEN 'Installed'
	END as ScanStatus
FROM
	dbo.v_R_System RS 
JOIN 
	dbo.v_Update_ComplianceStatusAll UCSAll ON UCSAll.ResourceID = RS.ResourceID
JOIN 
	dbo.v_FullCollectionMembership FCM ON RS.ResourceID = FCM.ResourceID
JOIN 
	dbo.v_Collection Col ON Col.CollectionID = FCM.CollectionID
JOIN 
	dbo.v_UpdateScanStatus USS ON UCSAll.ResourceId = USS.ResourceID
JOIN 
	dbo.v_AuthListInfo LI ON UCSAll.CI_ID = LI.CI_ID
WHERE 
	LI.Title IN ('All Updates')
	AND
	-- 'Software Update Compliance - Workstations' 
	Col.CollectionID = '<CollectionID>'
	and UCSAll.Status in (0, 2)
GO
