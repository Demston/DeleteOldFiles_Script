######   Cleaning empty folders (including nested ones) and files older than N days/months   ######


$logDate =  (Get-Date).AddDays(-30)         # Period (how many months to store logs)
$deleteDate = (Get-Date).AddMonths(-3)      # Period (how many months to keep files before purging)
$logFile = "D:\Test\DeleteOldFiles_Log.txt" # Path to logs
$targetPath = "D:\Test"                     # Path to the folder to be cleaned


if (Test-Path $logFile) {
    # Take the file creation date
    $logCreated = (Get-Item $logFile).CreationTime
    # If the log is more than 30 days old
    if ($logCreated -lt $logDate) {
        # Delete (or rename to archive)
        Remove-Item $logFile -Force
        Write-Host "Logs older than 30 days have been deleted."
    }
}


function ClearFolder {
    param ( [string]$path, [string]$TargetDate )
    # Basic logic: Cleaning temporary folders of old files.
    $curdate = (Get-Date)
    $scurdate = $curdate.ToString('yyyy-MM-dd HH:mm:ss')
    $date = $TargetDate

    $sMsgStr = ":Start deleting files from " + $path

    try {
        # First, find the list of files in a variable
        $filesToDelete = Get-ChildItem -LiteralPath $path -Recurse -ErrorAction SilentlyContinue | 
                         Where-Object { !$_.PSIsContainer -and ($_.LastWriteTime -lt $date) }

        foreach ($file in $filesToDelete) {
            try {
                $filePath = $file.FullName
                $file | Remove-Item -Force -ErrorAction Stop
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | FILE DELETED: $filePath" | Out-File -LiteralPath $logFile -Append
            }
            catch {
                # If the file is busy or there are no rights, we write the specific error for the file.
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | FILE DELETED ($filePath): $($PSItem.Exception.Message)" | Out-File $logFile -Append
            }
        }
    }
    catch {
        # Will only work if the path $path is not accessible
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | ERROR: $($PSItem.Exception.Message)" | Out-File $logFile -Append
    }


    $curdate = (Get-Date)
    $scurdate = $curdate.ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "$($scurdate): Completing the deletion of files from $($path)"
    Write-Host ""

    $curdate = (Get-Date)
    $scurdate = $curdate.ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "$($scurdate): Start deleting empty folders from $($path)"
    

    try {
        # Get a list of all folders into a variable
        $allFolders = Get-ChildItem -LiteralPath $path -Recurse -Directory -ErrorAction SilentlyContinue | 
                      Sort-Object { $_.FullName.Length } -Descending
        foreach ($folder in $allFolders) {
        # Let's check right away whether the folder is empty
            $items = Get-ChildItem -LiteralPath $folder.FullName -Force -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -eq $items) {
                try {
                    $folder | Remove-Item -Force -Recurse -ErrorAction Stop
                    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | EMPTY FOLDER DELETED: $($folder.FullName)" | Out-File $logFile -Append
                    Write-Host "Deleted: $($folder.Name)" -ForegroundColor Green
                }
                catch {
                    "$(Get-Date): Error deleting $($folder.FullName): $($PSItem.Exception.Message)" | Out-File $logFile -Append
                }
            }
        }
    }
    catch {
       "$(Get-Date): $($PSItem.Exception.Message)" | Out-File -FilePath $logFile -Append
    }

    $curdate = (Get-Date)
    $scurdate = $curdate.ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "$($scurdate): Finished deleting empty folders from $($path)"
    Write-Host ""
}


$curdate = (Get-Date)
$scurdate = $curdate.ToString('yyyy-MM-dd HH:mm:ss')
# Write-Host "$($scurdate): Start" >> $logFile
"--- $($scurdate): START SCRIPT ---" | Out-File $logFile -Append

# Start cleaning
ClearFolder -path $targetPath -TargetDate $deleteDate
