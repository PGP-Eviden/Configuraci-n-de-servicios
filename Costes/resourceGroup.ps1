$resourceGroups = Get-AzResourceGroup
$mes = Get-Date -Format "MM"
$body = @{
  "properties"= @{
    "category" = "Cost"
    "amount"= 2500
    "timeGrain" = "Monthly"
    "timePeriod"= @{
      "startDate" = "2023-$mes-01T00:00:00Z"
      "endDate" = "2023-12-31T00:00:00Z"
    }
    "notifications" = @{
      "Actual_GreaterThan_80_Percent" = @{
        "enabled" = $true
        "operator" = "GreaterThan"
        "threshold" = 90
        "locale" = "es-es"
        "contactEmails" = @()
        "thresholdType" = "Actual"
        "contactGroups" = @($actionGroup.Id)
      }
      "Forecasted_GreaterThan_100_Percent" = @{
        "enabled" = $true
        "operator" = "GreaterThan"
        "threshold" = 100
        "locale" = "es-es"
        "contactEmails" = @()
        "thresholdType" = "Forecasted"
        "contactGroups" = @($actionGroup.Id)
      }
      "Forecasted_GreaterThan_110_Percent" = @{
        "enabled" = $true
        "operator" = "GreaterThan"
        "threshold" = 110
        "locale" = "es-es"
        "contactEmails" = @()
        "thresholdType" = "Forecasted"
        "contactGroups" = @($actionGroup.Id)
      }
    }
  }
}
$token=(Get-AzAccessToken).token
$subscriptionId = (Get-AzSubscription).Id

foreach ($resourceGroup in $resourceGroups)
{
  Write-Host $resourceGroup.ResourceGroupName
  $rgName = $resourceGroup.ResourceGroupName
  $budgetName = "budget-$rgName"
  Invoke-RestMethod `
  -Method Put `
  -Headers @{"Authorization"="Bearer $token"} `
  -ContentType "application/json; charset=utf-8" `
  -Body (ConvertTo-Json $body -Depth 10) `
  -Uri https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Consumption/budgets/$($budgetName)?api-version=2023-03-01
}


