$ErrorActionPreference = "Stop"

$CONFIGURATION="Release"
$RESOURCE_GROUP="ApiManagementDemo"
$WEBAPP="web-ex5jgvvj72oju"
$DEPLOYMENT_SLOT="staging"

dotnet restore
dotnet build --no-restore --configuration $CONFIGURATION
dotnet test --no-build --verbosity normal --configuration $CONFIGURATION
dotnet publish src/Backend/Backend.csproj --no-build --configuration $CONFIGURATION --output app

Push-Location app
Compress-Archive -DestinationPath ../app.zip .
Pop-Location

az webapp deploy --resource-group $RESOURCE_GROUP --name $WEBAPP --slot $DEPLOYMENT_SLOT --src-path app.zip --clean
az webapp deployment slot swap --resource-group $RESOURCE_GROUP --name $WEBAPP --slot $DEPLOYMENT_SLOT

Remove-Item ./app -Recurse -Force
Remove-Item ./app.zip
