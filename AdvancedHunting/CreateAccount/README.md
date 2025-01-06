# Create Account Queries

The queries in this folder are an example of developing an Advanced Hunting query that can be used for a Custom Alert. 

## Scenario

Consider the scenario where a security team would like to monitor when a new account has been created and then granted advanced
permissions on a local device or domain. This is a well know threat 

The scenario for these queries are
The goal is to detect
when a new account has been created and is then added to a sensitive group on a local device. This type of detection is useful as it can be
a persistence tactic for both access & priviledges.

## Queries

**Query 1:** Grab all the Account events on devices so we can see what event types we care about.

**Query 2:** Reduce the Account events to AccountCreated and AccountAddedToLocalGroup so we can look at these in more depth. 

**Query 3** What we 