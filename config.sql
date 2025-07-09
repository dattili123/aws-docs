SELECT 
  eventTime,
  eventSource,
  eventName,
  userIdentity.type,
  userIdentity.principalId,
  userIdentity.arn,
  userIdentity.accountId,
  requestParameters.roleArn,
  requestParameters.roleSessionName,
  awsRegion,
  sourceIPAddress,
  userAgent,
  errorCode,
  responseElements.assumedRoleUser.arn,
  sessionContext.sessionIssuer.arn,
  sessionContext.sessionIssuer.userName,
  sessionContext.sourceIdentity
WHERE eventName = 'AssumeRole'
  AND eventTime >= timestamp '2025-04-10T00:00:00Z'
  AND userIdentity.arn LIKE '%:role/prod%comp'
  AND requestParameters.roleArn IN (
    'arn:aws:iam::123456789012:role/TargetRole1',
    'arn:aws:iam::123456789013:role/TargetRole2'
  )
