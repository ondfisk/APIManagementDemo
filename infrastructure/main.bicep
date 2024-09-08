param location string = resourceGroup().location
param logAnalyticsWorkspaceName string = 'MyLogAnalyticsWorkspace'
param appServicePlanName string = 'MyAppServicePlan'
param webAppName string = 'web-${uniqueString(resourceGroup().id)}'
param apimName string = 'api-${uniqueString(resourceGroup().id)}'
param apimTier string = 'Developer'
param apimCapacity int = 1
param apimOrganizationName string
param apimAdminEmail string
param tenantId string = subscription().tenantId
param clientId string
param allowedOrigins string
param scopes string

var azureAdInstance = environment().authentication.loginEndpoint
var callbackPath = '/signin-oidc'
var deploymentSlotName = 'staging'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  kind: 'linux'
  location: location
  sku: {
    name: 'P0v3'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    hyperV: false
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|9.0'
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      healthCheckPath: '/healthz'
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

resource deploymentSlot 'Microsoft.Web/sites/slots@2023-12-01' = {
  name: deploymentSlotName
  parent: webApp
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    hyperV: false
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|9.0'
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      healthCheckPath: '/healthz'
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

resource webAppBasicPublishingCredentialsFtp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  name: 'ftp'
  parent: webApp
  properties: {
    allow: false
  }
}

resource slotBasicPublishingCredentialsFtp 'Microsoft.Web/sites/slots/basicPublishingCredentialsPolicies@2023-12-01' = {
  name: 'ftp'
  parent: deploymentSlot
  properties: {
    allow: false
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {}
}

resource webAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: webAppName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource appSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: webAppInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    AzureAd__Instance: azureAdInstance
    AzureAd__TenantId: tenantId
    AzureAd__ClientId: clientId
    AzureAd__CallbackPath: callbackPath
    AzureAd__Scopes: scopes
    Cors__AllowedOrigins: allowedOrigins
  }
}

resource slotConfigNames 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'slotConfigNames'
  parent: webApp
  properties: {
    appSettingNames: [
      'APPLICATIONINSIGHTS_CONNECTION_STRING'
    ]
    azureStorageConfigNames: []
    connectionStringNames: []
  }
}

resource stagingAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${webAppName}-staging'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource stagingAppSettings 'Microsoft.Web/sites/slots/config@2023-12-01' = {
  name: 'appsettings'
  parent: deploymentSlot
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: stagingAppInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    AzureAd__Instance: azureAdInstance
    AzureAd__TenantId: tenantId
    AzureAd__ClientId: clientId
    AzureAd__CallbackPath: callbackPath
    AzureAd__Scopes: scopes
    Cors__AllowedOrigins: allowedOrigins
  }
}

resource apimAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: apimName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource apimDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: apim
  name: 'default'
  properties: {
    logs: [
      {
        category: 'GatewayLogs'
        categoryGroup: null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
      {
        category: 'WebSocketConnectionLogs'
        categoryGroup: null
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
    metrics: [
      {
        enabled: false
        retentionPolicy: {
          days: 0
          enabled: false
        }
        category: 'AllMetrics'
      }
    ]
    workspaceId: logAnalyticsWorkspace.id
    logAnalyticsDestinationType: 'Dedicated'
  }
}

resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: apimTier
    capacity: apimCapacity
  }
  zones: []
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherName: apimOrganizationName
    publisherEmail: apimAdminEmail
  }
  dependsOn: []
}

resource apimServiceLogger 'Microsoft.ApiManagement/service/loggers@2019-01-01' = {
  parent: apim
  name: apimAppInsights.name
  properties: {
    loggerType: 'applicationInsights'
    resourceId: apimAppInsights.id
    credentials: {
      instrumentationKey: apimAppInsights.properties.InstrumentationKey
    }
  }
}

resource apimServiceDiagnostic 'Microsoft.ApiManagement/service/diagnostics@2019-01-01' = {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: apimServiceLogger.id
    alwaysLog: 'allErrors'
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
  }
}
