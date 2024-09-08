using './main.bicep'

param location = 'swedencentral'
param apimOrganizationName = 'Microsoft Danmark ApS'
param apimAdminEmail = 'rasmusl@microsoft.com'
param clientId = 'edeb4634-c6d4-4f6a-b1df-50706208711c'
param allowedOrigins = 'https://localhost:7122'
param scopes = 'Forecast.Read'
