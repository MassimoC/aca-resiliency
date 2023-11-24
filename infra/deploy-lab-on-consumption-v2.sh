#!/bin/bash
. ./variables.sh

projectName='acaresiliency'

echo "${DBG}... Trigger INFRA deployment on $projectName"

#az stack sub create --name "$projectName" --template-file lab-infra.bicep --parameters project=$projectName --location westeurope --deny-settings-mode None --yes

echo "${DBG}... Trigger APP deployment on $projectName"

az stack sub create --name "$projectName-s1" --template-file lab-apps.bicep --parameters project=$projectName --location westeurope --deny-settings-mode None --yes

echo "${DBG}... Script completed"
