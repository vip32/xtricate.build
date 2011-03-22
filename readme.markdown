xtricate.build
==============

xtricate.build is a psake build and deployment extension. 

## demonstration
.\src\demo* contains a buildable and deployable .net 4 solution using these xtricate.build extensions

### xtricate.build features : 
* environment management
* nuget package management
* solution build
* configuration and script templating
* output packaging
* local and remote deployment
* html and diagram documentation
* tag driven model execution
* non obtrusive to your project or environment

### how can i use xtricate.build in my projects :
* copy the .\build folder to the root of your branch. 
* create a default.ps1 specific for your projects, modify the properties if needed.
* create a default.model.psm1 specific for your environment, start with a 'local' environment.
* run psake.cmd with the appropriate task.

### basic usage examples

> .\psake.cmd package

initiates the creation of the output packages, does a complete build.

> .\psake.cmd templatelocal

expands all templates (.template) in the sources folder for the local environment.
   
> .\psake.cmd packageinstall 

initiates the creation of the output packages and installs them on the current node, does a complete build

> .\psake.cmd remotepackageinstall -environment test -nodes nodeX -tags all

installs the packages matching the tags on the remote node. before installing all templates are expanded for the specified environment.

### environment model introduction
xtricate.build relies heavily on an environment model (the model), like a dsl, which contains all the environments important for the project. 
examples of environments are : the local development workstation, a test or production environment. xtricate.build can manage the deployment of your project
for all these environments. the model file to use is specified within the properties of the psake buildfile.

> ...
> $modelfile=resolvedefaultmodel
> ...

the defaultmodel function resolves to 'default.model.psm1' if the psake buildfile used is named 'default.ps1'.
an environment consists of nodes (e.g. computers, load balancers). each node has resources and packages assigned to it
* a resource is something that will be there or must be created (e.g. accounts, apppools, websites, certificates).
* a package is something that is created by your project, for example : webapplication, folders, webservices, console apps, scheduled tasks, windows services

## the environment model dsl :
    configuration
        settings
            environment -id 'local' -name
                settings
                node 'localhost' -id -name
                    resources -id -name -skipinstall -skipuninstall-tags
                    packages -id -name -skipinstall -skipuninstall-tags
            environment -id 'test' -name
                settings
                node -id 'webserver' -name
                    resources
                    packages
                node -id 'dbserver' -name
                    resources
            		package
			
### local and remote project installation

the contents of the build folder contains everything needed for deployment on any node within an environment. 
starting with the following command to create the output packages :

> .\psake.cmd package

then manually copying the build folder to a node and executing :

> .\psake.cmd install

will install, according to the environment model, all applicable resources and packages on that node. 

or, let xtricate.build handle everything. building, copying and installation on a node can be done like this :

> .\psake.cmd remotepackageinstall -environment test -nodes dev-srv-1

### the demo solution uses the following tools and technologies :
* microsoft visual studio 2010
* microsoft asp.net mvc 3
* microsoft sql ce 4.0
* specflow
* watin
* nunit
* **[nuget](http://nuget.org/List/Packages/xtricate.build)**

### some modules are based on work by:
* **[chewie](https://github.com/Ang3lFir3/Chewie)** : nuget package management
* **[soever](http://weblogs.asp.net/soever/archive/2006/12/31/a-templating-engine-using-powershell-expressions.aspx)** : template engine
* **[poshcode.org](http://poshcode.org)** : various scripts

xtricate.build contains a modified version of **[psake](http://github.com/JamesKovacs/psake)** by James Kovacs. some small
improvements in module loading were made.