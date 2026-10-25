param(
    [ValidateSet('inspect', 'submit')][string]$Mode = 'inspect',
    [string]$PackagePath = 'store-package/Rytmica.msix'
)
$ErrorActionPreference = 'Stop'
$productId = '9N7HMK8TN36X'
$expectedIdentity = 'ryuya.Rytmica'
$expectedPublisher = 'CN=2492F63A-A943-4F47-BCBE-6BCFF558B3D9'
$versionMatch = [regex]::Match((Get-Content -Raw pubspec.yaml), '(?m)^version:\s*(\d+\.\d+\.\d+)\+\d+\s*$')
if (!$versionMatch.Success) { throw 'Missing pubspec version' }
$expectedVersion = [version]($versionMatch.Groups[1].Value + '.0')
$reportDirectory = New-Item -ItemType Directory -Force store-status
function Save-Report($Name, $Value) {
    $json = $Value | ConvertTo-Json -Depth 30
    $json | Set-Content -LiteralPath (Join-Path $reportDirectory "$Name.json") -Encoding utf8
    Write-Host $json
}
foreach ($name in @('AZURE_AD_TENANT_ID', 'AZURE_AD_APPLICATION_CLIENT_ID', 'AZURE_AD_APPLICATION_SECRET', 'SELLER_ID')) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) { throw "Missing $name" }
}
$token = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$env:AZURE_AD_TENANT_ID/oauth2/token" -Body @{
    grant_type = 'client_credentials'
    client_id = $env:AZURE_AD_APPLICATION_CLIENT_ID
    client_secret = $env:AZURE_AD_APPLICATION_SECRET
    resource = 'https://manage.devcenter.microsoft.com'
}
$headers = @{ Authorization = "Bearer $($token.access_token)" }
$apiRoot = "https://manage.devcenter.microsoft.com/v1.0/my/applications/$productId"
function Get-App { Invoke-RestMethod -Headers $headers -Uri $apiRoot }
function Get-Submission($Id) { Invoke-RestMethod -Headers $headers -Uri "$apiRoot/submissions/$Id" }
function Submission-Summary($Submission) {
    if ($null -eq $Submission) { return $null }
    return @{
        id = $Submission.id; status = $Submission.status
        targetPublishMode = $Submission.targetPublishMode
        priceId = $Submission.pricing.priceId
        locales = @($Submission.listings.PSObject.Properties.Name)
        packages = @($Submission.applicationPackages | ForEach-Object {
            @{ version = $_.version; architecture = $_.architecture; fileName = $_.fileName; fileStatus = $_.fileStatus }
        })
        errors = $Submission.statusDetails.errors
        warnings = $Submission.statusDetails.warnings
    }
}
$app = Get-App
if ($app.id -ne $productId -or $app.packageIdentityName -ne $expectedIdentity -or $app.publisherName -ne $expectedPublisher) {
    throw 'Partner Center application identity does not match Rytmica'
}
$published = if ($app.lastPublishedApplicationSubmission.id) { Get-Submission $app.lastPublishedApplicationSubmission.id } else { $null }
$pending = if ($app.pendingApplicationSubmission.id) { Get-Submission $app.pendingApplicationSubmission.id } else { $null }
Save-Report before @{
    productId = $app.id; name = $app.primaryName; expectedVersion = "$expectedVersion"
    published = (Submission-Summary $published); pending = (Submission-Summary $pending)
}
if ($Mode -eq 'inspect') { exit 0 }
if (!$published) { throw 'First publication must be completed in Partner Center' }
if ($pending) { throw 'An existing submission is pending; inspect it before changing anything' }
if ($published.pricing.priceId -ne 'Free') { throw 'Unexpected price configuration; refusing to change it' }
foreach ($package in $published.applicationPackages) {
    if ($package.architecture -eq 'x64' -and [version]$package.version -ge $expectedVersion) {
        throw "Published x64 package $($package.version) is already at or above $expectedVersion"
    }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $PackagePath))
try {
    $entry = $archive.GetEntry('AppxManifest.xml')
    if (!$entry) { throw 'MSIX manifest missing' }
    $reader = [System.IO.StreamReader]::new($entry.Open())
    try { [xml]$manifest = $reader.ReadToEnd() } finally { $reader.Dispose() }
    $identity = $manifest.Package.Identity
    if ($identity.Name -ne $expectedIdentity -or $identity.Publisher -ne $expectedPublisher -or
        $identity.ProcessorArchitecture -ne 'x64' -or [version]$identity.Version -ne $expectedVersion) {
        throw 'MSIX identity, publisher, architecture or version is incorrect'
    }
    if (!$archive.GetEntry('Rytmica.exe') -or !$archive.GetEntry('flutter_windows.dll')) { throw 'MSIX application payload missing' }
} finally { $archive.Dispose() }
$packageHash = (Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash
& msstore reconfigure --tenantId $env:AZURE_AD_TENANT_ID --sellerId $env:SELLER_ID --clientId $env:AZURE_AD_APPLICATION_CLIENT_ID --clientSecret $env:AZURE_AD_APPLICATION_SECRET
if ($LASTEXITCODE -ne 0) { throw 'Store CLI authentication failed' }
if ((Get-App).pendingApplicationSubmission.id) { throw 'A new pending submission appeared; refusing to replace it' }
& msstore publish $PackagePath -id $productId --noCommit
if ($LASTEXITCODE -ne 0) { throw 'Package staging failed; inspect Partner Center before retrying' }
$stagedApp = Get-App
$submissionId = $stagedApp.pendingApplicationSubmission.id
if (!$submissionId) { throw 'Staged submission not found' }
$staged = Get-Submission $submissionId
if ($staged.status -ne 'PendingCommit' -or $staged.pricing.priceId -ne 'Free') { throw 'Unexpected staged submission status or price' }
if (!($staged.applicationPackages | Where-Object { $_.fileName -eq 'Rytmica.msix' -and $_.fileStatus -ne 'PendingDelete' })) {
    throw 'Staged package is missing'
}
foreach ($listing in $staged.listings.PSObject.Properties) {
    $listing.Value.baseListing.releaseNotes = if ($listing.Name -like 'ja*') {
        'ウィンドウサイズ変更時の入力・タブ・メトロノーム再生状態の保持を改善しました。狭い画面の単位切替や設定見出しを修正し、Flutterと依存ライブラリを更新しました。'
    } else {
        'Preserve inputs, the selected tab and metronome playback when resizing the window. Improve compact unit controls and settings headings. Update Flutter and dependencies.'
    }
}
$null = Invoke-RestMethod -Method Put -Headers $headers -Uri "$apiRoot/submissions/$submissionId" -ContentType 'application/json' -Body ($staged | ConvertTo-Json -Depth 100 -Compress)
Save-Report staged @{
    submission = (Submission-Summary (Get-Submission $submissionId))
    sha256 = $packageHash; sourceCommit = $env:GITHUB_SHA; packageVersion = "$expectedVersion"
}
$null = Invoke-RestMethod -Method Post -Headers $headers -Uri "$apiRoot/submissions/$submissionId/commit" -ContentType 'application/json' -Body '{}'
$status = Invoke-RestMethod -Headers $headers -Uri "$apiRoot/submissions/$submissionId/status"
Save-Report submitted @{ productId = $productId; submissionId = $submissionId; status = $status; packageVersion = "$expectedVersion"; sha256 = $packageHash; sourceCommit = $env:GITHUB_SHA }
if ($status.status -match 'Failed|Canceled' -or $status.statusDetails.errors.Count -gt 0) { throw 'Store reported a submission error' }
