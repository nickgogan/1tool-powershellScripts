$stopwatch = [System.Diagnostics.Stopwatch]::new();
$totalDuration = 0;
$destinationBase = "C:\0.Personal\Tech\Projects\Setup\Work Setups\MongoDB\";
$gitDir = "C:\0.Personal\Tech\Projects\Setup\";
Write-Output "";
Write-Output "Destination: $destinationBase";

# FUNCTIONS #
function ExitOnError {
	Write-Error "Fatal error" -ErrorAction Stop;
}
function Delete {
	param(
        [parameter(Mandatory=$true)] [string]$Path
    );
	Remove-Item -Force -Recurse -ErrorAction Ignore $Path;
}
function CopyOrSkipDirectory {
	param(
        [parameter(Mandatory=$true)] [string]$Source,
        [parameter(Mandatory=$true)] [string]$Destination,
        [parameter(Mandatory=$false)] [string]$IncludeFilter,
        [parameter(Mandatory=$false)] [string]$ExcludeFilter
    );
	try {
		if ($IncludeFilter) {Copy-Item -Path $Source -Container -Include $IncludeFilter -Recurse -Force;}
		elseif($ExcludeFilter) {Copy-Item -Path $Source -Container -Exclude $ExcludeFilter -Recurse -Force}
		else {Copy-Item -Path $Source -Destination $Destination -Container -Recurse -Force;}
	}
	catch {
		Write-Error "Error copying directory from [$Source] to [$Destination]";
	}
}
function EmptyDestinationBase {
	param(
        [parameter(Mandatory=$true)] [string]$Destination
    );
	if(Test-Path $Destination) {
		Delete -Path $Destination;	
	}
	New-Item -ItemType "directory" -Path $Destination;
}
function BackupUserData {
	param(
        [parameter(Mandatory=$true)] [string]$DestinationBase,
		[parameter(Mandatory=$false)] [string]$Destination,
        [parameter(Mandatory=$true)] [string[]]$Paths
    );
	
	Write-Output "";
	foreach($path in $Paths) {
		$source = $path;
		$destination = $DestinationBase + $path.Split("C:\Users\")[1];
		Write-Output "Source: $path";
		Write-Output "Destination: $destination";
		$exists = Test-Path -Path $path;
		if(-Not $exists){
			Write-Error "Path does not exist: $path";
			continue;
		}

		CopyOrSkipDirectory -Source $path -Destination $destination;
	}
}
function BackupSoftwareBOM {
	param(
        [parameter(Mandatory=$true)] [string]$DestinationBase
    );
	
	Write-Output "";
	$chocolateyExpr = "choco list --local";
	$winlistExpr = "winget list";
	$bomChocoResult = Invoke-Expression $chocolateyExpr;
	$bomWinlistResult = Invoke-Expression $winlistExpr;
	try {
		New-Item -ItemType "file" -Name "bom.txt" -Path $DestinationBase;
	}
	catch {
		Write-Error "Error creating file [bom.txt] at destination [$DestinationBase]";
		ExitOnError;
	}
	$bomFile = $DestinationBase + "bom.txt";

	Add-Content -Path $bomFile -Value "Chocolatey";
	Add-Content -Path $bomFile -Value "";
	foreach($item in $bomChocoResult) {
		Add-Content -Path $bomFile -Value $item.ToString();
	}
	Add-Content -Path $bomFile -Value "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
	Add-Content -Path $bomFile -Value "Winlist";
	Add-Content -Path $bomFile -Value "";
	foreach($item in $bomWinlistResult) {
		Add-Content -Path $bomFile -Value $item.ToString();
	}
}
# function GitPush {
	# param(
        # [parameter(Mandatory=$true)] [string]$GitDir
    # );
	# cd $GitDir;

	# $gitAddExpr = "git add .";
	# $gitCommitExpr = "git commit --m 'Scripted backup.'";
	# $gitPushExpr = "git push origin main";

	# $gitAddResult = Invoke-Expression $gitAddExpr;
	# Write-Output $gitAddResult;
	# $gitCommitResult = Invoke-Expression $gitCommitExpr;
	# Write-Output $gitCommitResult;
	# $gitPushResult = Invoke-Expression $gitPushExpr;
# }

# RECREATE DESTINATION #
try {
	Write-Output "Recreating destination...";
	$stopwatch.Start();
	EmptyDestinationBase -Destination $destinationBase;
	$stopwatch.Stop();
	$opDuration = $stopwatch.Elapsed.Milliseconds;
	Write-Output "";
	Write-Output "Recreating the destination took $opDuration ms";
	$totalDuration += $opDuration;
}
catch {
	ExitOnError;
}

# BACKUP #
Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
Write-Output "Software BOM Backup";
$stopwatch.Reset();
$stopwatch.Start();
BackupSoftwareBOM -DestinationBase $destinationBase;
$stopwatch.Stop();
$opDuration = $stopwatch.Elapsed.Milliseconds;
Write-Output "";
Write-Output "Software BOM took $opDuration ms";
$totalDuration += $opDuration;

Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
Write-Output "%APPDATA% Backup";
$appData = @(
#"C:\Users\Nick Gogan\AppData\Roaming\TEST", #Test
"C:\Users\Nick Gogan\AppData\Roaming\Cmder\config\",
"C:\Users\Nick Gogan\AppData\Roaming\Code\User\",
"C:\Users\Nick Gogan\AppData\Roaming\mongodb\",
"C:\Users\Nick Gogan\AppData\Roaming\MongoDB Compass\",
"C:\Users\Nick Gogan\AppData\Roaming\MySQL\Workbench\sql_workspaces\",
"C:\Users\Nick Gogan\AppData\Roaming\Notepad++\",
"C:\Users\Nick Gogan\AppData\Roaming\NuGet\",
"C:\Users\Nick Gogan\AppData\Roaming\obsidian\",
"C:\Users\Nick Gogan\AppData\Roaming\obs-studio\plugin_config\"
);
$stopwatch.Reset();
$stopwatch.Start();
BackupUserData -Paths $appData -DestinationBase $destinationBase;
$stopwatch.Stop();
$opDuration = $stopwatch.Elapsed.Milliseconds;
Write-Output "";
Write-Output "Backing up %APPDATA% took $opDuration ms";
$totalDuration += $opDuration;

Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
Write-Output "%LOCALAPPDATA% Data";
$appLocalData = @(
"C:\Users\Nick Gogan\AppData\Local\CodeMaid\",
"C:\Users\Nick Gogan\AppData\Local\JetBrains\"
);
$stopwatch.Reset();
$stopwatch.Start();
BackupUserData -Paths $appLocalData -DestinationBase $destinationBase;
$stopwatch.Stop();
$opDuration = $stopwatch.Elapsed.Milliseconds;
Write-Output "";
Write-Output "Backing up %LOCALAPPDATA% took $opDuration ms";
$totalDuration += $opDuration;

Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
Write-Output "%USERNAME% Data";
$username = @(
"C:\Users\Nick Gogan\.aws\",
"C:\Users\Nick Gogan\.nuget\packages",
"C:\Users\Nick Gogan\.ssh\",
"C:\Users\Nick Gogan\.vscode\"
);
$stopwatch.Reset();
$stopwatch.Start();
BackupUserData -Paths $username -DestinationBase $destinationBase;
$stopwatch.Stop();
$opDuration = $stopwatch.Elapsed.Milliseconds;
Write-Output "";
Write-Output "Backing up %USERNAME% took $opDuration ms";
$totalDuration += $opDuration;

# # GITHUB #
# Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
# Write-Output "Pushing to GitHub";
# $stopwatch.Reset();
# $stopwatch.Start();
# GitPush -GitDir $gitDir;
# $stopwatch.Stop();
# $opDuration = $stopwatch.Elapsed.Milliseconds;
# Write-Output "";
# Write-Output "Pushing to GitHub took $opDuration ms";
# $totalDuration += $opDuration;

# REPORTING #
Write-Output "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
Write-Output "Total backup duration: $totalDuration ms";