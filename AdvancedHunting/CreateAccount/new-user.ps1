# Define the username and password for the new user
$username = "lrBadGuyPs"
$password = "P@ssw0rd!"

# Create a secure string for the password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

# Create the new local user
New-LocalUser -Name $username -Password $securePassword -FullName "Bad Guy" -Description "Bad Guy from Live Response"

# Add the new user to the Administrators group
Add-LocalGroupMember -Group "Administrators" -Member $username

Write-Output "User $username has been created and added to the Administrators group."
