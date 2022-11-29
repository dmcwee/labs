Configuration MDIEventRegistryKeys 
{
    Node localhost 
    {
        Registry 15FieldEngineering 
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics"
            ValueName = "15 Field Engineering"
            ValueData = "5"
            ValueType = "Dword"
        }

        Registry ExpensiveSearchResultThreshold
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters"
            ValueName = "Expensive Search Results Threshold"
            ValueData = "1"
            ValueType = "Dword"
        }

        Registry InefficientSearchResultsThreshold
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters"
            ValueName = "Inefficient Search Results Threshold"
            ValueData = "1"
            ValueType = "Dword"
        }

        Registry SearchTimeThreshold_msecs
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters"
            ValueName = "Search Time Threshold (msecs)"
            ValueData = "1"
            ValueType = "Dword"
        }
    }
}