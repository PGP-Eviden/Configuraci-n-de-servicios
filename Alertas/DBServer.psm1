function CreateMetricAlert {
    param(
        $rg,
        $metricName,
        $condition,
        $windowSize,
        $frequency,
        $location,
        $actionGroup,
        $DBId,
        $description
    )

    $actionGroupId = $actionGroup.Id
    # Adds or updates a V2 (non-classic) metric-based alert rule.
    Add-AzMetricAlertRuleV2 `
        -Name $metricName `
        -ResourceGroupName $rg `
        -WindowSize $windowSize `
        -Frequency $frequency `
        -Condition $condition `
        -ActionGroupId $actionGroupId `
        -TargetResourceType "Microsoft.DBforPostgreSQL/flexibleServers" `
        -TargetResourceScope $DBId `
        -Severity 3 `
        -TargetResourceRegion $location `
        -Description $description
    
    # -TargetResourceId $targetResourceId `
    
    Write-Host "Todo bien"
}