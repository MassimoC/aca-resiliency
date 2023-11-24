FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["OrderGenerator/OrderGenerator.csproj", "OrderGenerator/"]
COPY ["Contracts/Contracts.csproj", "Contracts/"]
RUN dotnet restore "OrderGenerator/OrderGenerator.csproj"
COPY . .
WORKDIR "/src/OrderGenerator"
RUN dotnet build "OrderGenerator.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "OrderGenerator.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "OrderGenerator.dll"]