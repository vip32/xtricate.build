xtricate.build
==============

src\demo* demonstrates a buildable and deployable solution using these xtricate.build extensions

### xtricate.build features : 
* environment management
* nuget package management
* solution build
* configuration and script templating
* output packaging
* local and remote deployment
* html and diagram documentation

### how can i use xtricate.build in my projects :
* copy the build folder to the root of your branch. 
* create a default.ps1 specfic for your project, modify the properties.
* create a default.model.ps1 specific for your environment.
* run psake.cmd with the appropriate task.

### usage examples
> .\psake.cmd package
> - this will initiate the creation of the packages
> 
> .\psake.cmd packageinstall 
> - this will install the packages on the local node
>
> .\psake.cmd remotepackageinstall -nodes nodeX -tags all
> - this will install the packages matching the tags on the remote node 

### model introduction
this extension relies heavily on an environment model, like a dsl, which contains all the environments. 
the model file to use is specified in the properties of the psake buildfile.
> $modelfile=resolvedefaultmodel
the defaultmodel function resolves to 'default.model.ps1' if the psake buildfile used is named 'default.ps1'.
an environment consists of nodes (e.g. computers, load balancers). each node has resources and packages assigned to it
a resource is something that will be there or must be created (e.g. accounts, apppools, websites).
a package is something that is created by your project, for example : websites, folders, webservices, scheduled tasks, windows services

## the environment model dsl :
environment 'local'
	node 'localhost'
		resources
		packages
environment 'test'
	node 'webserver'
		resources
		packages
	node 'dbserver'
		resources
		package
		
### the demo solution uses the following technologies :
* microsoft visual studio 2010
* microsoft asp.net mvc 3
* microsoft sql ce 4.0

### some modules are based on work by:
* ang3lfir3/chewie : nuget package management

xtricate.build contains a modified version of **[psake](http://github.com/JamesKovacs/psake)** by James Kovacs. some small
improvements in module loading were made.
