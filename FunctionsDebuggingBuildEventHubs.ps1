#############
# Constants
#############
$extensionVersion = "<ANY SEMVER NOT MATHING RELEASED VERSIONS e.g. 999.0.0>"
$extensionRoot = '<FULL PATH TO azure-functions-eventhubs-extension\src\Microsoft.Azure.WebJobs.Extensions.EventHubs>'
$extensionTestsRoot = '<FULL PATH TO \azure-functions-eventhubs-extension\test\Microsoft.Azure.WebJobs.Extensions.EventHubs.Tests>'
# Set if using a custom package
$useCustomPackage = $false
#$previewPackageVersion = "5.0.0"
#$previewPackageDir = 'C:\Users\sidkri\source\previewPackages'

####################
# Dynamic settings
####################
$extensionPackageVersion = $extensionVersion + $packageVerSuffix

Write-Host "Event Hubs Ext package version: $extensionPackageVersion"

##########################################
# Build and pack
##########################################
Write-Host "`n======================================================"
Write-Host "===== Building and packing Event Hubs Extension ====="
Write-Host "======================================================"
Set-Location $extensionRoot

# Add custom Webjobs package
Write-Host "`n===== Adding Microsoft.Azure.WebJobs.$webJobsPackageVersion package from $packageOutputDir ====="
dotnet add package Microsoft.Azure.WebJobs -v $webJobsPackageVersion --source $packageOutputDir --no-restore
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to add custom WebJobs package . Exiting."; Pop-Location; exit 1; }

Write-Host "===== Adding Microsoft.Azure.WebJobs.Sources.$webJobsPackageVersion package from $packageOutputDir ====="
dotnet add package Microsoft.Azure.WebJobs.Sources -v $webJobsPackageVersion --source $packageOutputDir --no-restore
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to add custom WebJobs Soruces package. Exiting."; Pop-Location; exit 1; }

# Add custom Event Hubs SDK package (if using a custom package)
if ($useCustomPackage)
{
    Write-Host "`n===== Adding Microsoft.Azure.EventHubs.Processor package from $previewPackageDir ====="
    dotnet add package Microsoft.Azure.EventHubs.Processor -v $previewPackageVersion -s $previewPackageDir 
    if (-not $? -or $LastExitCode -ne 0)
    { Write-Host "Faild to add custom Event Hubs package. Exiting."; Pop-Location; exit 1; }
}

Write-Host "`n===== Buiding project ====="
dotnet restore --source $packageOutputDir
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to restore Event Hubs Ext. Exiting."; Pop-Location; exit 1; }
dotnet build --source $packageOutputDir
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to build Event Hubs Ext. Exiting."; Pop-Location; exit 1; }

Write-Host "===== Packing project ====="
dotnet pack WebJobs.Extensions.EventHubs.csproj -p:PackageVersion=$extensionPackageVersion --output $packageOutputDir --version-suffix $packageVerSuffix 
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to pack Event Hubs Ext. Exiting."; Pop-Location; exit 1; }

Write-Host "`n`n============================================================"
Write-Host "===== Building and packing Event Hubs Extension Tests ====="
Write-Host "============================================================"
Set-Location $extensionTestsRoot

# Add custom Webjobs package
Write-Host "===== Adding Microsoft.Azure.WebJobs.Host.TestCommon.$webJobsPackageVersion package from $packageOutputDir ====="
dotnet add package Microsoft.Azure.WebJobs.Host.TestCommon -v $webJobsPackageVersion --source $packageOutputDir --no-restore
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to add custom WebJobs Soruces package. Exiting."; Pop-Location; exit 1; }

# Add custom EventHubs SDK package (if using a custom package)
if ($useCustomPackage)
{
    Write-Host "`n===== Adding Microsoft.Azure.EventHubs.Processor package from $previewPackageDir ====="
    dotnet add package Microsoft.Azure.EventHubs.Processor -v $previewPackageVersion -s $previewPackageDir 
    if (-not $? -or $LastExitCode -ne 0)
    { Write-Host "Faild to add custom Event Hubs package. Exiting."; Pop-Location; exit 1; }
}

Write-Host "`n===== Buiding project ====="
dotnet restore --source $packageOutputDir
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to restore Event Hubs Ext. Exiting."; Pop-Location; exit 1; }
dotnet build --source $packageOutputDir
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to build Event Hubs Ext. Exiting."; Pop-Location; exit 1; }
