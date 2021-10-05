## Build scripts instructions for end-to-end step-through debugging across Azure Functions

The solution and scripts in this folder enable stepping through code in a debugger across the Functions host, Webjobs SDK and Webjobs extension repositories including a function app

**Steps:**

1. Clone the `azure-functions-host, azure-webjobs-sdk` and any extension you would like to debug (e.g. Service Bus and Event Hubs files are provided here)
1. Place the `FunctionsDebugging.sln` file in the folder containing the above repositories (top level folder).  Replace "sidkri-dev-env" with the path to your own function app.  Alternately you can also create a new solution that includes relevant projects from all the repos you are trying to step-through debug across.  Look through the solution file to determine the .csproj files you need to include.
1. To debug just the functions host with built in extensions (e.g. Timer, HTTP), modify and run the `FunctionsDebuggingBuild.ps1` powershell script.  Set the "Constants" at the top to appropriate folders:
    1. `$packageOutputDir` - this can be any folder where nuget packages are written to and pulled while buiding the various projects in dependency order.
    1. `$functionsHostRoot` - This is the full path where you have cloned the `azure-functions-host` repo
    1. `$webJobsVersion` - This should be set to any semver that does not match a typical release version to avoid conflicts/picking up published versions.
    1. `$webJobsRoot` - The full path where you have cloned the `azure-webjobs-sdk` repo.
    1. `$functionAppRoot` - The root location of the function app you want to debug.
1. To debug with the Event Hubs extension, run the `FunctionsDebuggingBuildEventHubs.ps1` **AFTER** running `FunctionsDebugginBuild.ps1` as the former depends on variables set by the latter.  Follow instructions to update the constants in this script file as well.

Contact @sidkri with any questions.
