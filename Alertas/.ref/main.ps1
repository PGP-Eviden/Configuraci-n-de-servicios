param (
    # Flag representing all alerts
    [Parameter(Mandatory, Position = 0, HelpMessage = "Path to file containing desired emails (name,email-address):")]
    [string]$EmailFile,

    [Parameter(Mandatory, HelpMessage = "The ResourceGroup where the resources to monitor are located")]
    [string]$rg,

    [Parameter(HelpMessage = "The Subscription name where the resources to monitor are located")]
    [string]$subscription,

    [Parameter(HelpMessage = "Creates only alerts for Storage Account")]
    [switch]$st,

    [Parameter(HelpMessage = "Creates only alerts for Virtual Machines")]
    [switch]$vm
)

if (!$st -and !$vm) {
    Write-Error "
Es necesario seleccionar el alcance de las alertas deseadas.
    -vm => crea alertas en Máquinas virtuales.
    -st => crea alertas en cuentas de almacenamiento.
   
     "
}
if ($st) {
    Write-Host "storage account"
    if ($subscription.Length -gt 0) {
        & $PSScriptRoot\stacc.ps1 .\emails.txt -rg $rg -subscription $subscription
    }
    & $PSScriptRoot\stacc.ps1 .\emails.txt -rg $rg
}
if ($vm) {
    Write-Host "VM"
    if ($subscription.Length -gt 0) {
        & $PSScriptRoot\vm.ps1 .\emails.txt -rg $rg -subscription $subscription
    }
    & $PSScriptRoot\vm.ps1 .\emails.txt -rg $rg
}

