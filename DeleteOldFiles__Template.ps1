######   Cleaning empty folders (including nested ones) and files older than N days/months
######   Очистка пустых папок (в т.ч. вложенных) и файлов, старше N-дней/месяцев.   


$logDate =  (Get-Date).AddDays(-30)         # Период (сколько месяцев хранить логи)
$deleteDate = (Get-Date).AddMonths(-3)      # Период (сколько месяцев хранить файлы перед очисткой)
$logFile = "D:\Test\DeleteOldFiles_Log.txt" # Путь к логам
$targetPath = "D:\Test"                     # Путь к очищаемой папке


if (Test-Path $logFile) {
    # берем дату создания файла
    $logCreated = (Get-Item $logFile).CreationTime
    # Если логу больше 30 дней
    if ($logCreated -lt $logDate) {
        # удаляем (либо переименовываем в архив)
        Remove-Item $logFile -Force
        Write-Host "Logs older than 30 days have been deleted."
    }
}


function ClearFolder {
    param ( [string]$path, [string]$TargetDate )
    # Код для выполнения нужных задач. Очистка временных папок от старых файлов.
    $curdate = (Get-Date)
    $scurdate = $curdate.ToString('yyyy-MM-dd HH:mm:ss')
    $date = $TargetDate

    $sMsgStr = ":Start deleting files from " + $path

    try {
        # сначала находим список файлов в переменную
        $filesToDelete = Get-ChildItem -LiteralPath $path -Recurse -ErrorAction SilentlyContinue | 
                         Where-Object { !$_.PSIsContainer -and ($_.LastWriteTime -lt $date) }

        foreach ($file in $filesToDelete) {
            try {
                $filePath = $file.FullName
                $file | Remove-Item -Force -ErrorAction Stop
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | FILE DELETED: $filePath" | Out-File -LiteralPath $logFile -Append
            }
            catch {
                # если файл занят или нет прав — пишем конкретную ошибку по файлу
                "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | FILE DELETED ($filePath): $($PSItem.Exception.Message)" | Out-File $logFile -Append
            }
        }
    }
    catch {
        # сработает, только если путь $path недоступен
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
        # Получаем список всех папок в переменную
        $allFolders = Get-ChildItem -LiteralPath $path -Recurse -Directory -ErrorAction SilentlyContinue | 
                      Sort-Object { $_.FullName.Length } -Descending
        foreach ($folder in $allFolders) {
        # Сразу проверяем, пустая ли папка
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
# Write-Host "$($scurdate): Старт" >> $logFile
"--- $($scurdate): START SCRIPT ---" | Out-File $logFile -Append

# Запустим очистку.
ClearFolder -path $targetPath -TargetDate $deleteDate
