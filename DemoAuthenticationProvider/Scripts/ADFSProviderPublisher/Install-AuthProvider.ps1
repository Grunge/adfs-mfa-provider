function Install-AuthProvider{
	<#
		.SYNOPSIS
		Publishes all of a provider's assemblies to the GAC, registers the provider with ADFS, and 
		finally enables the provider.
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
		param($typeName,$providerName,$FolderName,$assemblies)

		$WarningPreference = "Continue"
		$ErrorActionPreference = "Stop"

		Try
		{
			if(!(Test-Path "C:\$($FolderName)")){ New-Item -ItemType Directory -Path "C:\$($FolderName)" > $null}
			Set-location "C:\$($FolderName)"

			[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
			$publish = New-Object System.EnterpriseServices.Internal.Publish

			$assemblies |% {
				$path = "C:\{0}\{1}" -f $FolderName, $_
				$publish.GacInstall($path)
			} > $null

			Register-AdfsAuthenticationProvider -TypeName $typeName -Name $providerName
			Stop-Service -Name adfssrv -Force
			Start-Service -Name adfssrv

			# Restart device recognition service (which was stopped as a dependent service when adfssrv was stopped)
			#Start-Service -Name drs

			# Enable the provider in ADFS - TODO, must run as admin
			Set-AdfsGlobalAuthenticationPolicy -AdditionalAuthenticationProvider $providerName
		}
		Catch
		{
			Write-Error $_.Exception.Message
		}
	} -ArgumentList $FullTypeName,$ProviderName,$FolderName,$Assemblies
}