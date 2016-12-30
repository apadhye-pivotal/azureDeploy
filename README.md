# Azure Provisioning for Apache Geode

These Azure deployment templates allow near push-button install of Apache Geode/Gemfire multiple Azure VMs.

### Login to Azure and set mode to ARM
```
$ azure login
$ azure config mode arm
```

### Checkout repo to a local directory
```
$ git clone git@github.com:apadhye-pivotal/azureDeploy.git
```

### Configure azuredeploy.parameters.json
##### (Note: any parameter listed in the ```parameters``` section of ```azuredeploy.json``` can be added to this file to override the defaults.)
- Public and private keypair data
- gfadmin default password
- Pivotal Network API key
- Cluster name
- Deployment Region
- Deployment/VM type
- Number of locators(1 or 2)
- Number of servers

### Create Resource Group

##### Example resource group in EastUS
```
$ azure group create geode-east -l eastus
```

### Deploy

##### Example cluster deployment
```
$ azure group deployment create -f azuredeploy.json -e azuredeploy.parameters.json geode-east -n geode-prod
```

### Login
```
$ ssh -i /path/to/my/sshPrivateKeyFile gpadmin@east-geode-mdw.eastus.cloudapp.azure.com
```

### Destroy
```
$ azure group deployment delete geode-east -n geode-prod
```
