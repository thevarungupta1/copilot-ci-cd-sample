# syntax=docker/dockerfile:1.7
ARG DOTNET_VERSION=8.0

FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_VERSION}-alpine AS base
WORKDIR /app

EXPOSE 8080
ENV ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_EnableDiagnostics=0 \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# Create an unprivileged user for runtime security.
RUN addgroup -S appgroup \
    && adduser -S -D -H -G appgroup appuser

FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION}-alpine AS build
WORKDIR /src

# Copy project file first to maximize Docker layer caching for restore.
COPY ["SampleApp.csproj", "./"]
RUN dotnet restore "SampleApp.csproj" --nologo

# Copy everything else and build.
COPY . .
RUN dotnet build "SampleApp.csproj" -c Release -o /app/build --no-restore --nologo

FROM build AS publish
RUN dotnet publish "SampleApp.csproj" -c Release -o /app/publish --no-build --nologo /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

USER appuser
ENTRYPOINT ["dotnet", "SampleApp.dll"]
