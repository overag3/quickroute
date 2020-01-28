param([string]$IncludeStream, [switch]$Force)

import-module au

$releases = 'https://www.matstroeng.se/quickroute/download'

function global:au_SearchReplace {
   @{
        "tools\chocolateyInstall.ps1" = @{
            "(^[$]url\s*=\s*)('.*')"          = "`$1'$($Latest.URL)'"
            "(^[$]version\s*=\s*)('.*')"      = "`$1'$($Latest.InstallerVersion)'"
            "(^\s*checksum\s*=\s*)('.*')"     = "`$1'$($Latest.Checksum32)'"
            "(^\s*checksumType\s*=\s*)('.*')" = "`$1'$($Latest.ChecksumType32)'"
        }
    }
}

function global:au_BeforeUpdate { Get-RemoteFiles -Purge -NoSuffix }

function global:au_GetLatest {
    $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing
    $regex   = 'download_file\.php\?version\=\d\.\d$'
    $url     = ($download_page.links | ? href -match 'download_file\.php\?version\=\d\.\d$' | Select-Object -First 1 -expand href) -split '/' | Select-Object -Last 1
    $version = Get-Version $url

    return @{
        Version = $version
        InstallerVersion = $version
        URL = "$releases/$url"
    }

}

update -ChecksumFor 32
