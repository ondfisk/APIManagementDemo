param location string = resourceGroup().location
param logAnalyticsWorkspaceName string
param applicationInsightsName string
param appServicePlanName string
param webAppName string

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

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
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
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    WEBSITE_RUN_FROM_PACKAGE: '1'
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

resource stagingApplicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${applicationInsightsName}-staging'
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
    APPLICATIONINSIGHTS_CONNECTION_STRING: stagingApplicationInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    WEBSITE_RUN_FROM_PACKAGE: '1'
  }
}
