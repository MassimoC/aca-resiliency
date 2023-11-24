using Contracts;
using Microsoft.Extensions.Logging;
using System.Collections;
using System.Diagnostics;
using System.Globalization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

Hashtable results = new Hashtable();

const string RETRIABLE_HEADER = "x-retriable-status-code";

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseDeveloperExceptionPage();
}

app.MapPost("/orders", (Order order, HttpContext context) =>
{
    
    Console.WriteLine("... [{0}] Processing ORDER {1} for {2} units of {3} bought by {4} {5}", DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture), order.Id, order.Amount, order.ArticleNumber, order.Customer.FirstName, order.Customer.LastName); 

    if (order.Amount < 60)
    {

        Console.WriteLine("... --> RETURNING [200]");
        SetState(results, order, 200);
        return Results.Ok(order.Amount);
    }
    else if (order.Amount > 80)
    {
        // retry will always fail (usecase for circuit breaker)
        Console.WriteLine("... --> RETURNING [503]");
        context.Response.Headers.Add(RETRIABLE_HEADER, "true");
        return Results.StatusCode(SetState(results, order, 503));
    }
    else
    {
        if (!results.ContainsKey(order.Id))
        {
            Console.WriteLine("... --> RETURNING [429]");
        }
        else
        {
            Console.WriteLine("... --> RETRYING AFTER [429]");

            // 70 chance to recover 
            if (isOK())
            {
                Console.WriteLine("... --> RETURNING [200]");
                results[order.Id] = 200;
                return Results.Ok(order.Amount);
            }            
        }
        context.Response.Headers.Add(RETRIABLE_HEADER, "true");
        return Results.StatusCode(SetState(results, order, 429));

    }

})
.WithName("ProcessOrders")
.WithOpenApi();

await app.RunAsync();


static bool isOK()
{
    Random r = new();
    int rInt = r.Next(1, 100);
    Console.WriteLine("... ... --> retry [ % of success {0}]" , rInt);
    return rInt >= 30;
}

static int SetState (Hashtable results, Order order, int statusCode)
{
    if (!results.ContainsKey(order.Id)) { results.Add(order.Id, 503); }
    return statusCode;
}

