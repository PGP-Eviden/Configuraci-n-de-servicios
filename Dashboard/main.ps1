param(
    [Parameter(Mandatory, HelpMessage = "The ResourceGroup where the resources to monitor are located")]
    [string]$rg,

    [Parameter(HelpMessage = "The Subscription name where the resources to monitor are located")]
    [string]$subscriptionID,

    [Parameter(HelpMessage = "The location")]
    [string]$location,

    [Parameter(HelpMessage = "The location")]
    [string]$saName
)

# Comprobar que subscriptionID y rg son correctos
Get-AzSubscription -SubscriptionId $subscriptionID -ErrorAction Break

#New-AzResourceGroup -Name $rg -Location $location

$ContentMen = Get-Content -Path '.\Metricas_VM_mensual.json' -Raw
$ContentMen = $ContentMen -replace '<subscriptionID>', $subscriptionID
$ContentMen = $ContentMen -replace '<rgName>', $rg
$ContentMen = $ContentMen -replace '<title>', 'CONTURSA'
$ContentMen = $ContentMen -replace '<location>', $location
$ContentMen = $ContentMen -replace '<dTitle>', "Monthly_Metric_VM"

$DashPathmen = ".\nuevo.json"
New-Item $DashPathmen -ItemType File -Force
$ContentMen | Out-File -FilePath $DashPathmen -Force

$DashboardParams = @{
    DashboardPath = $DashPathmen
    ResourceGroup = $rg
    DashboardName = "Monthly_Metric_VM"
}

New-AzPortalDashboard @DashboardParams

# $ContentBu = Get-Content -Path '.\Metricas_Backups.json' -Raw
# $ContentBu = $ContentBu -replace '<subscriptionID>', $subscriptionID
# $ContentBu = $ContentBu -replace '<rgName>', $rg
# $ContentBu = $ContentBu -replace '<title>', 'UQUIFA prod'
# $ContentBu = $ContentBu -replace '<location>', $location
# $ContentBu = $ContentBu -replace '<dTitle>', "Backup_Health_Metric"

# $DashPathBu = ".\nuevo_bu.json"
# New-Item $DashPathBu -ItemType File -Force
# $ContentBu | Out-File -FilePath $DashPathBu -Force

# $DashboardParamsBu = @{
#     DashboardPath = $DashPathBu
#     ResourceGroup = $rg
#     DashboardName = "Backup_Health_Metric"
# }

# New-AzPortalDashboard @DashboardParamsBu

$SA = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $saName} 

if ($null -eq $SA) {
    Write-Host "The storage account $SA could not be found"
    exit
}

$ContentSA = Get-Content -Path '.\StorageAccount_Backuplabcomputes.json' -Raw
$ContentSA = $ContentSA -replace '<subscriptionID>', $subscriptionID
$ContentSA = $ContentSA -replace '<rgName>', $rg
$ContentSA = $ContentSA -replace '<title>', 'CONTURSA'
$ContentSA = $ContentSA -replace '<location>', $location
$ContentSA = $ContentSA -replace '<dTitle>', "Metric_SA_$($SA.StorageAccountName)"
$ContentSA = $ContentSA -replace '<SAId>', $SA.Id

$DashPathSA = ".\nuevo_st.json"
New-Item $DashPathSA -ItemType File -Force
$ContentSA | Out-File -FilePath $DashPathSA -Force

$DashboardParamsSA = @{
    DashboardPath = $DashPathSA
    ResourceGroup = $rg
    DashboardName = "Metric_SA"
}

New-AzPortalDashboard @DashboardParamsSA

#.\main.ps1 -rg Monitorizacion -subscription subscriptionIP -location westeurope -saName StorageName