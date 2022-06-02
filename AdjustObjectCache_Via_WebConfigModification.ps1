<#
.SYNOPSIS
    Adjusts the MaxSize of the ObjectCache for a SharePoint WebApplication via a WebConfigModification. 

    based upon
    http://blog.kuppens-switsers.net/sharepoint/enabling-blob-cache-sharepoint-using-powershell/
    
.DESCRIPTION
    Enables and configures the SharePoint BLOB Cache. 

.NOTES
    File Name: AdjustObjectCacheSize_via_WebConfigModification.ps1
    Author   : Bart Kuppens
    Version  : 2.0

    File Name: AdjustObjectCacheSize_via_WebConfigModification.PS1
    Author   : Rainer Asbach
    Version  : 3.1

.PARAMETER Url
    Specifies the URL of the Web Application for which the ObjectCache MaxSize should be changed. 

.PARAMETER MaxSize
    Specifies the Maximum size of the in Memory ObjectCache. 	 

.EXAMPLE
    PS > .\AdjustObjectCacheSize_via_WebConfigModification.ps1 -Url http://intranet.westeros.local -MaxSize 200

   Description
   -----------
   This script changes the size of the ObjectCache for the http://intranet.westeros.local to 200 MB
  

.ToDo
   Add a parameter that shows the current values

.Versions
   3.1
    Initial implementation based on a previous Script to enable the BlobCache
   
#>
param( 
   [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)] 
   [string]$Url,
   [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=1)] 
   [string]$MaxSize="100",
   [Parameter(Mandatory=$false, ValueFromPipeline=$false)]
   [switch]$Reset
) 
 

# Load the SharePoint PowerShell snapin if needed
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null)
{
   Add-PSSnapin Microsoft.SharePoint.PowerShell
}
 
$webApp = Get-SPWebApplication $Url
$WebConfigModificationOwner="ObjectCacheMod"

if ($Reset)
{
   $MaxSize="100"
}

$MaxSizeInt = $MaxSize -as [int]
if ($MaxSizeInt -ge 1 -and $MaxSizeInt -le 2048)
{


    $modifications = $webApp.WebConfigModifications | ? { $_.Owner -eq $WebConfigModificationOwner }
    if ($modifications.Count -ne $null -and $modifications.Count -gt 0)
    {
        Write-Host -ForegroundColor Yellow "Modifications have already been added!"
        $a= read-Host "Re-Create Entries? (Y/N)"
        if ($a -ne 'y')
        {
            break
        }
        
        for ($i=$modifications.count-1;$i -ge 0;$i--)
        {
            $c = ($webApp.WebConfigModifications | ? {$_.Owner -eq $WebConfigModificationOwner})[$i] 
            $r = $webApp.WebConfigModifications.Remove($c)
        }

        $webApp.update()
        $webApp.Parent.ApplyWebConfigModifications()
    }
 

    # Adjust ObjectCacheSize
    [Microsoft.SharePoint.Administration.SPWebConfigModification] $config1 = New-Object Microsoft.SharePoint.Administration.SPWebConfigModification 
    $config1.Path = "configuration/SharePoint/ObjectCache" 
    $config1.Name = "maxSize"
    $config1.Value = $MaxSize
    $config1.Sequence = 0
    $config1.Owner = $WebConfigModificationOwner 
    $config1.Type = 1 

    #Add mods to webapp and apply to web.config
    $webApp.WebConfigModifications.Add($config1)
    $webApp.update()
    $webApp.Parent.ApplyWebConfigModifications()
} else {
    Write-Host "Valid values for MaxSize are integer numbers between 1 and 2048" -ForegroundColor Red
}