param (
    # Flag representing all alerts
    [Parameter( HelpMessage = "Path to file containing desired emails (name,email-address):")]
    [string]$EmailFile,

    [Parameter( HelpMessage = "The ResourceGroup where the resources to monitor are located")]
    [string]$rg,

    [Parameter(HelpMessage = "The Subscription name where the resources to monitor are located")]
    [string]$subscription
)

$emailReceivers = @()

function GenerateEmailReceiver {
    param ( $emailrec )

    $name = $emailrec[0]; $email = $emailrec[1]

    # return "New-AzActionGroupReceiver `
    #     -Name $name `
    #     -EmailAddress $email" 
    return New-AzActionGroupReceiver -Name $name -EmailAddress $email
}

function CreateReceivers {
    # return (Get-Content -Path $EmailFile)[0]
    Get-Content -Path $EmailFile | ForEach-Object { $emailReceivers += (GenerateEmailReceiver $_.Split(",")) }
    return $emailReceivers
}

# Creates a new or updates an existing action group.
function CreateActionGroup {

    $receivers = CreateReceivers
    Write-Host $receivers

    # TODO Actualizar -Name y ShortName
    $actionGroup = Set-AzActionGroup `
        -Name "notify-admins" `
        -ShortName "ActionGroup1" `
        -ResourceGroupName $rg `
        -Receiver $receivers

    return $actionGroup
}

function CreateMetricAlert {
    param(
        $metricName,
        $condition,
        $windowSize,
        $frequency,
        $location,
        $SAId
    )

    $actionGroupId = (CreateActionGroup).Id
    # Adds or updates a V2 (non-classic) metric-based alert rule.
    Add-AzMetricAlertRuleV2 `
        -Name $metricName `
        -ResourceGroupName $rg `
        -WindowSize $windowSize `
        -Frequency $frequency `
        -Condition $condition `
        -ActionGroupId $actionGroupId `
        -TargetResourceType "Microsoft.Storage/storageAccounts" `
        -TargetResourceScope $SAId `
        -Severity 3 `
        -TargetResourceRegion $location
    
    # -TargetResourceId $targetResourceId `
    
    Write-Host "Todo bien"
}

$CapacityAlertCriteria = New-AzMetricAlertRuleV2Criteria `
    -MetricName "UsedCapacity" `
    -TimeAggregation Average `
    -Operator GreaterThan `
    -Threshold (100 * 1024 * 1024 * 1024)

$LatencyAlertCriteria = New-AzMetricAlertRuleV2Criteria `
    -MetricName "SuccessServerLatency" `
    -TimeAggregation Average `
    -Operator GreaterThan `
    -Threshold 150

$SAWindowSize = New-TimeSpan -Hours 6
$SAFrequency = New-TimeSpan -Minutes 5

if ($subscription.Length -gt 0) {
    $storageAccounts = Get-AzStorageAccount
}
else {
    $storageAccounts = Get-AzStorageAccount -ResourceGroupName $rg
}

foreach ($storageAccount in $storageAccounts) {
    # TODO Actualizar nombre MetricName
    CreateMetricAlert "$($storageAccount.StorageAccountName)CapRule" $CapacityAlertCriteria $SAWindowSize $SAFrequency $storageAccount.PrimaryLocation $storageAccount.Id
    CreateMetricAlert "$($storageAccount.StorageAccountName)LatRule" $LatencyAlertCriteria $SAWindowSize $SAFrequency $storageAccount.PrimaryLocation $storageAccount.Id
}