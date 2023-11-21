param (
    [Parameter(Mandatory, Position = 0, HelpMessage = "Path to file containing desired emails (name,email-address)")]
    [string]$EmailFile,

    [Parameter(Mandatory, HelpMessage = "The ResourceGroup where the resources to monitor are located")]
    [string]$rg,

    [Parameter(HelpMessage = "Path to file containing the variables for the resources to be monitored")]
    [string]$VarFile,

    [Parameter(HelpMessage = "The Subscription name where the resources to monitor are located")]
    [string]$subscription,

    [Parameter(HelpMessage = "The Subscription name where the resources to monitor are located")]
    [string]$actionGroup
)

function AskUserInput {

    do {
        $InitInput = Read-Host "(Y) to continue or (N) to quit"
        if ($InitInput.ToLower().Equals("y")) {
            Write-Host
        }
        elseif ($InitInput.ToLower().Equals("n")) {
            Write-Host "Exiting...`n"

            exit
        }
    } while ($InitInput -ne "y" -and $InitInput -ne "n")
}

$scope = @{}

function AskScope {
    do {
        Write-Host "Select the scope of the resources:`n"
        $scopeInput = Read-Host "(R) for Resource Group | (S) for current Subscription"
        if ($scopeInput.ToLower().Equals("r")) {
            if ((Read-Host "Press [Enter] to use $(fmtForegrColor " $rg " def white) or [C] to change it").ToLower() -eq "c") {
                $rg = Read-Host "Enter a valid Resource Group`n"
            }
            do {
                $currentrg = Get-AzResourceGroup -Name $rg -ErrorAction SilentlyContinue

                if ($currentrg.ResourceGroupName.Length -le 0) {
                    Write-host "`n$rg NOT FOUND`n" -ForegroundColor Red
                    $rg = Read-Host "Enter a valid Resource Group`n"
                }
            } while ($currentrg.ResourceGroupName.Length -le 0)

            $scope["name"] = $currentrg.ResourceGroupName
            $scope["id"] = $currentrg.ResourceId
            $scope["type"] = "rg"
        }
        elseif ($scopeInput.ToLower().Equals("s")) {
            $subs = Get-AzSubscription -TenantId $subscription

            $scope["name"] = $subs.Name
            $scope["id"] = "/subscriptions/$($subs.Id)"
            $scope["type"] = "su"
        }
    } while ($scopeInput -ne "s" -and $scopeInput -ne "r")
    Write-Host "`nname:`t$(fmtForegrColor " $($scope.name) " def white)`nId:`t$($scope.id)`n"

    if ((Read-Host "Press [C] to change scope | [Enter] to continue").ToLower() -eq "c") {
        AskScope
    }
}

$metricNameDict = @{
    "CPU" = "Percentage CPU"
    "RAM" = "Available Memory Bytes"
    "AV"  = "VmAvailabilityMetric"
    #"CAP" = "UsedCapacity"
    #"LAT" = "SuccessServerLatency"
    "DIS" = "Availability"
}

$metricMultiplier = @{
    "CPU" = 1
    "RAM" = [Math]::Pow(1000, 2)
    "AV"  = 0.01
    #"CAP" = [Math]::Pow(1024, 3)
    #"LAT" = 1
    "DIS" = 1
}

function GetVmMemory {
    param(
        $vminfo
    )
    $vmsize = $vminfo.HardwareProfile.VmSize
    $vmsizeopt = Get-AzVMSize -VMName $vminfo.Name -ResourceGroupName $vminfo.ResourceGroupName | Where-Object { $_.Name -eq $vmsize }
    return $vmsizeopt.MemoryInMB
}

$storageAccounts = Get-AzStorageAccount

function ParseResource {
    param ( [array]$resourceLine )

    if ($resourceLine[0].Equals("recurso")) {
        return
    }

    [string]$resource = $resourceLine[0]; [string]$name = $resourceLine[1]

    if ($resource -eq "vm") {
        # TODO update to Get-AzVM once and loop through it (like ik StorageAccounts)
        if ($name -eq "*") {
            # TODO if -$rg -> Get-AzVM -ResourceGroupName $rg | ForEach-Object {
            $vms = @()


            $scope.type -eq "rg" ? (Get-AzVM $scope.name) : (Get-AzVM) | ForEach-Object {
                $vmMemoryInMB = GetVmMemory $_
                if (!($_.Name -in $resources.name)) { 
                    $vmId = $_.Id
                    $vms += [ordered]@{resource = $resource; name = $_.Name; location = $_.Location; memoryInMB = $vmMemoryInMB; limits = $(ReadResourceLimits $resourceLine[2] $vmMemoryInMB); group = $true; id = $vmId }
                }
            }
            return $vms
        } else {
            $azvm = Get-AzVM -Name $name -ErrorAction SilentlyContinue
            if (!$azvm) {
                Write-Host "`nVM $name could not be found in $($scope.name). Run `n`n`t(Get-AzVM -Name <vm-name>).ResourceGroupName`n`nto see where the VM is located`n"
                exit
            }

            $location = $azvm.Location
            $vmMemoryInMB = GetVmMemory $azvm
            $vmId = $azvm.Id
            return [ordered]@{resource = $resource; name = $name; location = $location; memoryInMB = $vmMemoryInMB; limits = $(ReadResourceLimits $resourceLine[2] $vmMemoryInMB); id = $vmId }
        }
        
    }
    else {
        if ($name -eq "*") {
            # TODO Guardar resourcegroup
            [hashtable]$limits = ReadResourceLimits $resourceLine[2] 
            $restSt = @()
            $storageAccounts | ForEach-Object {
                $stName = $_.StorageAccountName
                $currentStorageAccount = $storageAccounts | Where-Object { $stName -eq $_.StorageAccountName }
                $SAId = $currentStorageAccount.Id
                $restSt += [ordered]@{resource = $resource; name = $_.StorageAccountName; location = $currentStorageAccount.Location; limits = $limits; id = $SAId }
            }
            return $restSt
        }
        elseif (!($name -in $storageAccounts.StorageAccountName)) {
            Write-Host "`n$name not found in the current subscription`n" -ForegroundColor Red
        }
        else {
            [hashtable]$limits = ReadResourceLimits $resourceLine[2] 
            $currentStorageAccount = $storageAccounts | Where-Object { $_.StorageAccountName -eq $name }
            $SAId = $currentStorageAccount.Id
            return [ordered]@{resource = $resource; name = $name; location = $currentStorageAccount.Location; limits = $limits; id = $SAId }
        }
    }
}

[array]$resources = @()

function ReadResources {

    Get-Content -Path $VarFile | ForEach-Object { 
        $resources += (ParseResource $_.Split(";"))
    }

    return $resources
}

function ReadResourceLimits {
    param(
        [string]$lims,
        $maxMemory
    )

    $processedLims = @{}
    $lims.Split(",") | ForEach-Object {
        $limKV = $_.Split("=")
        if ($limKV[0] -eq "RAM") {
            $processedLims[$metricNameDict[$limKV[0]]] = $maxMemory * ( $metricMultiplier[$limKV[0]] * $limKV[1] ) * 0.01
        }
        else { $processedLims[$metricNameDict[$limKV[0]]] = $metricMultiplier[$limKV[0]] * $limKV[1] }
    } 

    return $processedLims
}

# 1. Read current vars and check correctness + alert state +
Import-Module -Name .\fmt.psm1 -Force -Prefix fmt


($VarFile.Length -gt 0) ? $(Write-Host "`nReading variables from file $(fmtForegrColor $VarFile yellow)`n") : $(Write-Host "`nVar File not found. The default parameters (found in the README.md) will be used instead:`n")
AskUserInput

AskScope

Write-Host `nResources:`n

$rs = ReadResources

$rs | ForEach-Object {
    $limitString = ""
    foreach ($key in $_["limits"].keys) {
        $limitString += "`n`t$key`: $($_["limits"][$key]) " 
    }

    Write-Host "type: $($_["resource"])"
    Write-Host "name: $($_["name"] -eq "*" ? "all/rest" : $_["name"])"
    Write-Host "location: $($_["location"])"
    if ($_["resource"] -eq "vm") { Write-Host "memory: $($_["memoryInMB"])" }
    Write-Host "limits: $limitString"
}
# 1.1. Ask if everything is ok

Write-Host 
AskUserInput

# 2. Create main Action Group
Import-Module -Name .\actiongroup.psm1 -Force
$actGroup = CreateActionGroup $rg $EmailFile

# 3. Create alerts
Import-Module -Name .\vm.psm1 -Prefix vm -Force
Import-Module -Name .\stacc.psm1 -Prefix st -Force

$rs | ForEach-Object {
    if ($_["resource"] -eq "st") { 
        foreach ($key in $_.limits.keys) {

            $val = $_.limits[$key]

            $SAWindowSize = New-TimeSpan -Hours 6
            $SAFrequency = New-TimeSpan -Minutes 5
            
            
            $isGreaterThan = ($key -eq "Availability") ? "LessThan" : "GreaterThanOrEqual"



            $SAId = $_.id

            $StCriteria = New-AzMetricAlertRuleV2Criteria `
                -MetricName $key `
                -TimeAggregation Average `
                -Operator $isGreaterThan `
                -Threshold $val

                $shortKey = ($key -eq "Availability") ? "Disponibilidad" 
                : ($key -eq "UsedCapacity") ? "Capacidad" 
                : ($key -eq "SuccessServerLatency") ? "Latencia"
                : "Error"  
            
            $unit = ($key -eq "UsedCapacity") ? "Bytes"
                : ($key -eq "Availability") ? "%"    
                : "ms"
                
                #$computed = ($key -eq "Availability") ? $val * 100 : $val
                
            
            $description = "Esta alerta se ejecuta cuando la  $shortKey es$(($key -eq "Availability") ? " menor que " : " mayor que ") $val $unit" 

            stCreateMetricAlert $rg `
                "CONTURSA-Azure-$($_.resource)-$key-$($_.name)" `
                $StCriteria `
                $SAWindowSize `
                $SAFrequency `
                $_.location `
                $actGroup `
                $SAId `
                $description
        
        }
    }
    else {
        foreach ($key in $_.limits.keys) {

            $val = $_.limits[$key]

            $CPUAlertWSize = New-TimeSpan -Minutes 5
            $CPUAlertFrequency = New-TimeSpan -Minutes 5

            $isGreaterThan = ($key -eq "VmAvailabilityMetric") ? "LessThan" : "GreaterThanOrEqual"

            $AvailAlertCriteria = New-AzMetricAlertRuleV2Criteria `
                -MetricName $key `
                -TimeAggregation Average `
                -Operator $isGreaterThan `
                -Threshold $val `

            $shortKey = ($key -eq "VmAvailabilityMetric") ? "Disponibilidad" 
                : ($key -eq "Percentage CPU") ? "CPU"
                : ($key -eq "Available Memory Bytes") ? "Memoria"
                : "Error"  
            
            $unit = ($key -eq "Available Memory Bytes") ? "Bytes"          
                : "%" 
                
            $computed = ($key -eq "VmAvailabilityMetric") ? $val * 100 : $val

            $description = "Esta alerta se ejecuta cuando la  $shortKey es $(($key -eq "VmAvailabilityMetric") ? "menor que " : "mayor que") $Computed $unit" 

            vmCreateMetricAlert $rg `
                "CONTURSA-Azure-$shortKey-$($_.name)" `
                $AvailAlertCriteria `
                $CPUAlertWSize `
                $CPUAlertFrequency `
                $_.location `
                $actGroup `
                $_.id `
                $description
        
        }
    }
}

# 4. Show the created resources
Write-Host  "`nAll went correctly`n" -ForegroundColor Green
$alerts = Get-AzMetricAlertRuleV2 | Where-Object { $_.Name.StartsWith("Alert")}
foreach ($alert in $alerts ) {
    Write-Host $alert.Name `n

}
Write-Host $alerts.

# TODO indicar las nuevas alertas solo (count, vm, st, etc, etc)