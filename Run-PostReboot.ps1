[cmdletbinding()]
#-- Create scheduled task
$TaskName = "Test"
$Action = New-ScheduledTaskAction -Execute "msg.exe" -Argument " * Test Scheduled task"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId 'SYSTEM' -LogonType ServiceAccount

##-- Check for scheduled task with matching name
if($null -ne (Get-ScheduledTask -TaskName $TaskName)){
    Write-Warning -Message "Task with name $TaskName found."
} else {
    $task = Register-ScheduledTask -TaskName $TaskName -Action $Action -Description "A Task to run once after a reboot." -Trigger $Trigger -Principal $principal
    $Task | Set-ScheduledTask
}
