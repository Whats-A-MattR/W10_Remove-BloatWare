<#SYNPOSIS
Check AppxPackages against a list of keywords known to be bloatware
Stores AppxPackage names in an array

From stored Array, removes AppxPackages and AppxProvisionedPackages
AppxPackages are on the users session
AppxProvisionedPackages are the packages that will install when a user logs into the computer, 
so Remove-AppxPackage on its own is not adequate

#>

<#AUTHOR
Matthew Russell
www.scriptedadventures.net
#>

<#REQUIREMENTS
Run script as Administrator

#>


$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Keywords for locating packages to remove
# Add to this list if something is detected that is not included in this list
# Make sure any additional entries are in the below format. This is necessary as formatting is different between Get-AppxPackage and Get-AppxProvisionedPackage, using widlcards makes it workable.
# "*name*"
$PackagesLookup = @(
    "*PeopleExperienceHost*"
    "*SkypeApp*"
    "*Xbox*"
    "*Microsoft.People*"
    "*HiddenCityMysteryofShadows*"
    "*DisneyMagicKingdoms*"
    "*Minecraft*"
    "*CandyCrush*"
    "*Netflix*"
    "*Microsoft.Office*"
    "*Microsoft.Bing*"
    "*Twitter*"
    "*Facebook*"
)

# Blank array for passing data between functions (AppxPackages that match our keywords)
$script:AppxPackagesFound = @()
# Blank array for passing data between functions (AppxProvisionedPackages that match our keywords)
$script:ProvisionedAppxPackagesFound = @()

# This functions objective is to take the keywords specified above and query against AppxPackages(installed) and AppxProvisionedPackages (list of to-be-installed packages)
function Get-BloatWare {
    # This loop looks up packages that match our keywords. Must be done in a loop as cmdlet has issues parsing wildcards and returning multiple results
    foreach ($AppxPackage in $script:PackagesLookup) {
        $AppxPackage_Digger = Get-AppxPackage | Where {$_.name -like "$AppxPackage"} | Select -ExpandProperty Name
        $script:AppxPackagesFound += $AppxPackage_Digger
    }
    # This loop looks up provisioned packages that match our keywords. Must be done in a loop as cmdlet has issues parsing wildcards and returning multiple results
    foreach ($PAppxPackage in $script:PackagesLookup) {
        $ProvisionedAppxPackage_Digger = Get-AppxProvisionedPackage -Online | where {$_.PackageName -like "$PAppxPackage"} | Select -ExpandProperty PackageName
        $script:ProvisionedAppxPackagesFound += $ProvisionedAppxPackage_Digger
    }
}

# This functions object is to, using the array populated by the Get-BloatWare function, remove found packages
function Assassinate-BloatWare {
    # This loop attempts to Get the AppxPackage and then pipes it to a Remove cmdlet with suppressed confirmation
    foreach ($AppxPackage in $script:AppxPackagesFound) {
        try {
            # Pipes data from array through a Get- to a Remove- with suppressed confirmation
            Get-AppxPackage $AppxPackage | Remove-AppxPackage -Confirm:$false -ErrorAction Stop
            # Write to host a success message
            Write-Host "Removed App Package: $AppxPackage"
        }
        catch {
            # Write to host a failure message, listing package that failed to remove
            Write-Host "Failed to remove App Package: $AppxPackage"
        }
    }

    foreach ($PAppxPackage in $script:ProvisionedAppxPackagesFound) {
        # This loop attempts to use the Remove- cmdlet to remove the package by package name
        try {
            Remove-AppxProvisionedPackage -Online -PackageName "$PAppxPackage" -ErrorAction Stop
            # Write to host a success message
            Write-Host "Removed Provisioned App Package: $PAppxPackage"
        }
        catch {
            # Write to host a failure message, listing package that failed to remove 
            Write-Host "Failed to remove Provisioned App Package: $PAppxPackage"
        }
    }
}

#Logic
Get-Bloatware | Assassinate-BloatWare