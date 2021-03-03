<#
.SYNOPSIS
=============================================================================
	./rc.SS.ps1

	must be done first: (& powershell -Command Set-ExecutionPolicy RemoteSigned)
=============================================================================
	The script running soft @Peleng
.DESCRIPTION
	please use rc.SS [start|stop|restart|status]
.PARAMETER	-D [1^|..] : включить отладочный режим. Будет производится вывод дополнительной информации;
.NOTES
	Developer Dmitriy L. Ivanov aka onepif
	JSC PELENG 2020
	All rights reserved
#>

Param(
	[Switch]$Verbose,

	[ValidateSet("start", "stop", "restart", "status")]
	[string]$action="start",

	[ValidatePattern("[0-9]")]
	[alias('d')]
    [Int]$GLOBAL:Dbg=0
)

$fNAME		= [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$fLOG		= "$($Data.pLOG)\$fNAME.log"

if( $Dbg ){ $GLOBAL:FLAG_CONS = $true } else { $GLOBAL:FLAG_CONS = $PSBoundParameters.Verbose }
# ==============================================================================
Function Check() {
# Check that we're a owner
	if( $env:USERNAME -ne $Data.USER_PELENG ){
		CMD_DBG 2 $MyInvocation.MyCommand.Name "exit 4"
		exit 4
	}

# Check if SS is existing
	if( !(Test-Path -Path $env:WINDIR\SupervisorServer.exe) ){
		CMD_DBG 2 $MyInvocation.MyCommand.Name "exit 5"
		exit 5
	}

	if( !(Test-Path -Path $Data.pLOG) ){ New-Item -type Directory -Path $Data.pLOG *>$null }
	if( !(Test-Path -Path $Data.pRUN) ){ New-Item -type Directory -Path $Data.pRUN *>$null }

	CMD_DBG 2 $MyInvocation.MyCommand.Name "work completed"
}
# ==============================================================================
Function Start-SS(){

	Check

	$PIDVAL = (Get-Process |where {$_.ProcessName -eq "SupervisorServer"}).Id
	if( $PIDVAL ){
# the process is already running
		CMD_DBG 2 $MyInvocation.MyCommand.Name "the process is already running with PID: $PIDVAL"
		$RETVAL = 1
	} else {
		CMD_Empty
		Out-Logging -out $fLOG -src $MyInvocation.MyCommand.Name -m "=== start SupervisorServer ===" -cr
		Start-Process -FilePath "$env:WINDIR\SupervisorServer.exe" -WorkingDirectory "$($Data.PATH_PELENG)" -ArgumentList "-c $env:WINDIR\SupervisorServer.xml"
		$PIDVAL = (Get-Process |where {$_.ProcessName -eq "SupervisorServer"}).Id
		if( Test-Path -Path "$($Data.pRUN)/$fNAME.pid" ){ Out-Logging -out $fLOG -src $MyInvocation.MyCommand.Name -t w -m "previous session crashed" -cr }
		Set-Content -Path "$($Data.pRUN)/$fNAME.pid" -Value $PIDVAL
		Out-Logging -out $fLOG -src $MyInvocation.MyCommand.Name -m "run $fNAME with PID: $PIDVAL" -cr
		$RETVAL=0
	}

	CMD_DBG 2 $MyInvocation.MyCommand.Name "work completed"

#	return $RETVAL
}
# ==============================================================================
Function Stop-SS(){

	Check

	if( Get-Process |where {$_.ProcessName -eq "SupervisorServer"} ){
		$PIDVAL = (Get-Process "SupervisorServer").Id
		if( Test-Path -Path "$($Data.pRUN)/$fNAME.pid" ){
			$fPIDVAL = Get-Content "$($Data.pRUN)\$fNAME.pid"
			CMD_DBG 2 $MyInvocation.MyCommand.Name "SupervisorServer, PID from file: $fPIDVAL"
		} else {
			Out-Logging -out $fLOG -src $MyInvocation.MyCommand.Name -t w -m "start of the current session is carried out manually" -cr
		}
		CMD_DBG 2 $MyInvocation.MyCommand.Name "SupervisorServer, PID: $PIDVAL"

		if( "$PIDVAL" -ne "$fPIDVAL" ){
			Out-Logging -out $fLOG -src $MyInvocation.MyCommand.Name -t w -m "PID file is outdated" -cr
		}
		foreach( $ix in $PIDVAL ){ TaskKill /pid $ix /t /f *>$null }
		Remove-Item -Force -Path "$($Data.pRUN)/$fNAME.pid" *>$null
	} else {
		if( Test-Path -Path "$($Data.pRUN)/$fNAME.pid" ){
			Out-Logging -out $fLOG -src $MyInvocation.MyCommand.Name -t w -m "SupervisorServer not running, previous session crashed" -cr
		} else {
			Out-Logging -out $fLOG -src $MyInvocation.MyCommand.Name -t w -m "SupervisorServer not running" -cr
		}
	}

	CMD_DBG 2 $MyInvocation.MyCommand.Name "work completed"
}
# ==============================================================================
Function Restart-SS(){ Stop-SS; Sleep 2; Start-SS }
# ==============================================================================
Function Status(){
	foreach( $ix in	"SupervisorServer",
					"Recorder",
					"Player3",
					"VGrabber",
					"Master",
					"DbSync",
					"RTS",
					"Tachyon",
					"IS",
					"Imitator",
					"E1SS",
					"YourSender",
					"trs",
					"fdpsevices",
					"dbSynchronizer" ){
		if( Get-Process |where {$_.ProcessName -eq "$ix"} ){ Out-Logging -out $fLOG -src $MyInvocation.MyCommand.Name -m "$ix (PID: $($(Get-Process $ix).Id)) is Running" -cr }
	}

	CMD_DBG 2 $MyInvocation.MyCommand.Name "work completed"
}
# ==============================================================================
#if( $dbg ){ $DEBUG = 2 }

#CMD_DBG 2 $MyInvocation.MyCommand.Name "PATH_PELENG=$($Data.PATH_PELENG), Args: $Args"

Switch( $action ){
	"start"		{ Start-SS;		Break }
	"stop"		{ Stop-SS;		Break }
	"restart"	{ Restart-SS;	Break }
	"status"	{ Status;		Break }
	Default		{ $null }
}
