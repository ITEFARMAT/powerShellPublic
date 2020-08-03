$totalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum
while ($true) {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $cpuTime = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $availMem = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
    $memUsage = 100 - (104857600 * $availMem / $totalRam)
    $diskRead = (Get-Counter '\LogicalDisk(C:)\Disk Reads/sec').CounterSamples.CookedValue
    $diskWrite = (Get-Counter '\LogicalDisk(C:)\Disk Writes/sec').CounterSamples.CookedValue
    $date + ' > CPU: ' + $cpuTime.ToString("#,0.00") + '%, Used. Mem.: ' + $memUsage.ToString("#,0.00") + ' %  ' + 'DiskRead/sec: ' + $diskRead.ToString("#,0.00") + ' KB/s ' + "  " + 'DiskWrite/sec: ' + $diskWrite.ToString("#,0.00") + ' KB/s '
    Start-Sleep -s 2
}
