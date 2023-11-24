param appName string

resource app2aca 'Microsoft.App/containerApps@2023-05-02-preview' existing = {
  name: appName
}

resource acaPolicyRetry 'Microsoft.App/containerApps/resiliencyPolicies@2023-08-01-preview' = {
  name: 'app-resiliency-retry'
  parent: app2aca
  properties: {
    httpRetryPolicy: {
        maxRetries: 5
        retryBackOff: {
          initialDelayInMilliseconds: 1000
          maxIntervalInMilliseconds: 5000
        }
        matches: {
            headers: [
                {
                    header: 'x-retriable-status-code'
                    match: { 
                       exactMatch: 'true'
                    }
                }
            ]
            errors: [
                'retriable-headers'
            ]
        }
    } 
    circuitBreakerPolicy: {
        consecutiveErrors: 3
        intervalInSeconds: 10
        maxEjectionPercent: 50
    }
  }
}


