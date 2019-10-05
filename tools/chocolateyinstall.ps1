$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = 'https://www.matstroeng.se/quickroute/download/QuickRoute_2.4_Setup.msi'
$version = '2.4'

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'MSI'
  url            = $url
  softwareName   = 'quickroute*'
  checksum       = '64E73D9090C0AC1C9236199ABC8B8D48689CCB0042C5C3CDBD0C1C3B81B2DC3D'
  checksumType   = 'sha256'
  silentArgs     = "/qn /norestart ALLUSERS=1 /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`""
  validExitCodes = @(0, 3010, 1641)
}

function Set-QuickRouteVersion {
  Param (
    [String]$Version
  )
  $pathRegistryX86 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BDF3D53A-78E0-416D-B03E-A360355FDD6D}'
  $pathRegistryX64 = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{BDF3D53A-78E0-416D-B03E-A360355FDD6D}'

  if (Get-OSArchitectureWidth -Compare 64) {
    if (Test-Path $pathRegistryX64) {
      Set-ItemProperty -Path $pathRegistryX64 -Name "DisplayVersion" -Value $Version
      Write-Output "Quickroute $Version has been installed and the wrong version has been fixed"
    } else {
      Write-Warning "Quickroute $Version has been installed but the wrong version could not be fixed"
    }
  } else {
    if (Test-Path $pathRegistryX86) {
      Set-ItemProperty -Path $pathRegistryX86 -Name "DisplayVersion" -Value $Version
      Write-Output "Quickroute $Version has been installed and the wrong version has been fixed"
    } else {
      Write-Warning "Quickroute $Version has been installed but the wrong version could not be fixed"
    }
  }
}

#Uninstalls the previous version of QuickRoute if either version exists
Write-Output "Searching if the previous version exists..."
$InstallerVersion = $version.Replace('.', '')
[array]$checkreg = Get-UninstallRegistryKey -SoftwareName $packageArgs['softwareName']

if ($checkreg.Count -eq 0) {
  Write-Output 'No installed old version. Process to install QuickRoute.'
  # No version installed, process to install
  Install-ChocolateyPackage @packageArgs
  Set-QuickRouteVersion -Version $version
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
        Set-QuickRouteVersion -Version $version
      } elseif (($_.DisplayVersion.Replace('.', '') -eq $InstallerVersion) -and ($env:ChocolateyForce)) {
        # Force install
        Write-Output "QuickRoute $version already installed, but --force option is passed, download and install"
        Install-ChocolateyPackage @packageArgs
        Set-QuickRouteVersion -Version $version
      }
    }
  }
}
