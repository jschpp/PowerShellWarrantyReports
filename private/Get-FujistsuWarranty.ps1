function get-FujitsuWarranty ([Parameter(Mandatory = $true)]$SourceDevice, $Client) {
    $Req = Invoke-WebRequest "https://support.ts.fujitsu.com/Adler/Default.aspx?Lng=de&GotoDiv=Warranty/WarrantyStatus&DivID=indexwarranty&GotoUrl=IndexWarranty&Ident=$SourceDevice"
    $names = @(
        "AdlerResult"
        "Ident",
        "Product",
        "Firstuse",
        "WarrantyEndDate",
        "WCodeDesc"
    )
    $FujitsuDeviceWarrentyInfos = $Req.InputFields | Where-Object { $_.name -in $names } | ForEach-Object {@{$_.Name=$_.Value}}
    if ($FujitsuDeviceWarrentyInfos -and $FujitsuDeviceWarrentyInfos.AdlerResult -eq "OK") {
        $EndDate = [DateTime]::Parse($FujitsuDeviceWarrentyInfos.WarrantyEndDate)
        $WarrantyState = if ($EndDate -gt (Get-Date).Date) {"OK"} else {"Expired"}
        $FormattedProductInfo = @($FujitsuDeviceWarrentyInfos.Product)
        $FormattedProductInfo += $FujitsuDeviceWarrentyInfos.WCodeDesc.Split(",") | ForEach-Object {
            $_.trim()
        }
        $FormattedProductInfo = $FormattedProductInfo -join "`n"
        $WarObj = [PSCustomObject]@{
            'Serial'                = $SourceDevice
            'Warranty Product name' = $FormattedProductInfo
            'StartDate'             = [DateTime]::Parse($FujitsuDeviceWarrentyInfos.Firstuse)
            'EndDate'               = $EndDate
            'Warranty Status'       = $WarrantyState
            'Client'                = $Client
        }
    }
    else {
        $WarObj = [PSCustomObject]@{
            'Serial'                = $SourceDevice
            'Warranty Product name' = 'Could not get warranty information'
            'StartDate'             = $null
            'EndDate'               = $null
            'Warranty Status'       = 'Could not get warranty information'
            'Client'                = $Client
        }
    }
    return $WarObj
}