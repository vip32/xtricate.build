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
* create a default.ps1 specfic for your project, modify the properties if needed.
* create a default.model.ps1 specific for your environment, start with a 'local' environment.
* run psake.cmd with the appropriate task.

### usage examples
> .\psake.cmd package
> - initiates the creation of the output packages, does a complete build.
>
> .\psake.cmd templatelocal
> - expands all templates (.template) in the local sources folder for the local environment.
>   
> .\psake.cmd packageinstall 
> - initiates the creation of the output packages and installs them on the current node, does a complete build
>
> .\psake.cmd remotepackageinstall -environment test -nodes nodeX -tags all
> -  installs the packages matching the tags on the remote node. before installing all templates are expanded for the specified environment.

### environment model introduction
xtricate.build relies heavily on an environment model (the model), like a dsl, which contains all the environments important for the project. 
examples of environments are : the local development workstation, a test or production environment. xtricate.build can manage the deployment of your project
through  all these environment. the environment model file to use is specified within the properties of the psake buildfile.

> ...
> $modelfile=resolvedefaultmodel
> ...

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
			
### local and remote project installation

the contents of the build folder contains everything needed for deployment on any node within an environment. 
starting with the following command to create the output packages :

> .\psake.cmd package

then copying the build folder to a node and executing :

> .\psake.cmd install

will install, according to the environment model, all applicable resources and packages on that node. 

### the demo solution uses the following technologies :
* microsoft visual studio 2010
* microsoft asp.net mvc 3
* microsoft sql ce 4.0

### some modules are based on work by:
* ang3lfir3/chewie : nuget package management

xtricate.build contains a modified version of **[psake](http://github.com/JamesKovacs/psake)** by James Kovacs. some small
improvements in module loading were made.
