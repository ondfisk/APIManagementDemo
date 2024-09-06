namespace WebApi.Tests;

public class WeatherTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task Get_given_no_access_token_returns_401()
    {
        // Arrange
        var client = factory.CreateClient();

        // Act
        var response = await client.GetAsync("/weatherforecast");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // TODO: Test authentication
    // [Fact]
    // public async Task Get_returns_5_weather_objects()
    // {
    //     // Arrange
    //     var client = factory.CreateClient();

    //     // Act
    //     var response = await client.GetAsync("/weatherforecast");

    //     // Assert
    //     response.EnsureSuccessStatusCode(); // Status Code 200-299
        
    //     var weatherForecasts = await response.Content.ReadFromJsonAsync<WeatherForecast[]>();

    //     weatherForecasts!.Length.Should().Be(5);
    // }
}
