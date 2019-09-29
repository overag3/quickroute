$ErrorActionPreference = 'Stop'
$url = 'https://www.matstroeng.se/quickroute/download/QuickRoute_2.4_Setup.msi'
$version = '2.4'

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'MSI'
  url            = $url
  softwareName   = 'quickroute*'
  checksum       = '64E73D9090C0AC1C9236199ABC8B8D48689CCB0042C5C3CDBD0C1C3B81B2DC3D'
  checksumType   = 'sha256'
  silentArgs     = "/qn ALLUSERS=1 /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`""
  validExitCodes = @(0, 3010, 1641)
}

#Uninstalls the previous version of QuickRoute if either version exists
Write-Output "Searching if the previous version exists..."
$InstallerVersion = $version.Replace('.', '')
[array]$checkreg = Get-UninstallRegistryKey -SoftwareName $packageArgs['softwareName']

if ($checkreg.Count -eq 0) {
  Write-Output 'No installed old version. Process to install QuickRoute.'
  # No version installed, process to install
  Install-ChocolateyPackage @packageArgs
} elseif ($checkreg.count -ge 1) {
  $checkreg | ForEach-Object {
    if ($null -ne $_.PSChildName) {
      if ($_.DisplayVersion.Replace('.', '') -lt $InstallerVersion) {
        Write-Output "Uninstalling QuickRoute previous version : $($_.DisplayVersion)"
        $msiKey = $_.PSChildName
        Start-ChocolateyProcessAsAdmin "/qn /norestart /X$msiKey" -exeToRun "msiexec.exe" -validExitCodes @(0, 1605, 3010)

        # Process to install
        Write-Output "Installing new version of QuickRoute"
        Install-ChocolateyPackage @packageArgs
      } elseif ($_.DisplayVersion.Replace('.', '') -eq $InstallerVersion) {
        Write-Output "QuickRoute $version already installed, skip download and install"
      }
    }
  }
}