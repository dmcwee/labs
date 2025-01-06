echo "Create User %1"
net user %1 %2 /add

echo "Add user %1 to Local Group %3"
net localgroup %3 %1 /add