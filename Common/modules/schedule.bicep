param name string
param id string
param time string = '1900'
param timeZone string = 'Eastern Standard Time'
param location string = resourceGroup().location

resource schedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name:'shutdown-computevm-${toLower(name)}'
  location: location
  properties: {
    dailyRecurrence: {time: time}
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    timeZoneId: timeZone
    notificationSettings: {status: 'Disabled'}
    targetResourceId: id
  }
}
