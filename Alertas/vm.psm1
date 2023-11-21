function CreateMetricAlert {
    param(
        $rg,
        $metricName,
        $condition,
        $windowSize,
        $frequency,
        $location,
        $actionGroup,
        $targetScope,
        $description,
        $subsciption
    )

    # Adds or updates a V2 (non-classic) metric-based alert rule.
    Add-AzMetricAlertRuleV2 `
        -Name $metricName `
        -ResourceGroupName $rg `
        -WindowSize $windowSize `
        -Frequency $frequency `
        -TargetResourceScope $targetScope `
        -Condition $condition `
        -ActionGroupId $actionGroup.Id `
        -TargetResourceType "Microsoft.Compute/virtualMachines" `
        -Severity 3 `
        -TargetResourceRegion $location `
        -Description $description
    
    # -TargetResourceId $targetResourceId `
    
    Write-Host "Todo bien"
}