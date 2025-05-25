$env:Path += ";C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin"
& "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" init
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 