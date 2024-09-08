using Frontend;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using Microsoft.AspNetCore.Components.WebAssembly.Authentication;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

var downstreamApi = builder.Configuration["DownstreamApi:BaseUrl"] ?? throw new InvalidOperationException("DownstreamApi BaseUrl is missing");
var scopes = builder.Configuration["DownstreamApi:Scopes"] ?? throw new InvalidOperationException("DownstreamApi Scopes are missing");
var subscriptionKey = builder.Configuration["DownstreamApi:SubscriptionKey"] ?? throw new InvalidOperationException("DownstreamApi SubscriptionKey is missing");

builder.Services.AddScoped(sp =>
{
    var authorizationMessageHandler = sp.GetRequiredService<AuthorizationMessageHandler>();
    authorizationMessageHandler.InnerHandler = new HttpClientHandler();
    authorizationMessageHandler = authorizationMessageHandler.ConfigureHandler(
        authorizedUrls: [downstreamApi],
        scopes: scopes.Split(','));
    var client = new HttpClient(authorizationMessageHandler)
    {
        BaseAddress = new Uri(downstreamApi),
    };
    client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", subscriptionKey);
    return client;
});

builder.Services.AddMsalAuthentication(options =>
{
    builder.Configuration.Bind("AzureAd", options.ProviderOptions.Authentication);
    foreach (var scope in scopes.Split(','))
    {
        options.ProviderOptions.DefaultAccessTokenScopes.Add(scope);
    }
});

await builder.Build().RunAsync();
