#############
# Constants
#############
$packageOutputDir = '<FULL PATH TO LOCATION WHERE PACKAGES ARE EXPORTED - CAN BE ANY FOLDER>'
$functionsHostRoot = '<FULL PATH TO azure-functions-host CLONED REPO>'
$webJobsVersion =  "<ANY SEMVER NOT MATHING RELEASED VERSIONS e.g. 999.0.0>"
$webJobsRoot = '<FULL PATH TO azure-webjobs-sdk CLONED REPO>'
$functionAppRoot = '<FULL PATH OF FUNCTION APP>'
# Set to the extension you are debugging
# Supported sptions: SERVICE_BUS, EVENT_HUB
Enum Extensions 
{
  ServiceBus = 0
  EventHub = 1
}
$extension = [Extensions]::EventHub;

####################
# Dynamic settings
####################
$scriptRoot = Get-Location
# Universal package suffix unique to each run of this script to ensure packages built here are pulled into each project
$packageVerSuffix = "-dev" + [datetime]::UtcNow.Ticks.ToString()
$webJobsPackageVersion= $webJobsVersion + $packageVerSuffix

Write-Host "Using package suffix: $packageVerSuffix"
Write-Host "WebJobs SDK package version: $webJobsPackageVersion"

Push-Location

####################
# WebJobs SDK: Pack
####################
Write-Host "`n============================================"
Write-Host "===== Building and packing WebJobs SDK ====="
Write-Host "============================================"

Write-Host "`n===== Clearing out $packageOutputDir ====="
Remove-Item "$packageOutputDir\*.nupkg"

Set-Location $webJobsRoot

## Uncomment only the projects that need to be stepped through in Visual Studio
$webJobsProjects = 
  "src\Microsoft.Azure.WebJobs\WebJobs.csproj",
  "src\Microsoft.Azure.WebJobs.Host\WebJobs.Host.csproj",
  "src\Microsoft.Azure.WebJobs.Host\WebJobs.Host.Sources.csproj",
  "src\Microsoft.Azure.WebJobs.Logging\WebJobs.Logging.csproj",
  "src\Microsoft.Azure.WebJobs.Logging.ApplicationInsights\WebJobs.Logging.ApplicationInsights.csproj",
  "src\Microsoft.Azure.WebJobs.Extensions.Storage\WebJobs.Extensions.Storage.csproj",
  "src\Microsoft.Azure.WebJobs.Host.Storage\WebJobs.Host.Storage.csproj",
  "test\Microsoft.Azure.WebJobs.Host.TestCommon\WebJobs.Host.TestCommon.csproj";

foreach ($project in $webJobsProjects)
{
  Write-Host "`n===== Packing $project ====="
  #dotnet pack $project --output $packageOutputDir --version-suffix $packageVerSuffix --verbosity q 
  dotnet pack $project --output $packageOutputDir -p:PackageVersion=$webJobsPackageVersion --verbosity q 
  if (-not $?) 
  { Write-Host "Faild to pack WebJobs. Exiting."; Pop-Location; exit 1; }
}

####################
# WebJobs Extension
####################
Switch ($extension)
{
  ServiceBus
  {
    . $scriptRoot/FunctionsDebuggingBuildServiceBus.ps1
  }
  EventHub
  {
    . $scriptRoot/FunctionsDebuggingBuildEventHubs.ps1
  }
}
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to load script for extension. Exiting."; Pop-Location; exit 1; }

###########################################################
# Functions Host: Add WebJobs SDK and Extension dependency
###########################################################
Write-Host "`n`n===================================================="
Write-Host "===== Adding custom packages to Functions Host ====="
Write-Host "===================================================="

Set-Location $functionsHostRoot
$functionHostProjects = 
  "src\WebJobs.Script\WebJobs.Script.csproj",
  "src\WebJobs.Script.WebHost\WebJobs.Script.WebHost.csproj",
  "src\WebJobs.Script.Grpc\WebJobs.Script.Grpc.csproj"
  #"test\WebJobsStartupTests\WebJobsStartupTests.csproj"
  #"test\WebJobs.Script.Tests.Integration\WebJobs.Script.Tests.Integration.csproj"

foreach ($project in $functionHostProjects)
{
  Write-Host "`n===== Adding Microsoft.Azure.WebJobs.$webJobsPackageVersion to $project from $packageOutputDir ====="
  dotnet add $project package Microsoft.Azure.Webjobs -v $webJobsPackageVersion --source $packageOutputDir --no-restore
  if (-not $? -or $LastExitCode -ne 0)
  { Write-Host "Faild to add custom WebJobs package for $project. Exiting."; Pop-Location; exit 1; }
  
  Switch ($extension)
  {
    ServiceBus
    {
      Write-Host "`n===== Adding Microsoft.Azure.WebJobs.Extensions.ServiceBus.$extensionPackageVersion to $project from $packageOutputDir ====="
      dotnet add $project package Microsoft.Azure.WebJobs.Extensions.ServiceBus -v $extensionPackageVersion --source $packageOutputDir --no-restore
      if (-not $? -or $LastExitCode -ne 0)
      { Write-Host "Faild to add custom Service Bus Extension package for $project. Exiting."; Pop-Location; exit 1; }
    }
    EventHub
    {
      Write-Host "`n===== Adding Microsoft.Azure.WebJobs.Extensions.EventHubs.$extensionPackageVersion to $project from $packageOutputDir ====="
      dotnet add $project package Microsoft.Azure.WebJobs.Extensions.EventHubs -v $extensionPackageVersion --source $packageOutputDir --no-restore
      if (-not $? -or $LastExitCode -ne 0)
      { Write-Host "Faild to add custom Event Hub Extension package for $project. Exiting."; Pop-Location; exit 1; }
    }
  }
}

foreach ($project in $functionHostProjects)
{
  Write-Host "`n===== Building $project ====="
  dotnet restore $project --source $packageOutputDir
  if (-not $? -or $LastExitCode -ne 0)
  { Write-Host "Faild to restore $project. Exiting."; Pop-Location; exit 1; }
  dotnet build $project --source $packageOutputDir 
  if (-not $? -or $LastExitCode -ne 0)
  { Write-Host "Faild to build $project. Exiting."; Pop-Location; exit 1; }
  #Write-Host "`n===== Packing $project ====="
  #dotnet pack $project --output $packageOutputDir -p:PackageVersion=$functionsHostVersion --verbosity q 
  #if (-not $?) 
  #{ Write-Host "Faild to pack WebJobs. Exiting."; Pop-Location; exit 1; }
}

############################################################
# Functions App: Add WebJobs and Ext package dependency
############################################################
Write-Host "`n`n==========================================================="
Write-Host "===== Adding custom packages to Function App project ====="
Write-Host "==========================================================="
Set-Location $functionAppRoot

Write-Host "`n===== Adding Microsoft.Azure.WebJobs package from $packageOutputDir ====="
dotnet add package Microsoft.Azure.WebJobs -v $webJobsPackageVersion --source $packageOutputDir --no-restore 
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to add custom WebJobs package for Function project. Exiting."; Pop-Location; exit 1; }

Switch ($extension)
{
  ServiceBus
  {
    Write-Host "`n===== Adding Microsoft.Azure.WebJobs.Extensions.ServiceBus package from $packageOutputDir ====="
    dotnet add package Microsoft.Azure.WebJobs.Extensions.ServiceBus -v $extensionPackageVersion --source $packageOutputDir --no-restore
    if (-not $? -or $LastExitCode -ne 0)
    { Write-Host "Faild to add custom Service Bus extension package for Function project. Exiting."; Pop-Location; exit 1; }
  }
  EventHub
  {
    Write-Host "`n===== Adding Microsoft.Azure.WebJobs.Extensions.EventHubs package from $packageOutputDir ====="
    dotnet add package Microsoft.Azure.WebJobs.Extensions.EventHubs -v $extensionPackageVersion --source $packageOutputDir --no-restore
    if (-not $? -or $LastExitCode -ne 0)
    { Write-Host "Faild to add custom Event Hub extension package for Function project. Exiting."; Pop-Location; exit 1; }
  }
}

Write-Host "`n===== Building project ====="
dotnet restore --source $packageOutputDir
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to restore functions code. Exiting."; Pop-Location; exit 1; }
dotnet build --source $packageOutputDir 
if (-not $? -or $LastExitCode -ne 0)
{ Write-Host "Faild to build functions code. Exiting."; Pop-Location; exit 1; }

Pop-Location