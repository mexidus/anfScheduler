<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

param(
    [Parameter(Mandatory = $True)]
    [string]
    $subscriptionId,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,

    [string]
    $resourceGroupLocation,

    #[Parameter(Mandatory = $True)]
    [string]
    $deploymentName,

    [string]
    $templateFilePath = "template.json",

    [string]
    $parametersFilePath = "parameters.json"
)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# auto-generate deployment name to simply deployment for users
$deploymentPrefix = "Scheduler-ANF-Snapshots-v1-"
$deploymentTime = Get-Date -format "yyyyMMddhhmmss"
$deploymentName = $deploymentPrefix + $deploymentTime

# welcome user
Write-Host "Welcome to ANF Snapshot Scheduler!";

# sign in
Write-Host "Logging in...";
Connect-AzAccount;

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
$context = Get-AzSubscription -SubscriptionId $subscriptionId;
Set-AzContext $context

# Register RPs
$resourceProviders = @("microsoft.logic");
if ($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach ($resourceProvider in $resourceProviders) {
        Register-AzResourceProvider -ProviderNamespace $resourceProvider;
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if (!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else {
    Write-Host "Using existing resource group '$resourceGroupName'";
}

#$Objects = az account list-locations | ConvertFrom-Json
#Write-Host "Specify the region you would like to deploy the scheduler within:"
#Write-Host "For your reference, the regions are: '$Objects.name'" -ForegroundColor Green
#Read-Host "deployment_Region"# Start the deployment

Write-Host "Starting deployment...";
if (Test-Path $parametersFilePath) {
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;
}
else {
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath;
}