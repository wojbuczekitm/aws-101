namespace WeatherApp.Api.Controllers;

using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("[controller]")]
public class HelloController : ControllerBase
{
    [HttpGet("{name?}")]
    public string Get([FromRoute] string? name=null)
    {
        return $"Hello {name ?? "World"}";
    }
}
