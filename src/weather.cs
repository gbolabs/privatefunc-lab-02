using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace src
{
    public class weather
    {
        private readonly ILogger _logger;

        public weather(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<weather>();
        }

        [Function("weather")]
        public HttpResponseData Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "text/plain; charset=utf-8");

            response.WriteString("Welcome to Azure Functions! Updated by GitHub Actions!");
            response.Headers.Add("X-AppVersion", "5.0.0");

            return response;
        }
    }
}
