# Azure API Management Demo

## Prerequisites

Two app registrations - one for the backend and one for the frontend.

Backend should expose and API with the scope `Forecast.Read`.

Frontend should be configured to consume the API.

## Configuration

API Management needs to be setup manually.

### Specification

Open API specification can be found at:

- <https://localhost:7075/openapi/v1.json>
- <https://web-ex5jgvvj72oju.azurewebsites.net/openapi/v1.json>

### Policy settings

```xml
<inbound>
    <base />
    <cors allow-credentials="false">
        <allowed-origins>
            <origin>*</origin>
        </allowed-origins>
        <allowed-methods>
            <method>*</method>
        </allowed-methods>
        <allowed-headers>
            <header>*</header>
        </allowed-headers>
    </cors>
    <validate-azure-ad-token tenant-id="18f459d7-049e-4645-8567-d0c65eeef42e">
        <audiences>
            <audience>api://edeb4634-c6d4-4f6a-b1df-50706208711c</audience>
        </audiences>
    </validate-azure-ad-token>
</inbound>
```

## Test

To run frontend update the `DownstreamApi:SubscriptionKey` in [`appsettings.json`](src/Frontend/wwwroot/appsettings.json).
