Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Application" -NoNewWindow -Wait
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "System" -NoNewWindow -Wait
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Security" -NoNewWindow -Wait