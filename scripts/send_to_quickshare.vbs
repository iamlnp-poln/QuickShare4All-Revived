Set objArgs = WScript.Arguments
If objArgs.Count > 0 Then
    Dim fileList, i
    fileList = ""
    For i = 0 To objArgs.Count - 1
        If i > 0 Then
            fileList = fileList & "<"
        End If
        fileList = fileList & objArgs(i)
    Next
    uri = "quickshare://pc/send?fileList=" & fileList
    Set objShell = CreateObject("WScript.Shell")
    objShell.Run "explorer.exe """ & uri & """", 0, False
End If
