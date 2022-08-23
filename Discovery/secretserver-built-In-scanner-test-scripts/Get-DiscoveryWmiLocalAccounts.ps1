﻿Function Get-DiscoveryWmiLocalAccounts{

    [cmdletbinding()]

    param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$MachineName,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Domain,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$User,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Pwd
    )

    $domuser="$Domain\$User"
    $namespace = "root\cimv2"
    $timeout=5
    [string[]] $wmiProps = "caption", "name", "disabled"

    $remote = $MachineName -notmatch $Env:COMPUTERNAME

        $ConnectionOptions = new-object System.Management.ConnectionOptions
            if ($remote) 
            {
            $ConnectionOptions.Username = $domuser
            $ConnectionOptions.Password = $Pwd
            }
    	    $ConnectionOptions.Impersonation = "Impersonate"
            $ConnectionOptions.Authentication = "Default"
            $ConnectionOptions.EnablePrivileges = $TRUE
        #$connectionoptions

        $EnumerationOptions = new-object System.Management.EnumerationOptions 
    
        $timeoutseconds = new-timespan -seconds $timeout
        $EnumerationOptions.set_timeout($timeoutseconds) 
    
        $assembledpath = "\\" + $MachineName + "\" + $namespace
    
        $Scope = new-object System.Management.ManagementScope $assembledpath, $ConnectionOptions
        $Scope.Connect() 
        
        if (!$remote) 
            {
            Write-Host ("Local machine WMI running as user: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -ForegroundColor Magenta
            }
    try {    
        $wmiQuery = new-object -TypeName System.Management.SelectQuery -ArgumentList "Win32_UserAccount", "LocalAccount = 'True'", $wmiProps   
        $searcher = new-object System.Management.ManagementObjectSearcher
        $searcher.set_options($EnumerationOptions)
        $searcher.Query = $wmiQuery
        $searcher.Scope = $Scope 
        #return $searcher.get() 

            if ($searcher.Get().Count -ne 0)
            {foreach ($managementObject in $searcher.Get())
                { 
                 if ($managementObject["name"] -ne $null) 
                    {
                        $Caption = $managementObject["caption"].ToString()
                        #$AccountName = $managementObject["name"].ToString()
                        $IsDisabled = $managementObject["disabled"].ToString()
                    }
        
                    Write-Log ("Account: {0}     IsDisabled?: {1}" -f $Caption, $IsDisabled)
                    }
            }                 
            else 
			{
                Write-Host "No local user accounts found" -ForegroundColor Magenta
                Write-Log "No local user accounts found"
            }
        }
    catch [exception] {
        Write-Host ("Unexpected exception occurred: {0}" -f $_.Exception)
    }

}

function Write-Log 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message, 

       [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path=[io.path]::combine($scriptRootFolder, "c:\Logs\$($startTime)\$($computername).log"),
         
		[Parameter(Mandatory=$false)]
		[ValidateSet("Error","Warn","Info")]
		[string]$Level="Info"
    ) 

   Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        
		# If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
		if (!(Test-Path $Path)) {
			Write-Verbose "Creating $Path."
			$NewLogFile = New-Item $Path -Force -ItemType File
		}


       # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

		# Write message to error, warning, or verbose pipeline and specify $LevelText
		switch ($Level) {
			'Error' {
				Write-Error $Message
				$LevelText = 'ERROR:'
				}
			'Warn' {
				Write-Warning $Message
				$LevelText = 'WARNING:'
				}
			'Info' {
				Write-Verbose $Message
				$LevelText = 'INFO:'
				}
			}
		
		# Write log entry to $Path
		"$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
  } 

$remote=$true
$machinename="baraka"
$domain="testlab.com"
$username="Administrator"
$varstr = read-host -assecurestring -prompt "Enter your password (the input is masked)"
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($varstr)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr)

Get-DiscoveryWmiLocalAccounts $machinename $domain $username $password