param (
    # Flag representing all alerts
    [Parameter(Mandatory, Position = 0, HelpMessage = "Path to file containing desired emails (name,email-address):")]
    [string]$EmailFile,

    [Parameter(Mandatory, HelpMessage = "The ResourceGroup where the resources to monitor are located")]
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
        $frequency
    )

    if ($subscription.Length -gt 0) {
        $targetResourceScope = (Get-AzSubscription -SubscriptionName $subscription).ResourceId
        $targetResourceScope = "/subscriptions/$((Get-AzSubscription -SubscriptionName $subscription).Id)"
    } else {
        # TODO Menasaje que pregunte si continuar solo con el resource group
        $targetResourceScope = (Get-AzResourceGroup -Name $rg).ResourceId
    }

    $actionGroupId = (CreateActionGroup).Id
    # Adds or updates a V2 (non-classic) metric-based alert rule.
    Add-AzMetricAlertRuleV2 `
        -Name $metricName `
        -ResourceGroupName $rg `
        -WindowSize $windowSize `
        -Frequency $frequency `
        -TargetResourceScope $targetResourceScope `
        -Condition $condition `
        -ActionGroupId $actionGroupId `
        -TargetResourceType "Microsoft.Compute/virtualMachines" `
        -Severity 3 `
        -TargetResourceRegion "eastus"
    
    # -TargetResourceId $targetResourceId `
    
    Write-Host "Todo bien"
}

$CPUAlertCriteria = New-AzMetricAlertRuleV2Criteria `
        -MetricName "Percentage CPU" `
        -TimeAggregation Average `
        -Operator GreaterThan `
        -Threshold 80

$CPUAlertWSize = New-TimeSpan -Minutes 1
$CPUAlertFrequency = New-TimeSpan -Minutes 1

$RAMAlertCriteria = New-AzMetricAlertRuleV2Criteria `
        -MetricName "Available Memory Bytes" `
        -TimeAggregation Average `
        -Operator GreaterThan `
        -Threshold 1000000000 `

$AvailAlertCriteria = New-AzMetricAlertRuleV2Criteria `
        -MetricName "VmAvailabilityMetric" `
        -TimeAggregation Average `
        -Operator LessThan `
        -Threshold 0.95 `

# TODO Leer vars.csv y crear cada vm o todas

# VM Availability Metric (Preview)
# Create CPU Metric Alert
CreateMetricAlert "CPURule" $CPUAlertCriteria $CPUAlertWSize $CPUAlertFrequency

# Create CPU Metric Alert
CreateMetricAlert "RAMRule" $RAMAlertCriteria $CPUAlertWSize $CPUAlertFrequency

# Create Availability Alert
CreateMetricAlert "AvailabilityRule" $AvailAlertCriteria $CPUAlertWSize $CPUAlertFrequency