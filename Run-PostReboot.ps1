
Function New-CustomScheduledTask{
    [cmdletbinding()]
    param(
        [string]$TaskName,
        [string]$TaskPath,
        [string]$Execute,
        [string]$Argument
    )

    $Action = New-ScheduledTaskAction -Execute "$Execute" -Argument "$Argument"
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId 'SYSTEM' -LogonType ServiceAccount
    ##-- Check for scheduled task with matching name
    $currentSchedTask = Get-ScheduledTask -TaskName $TaskName
    if($null -ne $currentSchedTask){
        Write-Warning -Message "Task with name $TaskName found."
    } else {
        Write-Verbose -Message "Creating Task $TaskName."
        $task = Register-ScheduledTask -TaskName $TaskName -Action $Action -Description "A Task to run once after a reboot." -Trigger $Trigger -Principal $principal -TaskPath $TaskPath
        $Task | Set-ScheduledTask
    }
}

#-- Create scheduled task
$TaskPath = 'Test'
$TaskName = "Test"
New-CustomScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Execute "powershell.exe" -Argument "-ExecutionPolicy ByPass -NoProfile -Command Write-Output 'Information - TEST' | Out-File 'C:\Windows\Logs\TestScheduledTask.log' -Append"