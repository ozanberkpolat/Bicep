using './main.bicep'

param labName = 'lab'
param domainName = 'contoso.local'
param domainNetbiosName = 'CONTOSO'
param adminUsername = 'labadmin'

// Passwords from the environment, never committed. Example (bash):
//   export LAB_ADMIN_PASSWORD='...' LAB_DSRM_PASSWORD='...'
param adminPassword = readEnvironmentVariable('LAB_ADMIN_PASSWORD')
param dsrmPassword = readEnvironmentVariable('LAB_DSRM_PASSWORD')

// Documentation range: replace with your own public IP /32
param rdpSourceRange = '203.0.113.10/32'
