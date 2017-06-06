Import-Module "$PSScriptRoot\..\ADFSProviderPublisher\ADFSProviderPublisher.psm1"

try{
	# To turn on Verbose or Debug outputs, change the corresponding preference to "Continue" ("SilentlyContinue")
    $WarningPreference = "Continue"
    $VerbosePreference = "Continue"
    $DebugPreference = "Continue"


	# change these values to suit your needs
	$adfsServer = 'servername.domain.com'
	$providerName = 'DEMO'
	$folderName = 'company\demo'
	$fileName = 'DemoAuthenticationProvider.dll'
	$builtAssemblyPath = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\bin\DemoAuthenticationProvider.dll")

	if(!(Test-Path $builtAssemblyPath)){
		"DemoAuthenticationProvider.dll not found. Try building the project first. Searched for {0}" -f $builtAssemblyPath | Write-Error
		return
	}

	$fullname = ([system.reflection.assembly]::loadfile($builtAssemblyPath)).FullName
	$fullTypeName = "DemoAuthenticationProvider.DemoAdapter, " + $fullname

	$cred = Get-Credential
	$sourcePath = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\bin\")
	$assemblies =  Get-ChildItem "$sourcePath\" -Include *.dll -Recurse | Select-Object -ExpandProperty Name

	$adfsProviderParams = @{
		FullTypeName = $fullTypeName
		ProviderName = $providerName
		FolderName = $folderName
		FileName = $fileName
		ComputerName = $adfsServer
		Credential = $cred
		SourcePath = $sourcePath
		Assemblies = $assemblies
	}

	"Uninstalling {0} on {1}" -f $providerName,$adfsServer | Write-Verbose
	Remove-AuthProvider @adfsProviderParams

	"Copying locally built {0} artifacts to {1}" -f $providerName,$adfsServer | Write-Verbose
	Copy-AuthProvider @adfsProviderParams

	"Installing {0} on {1}" -f $providerName,$adfsServer | Write-Verbose
	Install-AuthProvider @adfsProviderParams

	"Finished publishing {0} to {1}" -f $providerName,$adfsServer | Write-Verbose
}catch {
	"An error occurred while publishing {0}. `n{1}` " -f $providerName,$_.Exception.Message | Write-Error
}




