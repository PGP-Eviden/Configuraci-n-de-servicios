param (
    [Parameter(Mandatory, Position = 0, HelpMessage = "Path to file containing desired emails (name,email-address)")]
    [string]$EmailFile,

    [Parameter(Mandatory, HelpMessage = "The ResourceGroup where the action group is created")]
    [string]$rg,

    [Parameter(HelpMessage = "Scope: ResourceGroups")]
    [switch]$resourceGroup,

    [Parameter(HelpMessage = "Scope: Subscription")]
    [switch]$subscription

)

Import-Module -Name .\actiongroup.psm1 -Force
$actionGroup = CreateActionGroup $rg $EmailFile
Write-Host $actionGroup.Id


if ($resourceGroup) {
    & $PSScriptRoot\resourceGroup.ps1 .\emails.txt -rg $rg
    <# Action to perform if the condition is true #>
}
elseif ($subscription) {
    & $PSScriptRoot\subscription.ps1 .\emails.txt -rg $rg
    <# Action when this condition is true #>
}
else {
    Write-Host "Hace falta especificar el Scope: subscription / resouceGroup"
}