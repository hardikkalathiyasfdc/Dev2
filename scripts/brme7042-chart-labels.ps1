# BRME-7042: Enable showChartValues + showChartPercentages + showChartTotal on the 3 breakdown donut charts
$reports = @('00Obc000002Nw5NEAS','00Obc000002Nw5OEAS','00Obc000002Nw5PEAS')
foreach ($id in $reports) {
    $describe = sf api request rest "/services/data/v68.0/analytics/reports/$id/describe" -o dev2Current --method GET 2>$null | Out-String
    $raw = $describe
    $i = $raw.IndexOf('{')
    $json = $raw.Substring($i) | ConvertFrom-Json
    $meta = $json.reportMetadata
    $meta.chart.showChartValues = $true
    $meta.chart.showChartPercentages = $true
    $meta.chart.showChartTotal = $true
    $body = @{ reportMetadata = $meta } | ConvertTo-Json -Depth 100
    $tmp = "$env:TEMP\rpt-$id.json"
    $body | Set-Content $tmp -Encoding UTF8
    $resp = sf api request rest "/services/data/v68.0/analytics/reports/$id" -o dev2Current --method PATCH --body $tmp 2>&1 | Out-String
    Write-Output "$id => $resp"
}
