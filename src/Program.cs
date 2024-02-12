using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureAppConfiguration(configureDelegate=> {
        // Add configuration sources
        configureDelegate.AddUserSecrets<Program>();
    })
    .Build();

host.Run();
