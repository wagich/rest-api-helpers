param (
	[Parameter(Mandatory=$true)]
	[ValidatePattern("^\d+\.\d+\.(?:\d+\.\d+$|\d+$)")]
	[string]
	$ReleaseVersionNumber,
	[Parameter(Mandatory=$true)]
	[string]
	[AllowEmptyString()]
	$PreReleaseName
)

Write-Output "Dotnet CLI version:"
& dotnet --version
Write-Output ""

$PSScriptFilePath = (Get-Item $MyInvocation.MyCommand.Path).FullName

" PSScriptFilePath = $PSScriptFilePath"

$SolutionRoot = Split-Path -Path $PSScriptFilePath -Parent

$DOTNET = "dotnet"

# Make sure we don't have a release folder for this version already
$BuildFolder = Join-Path -Path $SolutionRoot -ChildPath "build";
$ReleaseFolder = Join-Path -Path $BuildFolder -ChildPath "Releases\v$ReleaseVersionNumber$PreReleaseName";
if ((Get-Item $ReleaseFolder -ErrorAction SilentlyContinue) -ne $null)
{
	Write-Warning "$ReleaseFolder already exists on your local machine. It will now be deleted."
	Remove-Item $ReleaseFolder -Recurse
}

$ProjectJsonPath = Join-Path -Path $SolutionRoot -ChildPath "src\RestApiHelpers\project.json"

# Set the version number in package.json
#(gc -Path $ProjectJsonPath) `
#	-replace "(?<=`"version`":\s`")[.\w-]*(?=`",)", "$ReleaseVersionNumber$PreReleaseName" |
#	sc -Path $ProjectJsonPath -Encoding UTF8
# Set the copyright
# $DateYear = (Get-Date).year
# (gc -Path $ProjectJsonPath) `
# -replace "(?<=`"copyright`":\s`")[\w\s�]*(?=`",)", "Copyright � Mark Vincze $DateYear" |
# sc -Path $ProjectJsonPath -Encoding UTF8

# Build the proj in release mode

& $DOTNET restore "$ProjectJsonPath"
if (-not $?)
{
	throw "The dotnet restore process returned an error code."
}

& $DOTNET build "$ProjectJsonPath"
if (-not $?)
{
	throw "The dotnet build process returned an error code."
}

& $DOTNET pack "$ProjectJsonPath" --configuration Release --output "$ReleaseFolder"
if (-not $?)
{
	throw "The dotnet pack process returned an error code."
}
