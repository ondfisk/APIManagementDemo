#!/bin/bash

CONFIGURATION="Release"
RESOURCE_GROUP="ApiManagementDemo"
WEBAPP="web-ex5jgvvj72oju"
DEPLOYMENT_SLOT="staging"

dotnet restore
dotnet build --no-restore --configuration $CONFIGURATION
dotnet test --no-build --verbosity normal --configuration $CONFIGURATION
dotnet publish src/Backend/Backend.csproj --no-build --configuration $CONFIGURATION --output app

pushd app && zip -r ../app.zip * && popd

az webapp deploy --resource-group $RESOURCE_GROUP --name $WEBAPP --slot $DEPLOYMENT_SLOT --src-path app.zip --clean

rm -rf app
rm app.zip

az webapp deployment slot swap --resource-group $RESOURCE_GROUP --name $WEBAPP --slot $DEPLOYMENT_SLOT
