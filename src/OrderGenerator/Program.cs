using Bogus;
using Contracts;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text;
using Microsoft.AspNetCore.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();
const string APPLICATION_JSON = "application/json";

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseDeveloperExceptionPage();
}

// In the current preview, resiliency policies can be used using Azure Container Apps service discovery only 
// examples : 
// - http://orderprocessor
// - http://orderprocessor...azurecontainerapps.io


HttpClient httpClient = new();
httpClient.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue(APPLICATION_JSON));
Console.WriteLine("... HTTP CLIENT initialized");

string? targetUrl = Environment.GetEnvironmentVariable("ACA_APP_Target_URL");
Console.WriteLine("... TARGET URL : " + targetUrl);

app.UseStatusCodePages(async statusCodeContext
    => await Results.Problem(statusCode: statusCodeContext.HttpContext.Response.StatusCode)
                 .ExecuteAsync(statusCodeContext.HttpContext));

app.MapPost("/generate", async (int totalOrders) =>
{
        for (int orderIncrement = 0; orderIncrement < totalOrders; orderIncrement++)
        {
            var order = GenerateOrder();
            Console.WriteLine("... Generated ORDER {0} :: bought by {1} {2}",order.Id.ToString(), order.Customer.FirstName, order.Customer.LastName);

        var jsonOrder = JsonSerializer.Serialize<Order>(order);
            var stringOrder = new StringContent(jsonOrder, Encoding.UTF8, APPLICATION_JSON);

            var response = await httpClient.PostAsync($"{targetUrl}/orders", stringOrder);
            Console.WriteLine("... Service INVOCATION for ORDER: {0}",order.Id);

            await Task.Delay(TimeSpan.FromMilliseconds(1500));
        }
})  
.WithName("GenerateOrders")
.WithOpenApi();

await app.RunAsync();


static Order GenerateOrder()
{
    var customerGenerator = new Faker<Customer>()
        .RuleFor(u => u.FirstName, (f, u) => f.Name.FirstName())
        .RuleFor(u => u.LastName, (f, u) => f.Name.LastName());

    var orderGenerator = new Faker<Order>()
        .RuleFor(u => u.Customer, () => customerGenerator)
        .RuleFor(u => u.Id, f => Guid.NewGuid().ToString())
        .RuleFor(u => u.Amount, f => f.Random.Number(1, 100))
        .RuleFor(u => u.ArticleNumber, f => f.Commerce.Product());

    return orderGenerator.Generate();
}