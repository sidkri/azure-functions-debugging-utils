#############
# Constants
#############
$extensionVersion = "<ANY SEMVER NOT MATHING RELEASED VERSIONS e.g. 999.0.0>"
$extensionRoot = '<FULL PATH TO  azure-functions-servicebus-extension\src\Microsoft.Azure.WebJobs.Extensions.ServiceBus>'
$extensionTestsRoot = '<FULL PATH TO  azure-functions-servicebus-extension\test\Microsoft.Azure.WebJobs.Extensions.ServiceBus.Tests>'
# Set if using a custom package
$useCustomPackage = $false
#$previewPackageVersion = "5.0.0"
#$previewPackageDir = 'C:\Users\sidkri\source\previewPackages'

####################
# Dynamic settings
####################
$extensionPackageVersion = $extensionVersion + $packageVerSuffix

Write-Host "Service Bus Ext package version: $extensionPackageVersion"

##########################################
# Service Bus Ext: Build and pack
##########################################
Write-Host "`n======================================================"
Write-Host "===== Building and packing Service Bus Extension ====="
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

# Add custom ServiceBus SDK package (if using a custom package)
if ($useCustomPackage)
{
    Write-Host "`n===== Adding Microsoft.Azure.ServiceBus package from $previewPackageDir ====="
    dotnet add package Microsoft.Azure.ServiceBus -v $previewPackageVersion -s $previewPackageDir 
    if (-not $? -or $LastExitCode -ne 0)
    { Write-Host "Faild to add custom ServiceBus package. Exiting."; Pop-Location; exit 1; }
}

Write-Host "`n===== Buiding project ====="
dotnet restore --source $packageOutputDir
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to restore Service Bus Ext. Exiting."; Pop-Location; exit 1; }
dotnet build --source $packageOutputDir
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to build Service Bus Ext. Exiting."; Pop-Location; exit 1; }

Write-Host "===== Packing project ====="
dotnet pack WebJobs.Extensions.ServiceBus.csproj -p:PackageVersion=$extensionPackageVersion --output $packageOutputDir --version-suffix $packageVerSuffix 
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to pack Service Bus Ext. Exiting."; Pop-Location; exit 1; }

Write-Host "`n`n============================================================"
Write-Host "===== Building and packing Service Bus Extension Tests ====="
Write-Host "============================================================"
Set-Location $extensionTestsRoot

# Add custom Webjobs package
Write-Host "===== Adding Microsoft.Azure.WebJobs.Host.TestCommon.$webJobsPackageVersion package from $packageOutputDir ====="
dotnet add package Microsoft.Azure.WebJobs.Host.TestCommon -v $webJobsPackageVersion --source $packageOutputDir --no-restore
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to add custom WebJobs Soruces package. Exiting."; Pop-Location; exit 1; }

# Add custom ServiceBus SDK package (if using a custom package)
if ($useCustomPackage)
{
    Write-Host "`n===== Adding Microsoft.Azure.ServiceBus package from $previewPackageDir ====="
    dotnet add package Microsoft.Azure.ServiceBus -v $previewPackageVersion -s $previewPackageDir 
    if (-not $? -or $LastExitCode -ne 0)
    { Write-Host "Faild to add custom ServiceBus package. Exiting."; Pop-Location; exit 1; }
}

Write-Host "`n===== Buiding project ====="
dotnet restore --source $packageOutputDir
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to restore Service Bus Ext. Exiting."; Pop-Location; exit 1; }
dotnet build --source $packageOutputDir
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to build Service Bus Ext. Exiting."; Pop-Location; exit 1; }
