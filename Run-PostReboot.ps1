    <#
    .SYNOPSIS

    .DESCRIPTION
    
    .PARAMETER Path
    
    .INPUTS

    .OUTPUTS

    .EXAMPLE

    .LINK
#>
[cmdletbinding()]
param(
    [parameter(Mandatory=$true,HelpMessage='Name of the task.')]
    [string]$TaskName,
    [parameter(Mandatory=$false,HelpMessage='Name of the task path. Places a folder in the Task Scheduler.')]
    [string]$TaskPath,
    [parameter(Mandatory=$true,HelpMessage='What do you want to execute.')]
    [string]$Execute,
    [parameter(Mandatory=$false,HelpMessage='Arguments to pass into the executable.')]
    [string]$Argument,
    [Parameter(Mandatory = $false, HelpMessage = 'Path to Save Log Files')]
    [string]$LogPath = "$env:Windir\Logs"
)

begin{
    #-- BEGIN: Executes First. Executes once. Useful for setting up and initializing. Optional
    if($LogPath -match '\\$'){
        $LogPath = $LogPath.Substring(0,($LogPath.Length - 1))
    }
    Write-Verbose -Message "Creating log file at $LogPath."
    #-- Use Start-Transcript to create a .log file
    #-- If you use "Throw" you'll need to use "Stop-Transcript" before to stop the logging.
    #-- Major Benefit is that Start-Transcript also captures -Verbose and -Debug messages.
    $ScriptName = & { $myInvocation.ScriptName }
    $ScriptName =  (Split-Path -Path $ScriptName -Leaf)
    Start-Transcript -Path "$LogPath\$($ScriptName.Substring(0,($ScriptName.Length) -4)).log"
}
process{
    #-- PROCESS: Executes second. Executes multiple times based on how many objects are sent to the function through the pipeline. Optional.
    try{
        #-- Try the things
        if($null -eq $Argument -or $Argument -eq ''){
            Write-Verbose -Message "Creating action with Execute parameter $Execute"
            $Action = New-ScheduledTaskAction -Execute "$Execute"
        } else {
            Write-Verbose -Message "Creating action with Execute parameter $Execute and Argument parameter $Argument"
            $Action = New-ScheduledTaskAction -Execute "$Execute" -Argument "$Argument"
        }

        Write-Verbose -Message "Creating Trigger at startup."
        $Trigger = New-ScheduledTaskTrigger -AtStartup
        Write-Verbose -Message "Creating Principal with RunLevel Highest running as SYSTEM."
        $Principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId 'SYSTEM' -LogonType ServiceAccount
        ##-- Check for scheduled task with matching name
        Write-Verbose -Message "Checking for existing task."
        $currentSchedTask = Get-ScheduledTask -TaskName "*$TaskName*" -TaskPath "*$TaskPath*"
        if($null -ne $currentSchedTask){
            Write-Warning -Message "Task with name $TaskName found."
            Write-Host -Message "Renaming Task."
            $currentTaskPath = $currentSchedTask.TaskPath
            $currentTaskName = $currentSchedTask.TaskName
            $currentSchedTask | Export-ScheduledTask | Register-ScheduledTask -TaskName "$($currentTaskName)_Old" -TaskPath $currentTaskPath
            Write-Verbose -Message "Unregistering $currentTaskName task."
            Unregister-ScheduledTask -TaskName $currentTaskName
            
        } else {
            ##-- Create task cleanup action
            $Action = ($Action), (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "Start-Sleep -Seconds 300; Unregister-ScheduledTask -TaskName $TaskName")
            ##-- Create Task
            Write-Verbose -Message "Creating Task $TaskName."
            $task = Register-ScheduledTask -TaskName $TaskName -Action $Action -Description "A Task to run once after a reboot." -Trigger $Trigger -Principal $principal -TaskPath $TaskPath
            $Task | Set-ScheduledTask
        }

    } catch {
        #-- Catch the error
        Write-Error $_.Exception.Message
        Write-Error $_.Exception.ItemName
    }
}
end{
    # END: Executes Once. Executes Last. Useful for all things after process, like cleaning up after script. Optional.
    Stop-Transcript
}