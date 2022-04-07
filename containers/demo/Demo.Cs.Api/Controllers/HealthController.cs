namespace WeatherApp.Api.Controllers;

using Microsoft.AspNetCore.Mvc;

public class HealthController : ControllerBase
{
    [HttpGet]
    [Route("")]
    public int Get()
    {
        return 200;
    }
}
