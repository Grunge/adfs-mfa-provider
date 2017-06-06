function Copy-AuthProvider{
	<#
		.SYNOPSIS
		Copies new custom provider build artifacts to ADFS server
	#>
	[Cmdletbinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[string]$FullTypeName,

		[Parameter(Position=1, Mandatory=$true)]
		[string]$ProviderName,
		
		[Parameter(Position=2, Mandatory=$true)]
		[string]$FolderName,
		
		[Parameter(Position=3, Mandatory=$true)]
		[string]$FileName,

		[Parameter(Position=4, Mandatory=$true)]
		[string[]]$Assemblies,

		[Parameter(Position=5, Mandatory=$true)]
		[string]$SourcePath,

		[Parameter(Position=6)]
		[string]$ComputerName,

		[Parameter(Position=7)]
		[pscredential]$Credential = $null
	)


	$networkCred = $Credential.GetNetworkCredential()
	$networkUser = "{0}\{1}" -f $networkCred.Domain, $networkCred.UserName
	$netServerPath = "\\{0}\C$" -f $ComputerName

	try{
		net.exe use $netServerPath $networkCred.Password /user:$networkUser > $null

		$destPath = "\\{0}\C$\{1}" -f $ComputerName,$FolderName
		$robocopyReturnValue = robocopy.exe /r:1 $SourcePath $destPath /E > $null

		$errors = $robocopyReturnValue -like '*error*'
		if($errors.Length -gt 0){
			Write-Error $errors[0]
		}
	}catch {
		Write-Error $_.Exception.Message
	}

	try{
		net.exe use * /d /y > $null
	}catch {}
}