function Show-NoteMessage {
    <#
    .SYNOPSIS
        Shows a Note message box and returns the selected result.
    #>
    param (
        [string]$Message,
        [string]$Title = "Note",
        $Button = "OK",
        $Icon = "Information"
    )

    [System.Windows.MessageBox]::Show($Message, $Title, $Button, $Icon)
}
