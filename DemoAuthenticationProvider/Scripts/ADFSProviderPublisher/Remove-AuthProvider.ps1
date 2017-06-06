function Remove-AuthProvider{
	<#
		.SYNOPSIS
		Disables a provider, removes it from ADFS, and deletes its local files
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

	if($Credential -eq $null) { $Credential = Get-Credential }

	Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
		param($providerName,$FolderName,$FileName, $assemblies)

		$WarningPreference = "Continue"
		$ErrorActionPreference = "Continue"

		try{			
		
			"set adfs authentication provider to null" | Write-Verbose
			[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")

			# Disable the provider in ADFS. Attempting to unregister our provider if it is currently enabled will throw an error
			Set-AdfsGlobalAuthenticationPolicy -AdditionalAuthenticationProvider $null

			# unregister provider
			"unregister provider" | Write-Verbose
			UnRegister-AdfsAuthenticationProvider -Name $providerName -confirm:$false

			#remove from GAC
			"unregister provider" | Write-Verbose
			$publish = New-Object System.EnterpriseServices.Internal.Publish
			
			$assemblies |% {
				$path = "C:\{0}\{1}" -f $FolderName, $FileName
				$publish.GacRemove($path)
			} > $null

			"restart service" | Write-Verbose
			Stop-Service -Name adfssrv -Force
			Start-Service -Name adfssrv

			"delete folder" | Write-Verbose
			Remove-Item -Path "C:\$($FolderName)\*" -Recurse -Force > $null
		}catch {
			Write-Error $_.Exception.Message
		}
	} -ArgumentList $ProviderName,$FolderName,$FileName,$Assemblies
}
