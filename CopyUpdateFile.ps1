# Prompt for server list input (comma-separated)
$ServerInput = Read-Host "Enter the server names separated by commas (e.g., wdevppes101,wdevppes102,wdevppes103)"
$Servers = $ServerInput -split ','

# Ensure a valid server list is provided
if ($Servers.Count -eq 0) {
    Write-Host "No servers provided. Exiting."
    exit
}

# Trim whitespace from each server name
$Servers = $Servers | ForEach-Object { $_.Trim() }

# Prompt for server credentials with a pop-up
$Credential = Get-Credential

# Open a file selector dialog for the local file path
Add-Type -AssemblyName System.Windows.Forms
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "All files (*.*)|*.*"
$OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop") # Default to Desktop
if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $LocalFilePath = $OpenFileDialog.FileName
} else {
    Write-Host "No file selected. Exiting."
    exit
}

# Prompt for the base remote path
$RemotePathBase = Read-Host "Enter the remote path (e.g., Z:\Source\SharePoint 2016 Updates)"
if ([string]::IsNullOrWhiteSpace($RemotePathBase)) {
    Write-Host "No remote path provided. Exiting."
    exit
}

# Extract the file name from the local file path
$RemoteFileName = [System.IO.Path]::GetFileName($LocalFilePath)

# Prompt for delay time between servers (in seconds)
$DelayTime = Read-Host "Enter the delay time between operations for each server (in seconds)"
if (-not [int]::TryParse($DelayTime, [ref]$null)) {
    Write-Host "Invalid delay time provided. Exiting."
    exit
}

# Loop through each server and perform the operation
foreach ($Server in $Servers) {
    Write-Host "Processing server: $Server"

    try {
        # Create a network drive using the provided credentials
        $DriveName = "Z"
        New-PSDrive -Name $DriveName -PSProvider FileSystem -Root "\\$Server\e$" -Credential $Credential -ErrorAction Stop

        # Ensure the remote folder exists
        if (-not (Test-Path -Path $RemotePathBase)) {
            New-Item -Path $RemotePathBase -ItemType Directory -Force
            Write-Host "Created folder: $RemotePathBase on $Server"
        }

        # Copy the file to the remote destination
        $RemotePath = "$RemotePathBase\$RemoteFileName"
        Copy-Item -Path $LocalFilePath -Destination $RemotePath -Force -ErrorAction Stop

        Write-Host "File successfully copied to $Server at $RemotePath."
    } catch {
        Write-Host "Failed to process $Server. Error: $_"
    } finally {
        # Remove the network drive
        Remove-PSDrive -Name $DriveName -Force
    }

    # Wait for the specified delay before processing the next server
    Start-Sleep -Seconds $DelayTime
}
