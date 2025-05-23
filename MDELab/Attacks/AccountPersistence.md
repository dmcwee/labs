# Account Persistence

This scenario is to detect if a recently created account has been added to a highly privileged group. This is a common persistence technique.

## Scenario

This will create a new user and then add that user to the local admin group on the device.

### Steps: Create User

On a testing machine open the Command Prompt as an Admin 

1. List current users `net user`
1. List local groups `net localgroup`
1. Create an example user from command line: `net user {username} {password} /add`
1. Add user to local admin group `net localgroup Administrators {username} /add`
1. Confirm user is in local admin group `net localgroup Administrators`

> *Script:* [download] (../../AdvancedHuting/CreateAccount/CreateAccount.cmd)

### Advanced Hunting

In the Security Portal open Advanced hunting and walk the customer through the query creation process below.

1. Start by finding all account events [Query 1](../../AdvancedHunting/CreateAccount/CreateAccount-Query1.kql)
1. Reduce results to just Account Creation & Account Added to Local Group [Query 2](../../AdvancedHunting/CreateAccount/CreateAccount-Query2.kql)
1. Reduce our initial results to just account created and get select fields. We will merge this into a single line with the Account added to group events shortly. Note: AccountSid in this event refers to the account created SID [Query 3](../../AdvancedHunting/CreateAccount/CreateAccount-Query3.kql)
1. Assign the results of the query to a local scaler variable and add back the query for Account Added events as well as extending the query by parsing the JSON in the Additional Fields column to extract Group Name [Query 4](../../AdvancedHunting/CreateAccount/CreateAccount-Query4.kql)
1. Next merge the scaler value & query using an inner join method. You can now see the Time the Account was created as well as the Time the Account was added to the local group. [Query 5](../../AdvancedHunting/CreateAccount/CreateAccount-Query5.kql)
1. Extend the query by calculating the time difference between when the account was created and when it was added to the local group. Also, reduce the output fields to just those we want to see: Created, Added, Account Name, Local Group, Device Id, Device Name, Created By [Query 6](../../AdvancedHunting/CreateAccount/CreateAccount-Query6.kql)
1. Finally filter out the default action of adding the user to the local Users group and include the Timestamp, ReportId, and InitiatingProcessAccountObjectId fields which are required for creating Custom NRT Detection [Query Final](../../AdvancedHunting/CreateAccount/CreateAccount-QueryFinal.kql)

### Create Custom Detection

1. From the Advanced Hunting page for the above final query choose the Manage rules and select Create custom detection
1. Provide Alert DetailsDetection Name: User Created and Added to Sensitive group
    1. Frequency: Hourly
    1. Alert Title: User Created and Added to Sensitive group
    1. Severity: High
    1. Category: Persistence
    1. MITRE Techniques: {Select the various MITRE techniquest (e.g. T1162, T1078.001, T1136.001)}
    1. Description: Alert when a new user is created and then added to a local privileged group.
    1. Recommended Actions: Review the account created to ensure it is a valid account and should have permission granted.
1. Impacted Entities
    1. Device: DeviceId
    1. User: InitiatingProcessAccountObjectId
1. Actions (Optional - Just showing these settings is fine and then demonstrate the alert being created)
    1. Devices: Choose an action to perform - Isolate device (Full) or Restrict app execution are good options for demonstration
    1. User: Mark user as compromised
        > The user account that was used to create the account is the account that will be Marked As Compromised
    1. Save the Custom Alert

## Queries

* [Query 1](../../AdvancedHunting/CreateAccount/CreateAccount-Query1.kql)
* [Query 2](../../AdvancedHunting/CreateAccount/CreateAccount-Query2.kql)
* [Query 3](../../AdvancedHunting/CreateAccount/CreateAccount-Query3.kql)
* [Query 4](../../AdvancedHunting/CreateAccount/CreateAccount-Query4.kql)
* [Query 5](../../AdvancedHunting/CreateAccount/CreateAccount-Query5.kql)
* [Query 6](../../AdvancedHunting/CreateAccount/CreateAccount-Query6.kql)
* [Query Final](../../AdvancedHunting/CreateAccount/CreateAccount-QueryFinal.kql)
