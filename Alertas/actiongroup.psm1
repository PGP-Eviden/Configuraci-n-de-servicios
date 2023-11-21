$emailReceivers = @()

function GenerateEmailReceiver {
    param ( $emailrec )

    $name = $emailrec[0]; $email = $emailrec[1]

    return New-AzActionGroupReceiver -Name $name -EmailAddress $email
}

function CreateReceivers {
    param ( [string]$EmailFile)
    Get-Content -Path $EmailFile | ForEach-Object { $emailReceivers += (GenerateEmailReceiver $_.Split(",")) }
    return $emailReceivers
}

function CreateActionGroup {
    param ([string]$rg, [string]$EmailFile)

    $receivers = CreateReceivers $EmailFile
    Write-Host $receivers

    # TODO Actualizar -Name y ShortName
    $actionGroup = Set-AzActionGroup `
        -Name "AG-Contursa01" `
        -ShortName "AG-Con01" `
        -ResourceGroupName $rg `
        -Receiver $receivers

    return $actionGroup
}