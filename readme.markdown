xtricate.build
==============

xtricate.build is a psake build and deployment extension. 

### some of the features 
* environment management: control your environment and everything depending on it.
* local and remote deployments: one way to deploy them all
* output packaging: keep everything deployable in one place
* configuration and script templating: the model knows everything, use it
* tag based model execution: only install what you want or need
* non obtrusive: no modifications to your projects needed
* extensibility: change the model dsl with your own items
* environment smoke testing: is your environment installed correctly?
* html and diagram documentation: get an overview of your project and environment
* nuget package management: use or publish packages with nuget

### how can i use xtricate.build in my projects?
* copy the `.\build` folder to the root of your branch, rename if you like. 
* create a `.\build\default.ps1` specific for your projects, modify the properties if needed.
* create a `.\build\default.model.psm1` specific for your environment, start with a 'local' environment.
* run `psake.cmd taskname(s)` from the `.\build` folder with the appropriate task(s).

## demonstration
`.\src\demo*` contains a buildable and deployable .net 4 solution using these xtricate.build extensions. 

    .\build
		\assets						[demo project assets like certificates]
		\modules					[xtricate.build psake modules]
		\output						
			\default.master			[demo project output packages appear here]
		\tools						[xtricate.build tools like nunit and nuget]
		default.ps1					[demo project psake file, the tasks]
		default.model.psm1			[demo project model file, the environments]
	.\lib							[demo project external libraries appear here]
    .\src							[demo project solution]
		\demo
		...
		\demo.webservices

## basic usage examples
run the following commands from the `.\build` folder

> .\psake.cmd package

initiates the creation of the output packages, does a complete build and places the packages in the `.\output` folder.

> .\psake.cmd templatelocal

expands all templates (.template) in the sources folder for the local environment.
   
> .\psake.cmd packageinstall 

initiates the creation of the output packages and installs them on the current node, does a complete build

> .\psake.cmd remotepackageinstall -environment test -nodes nodeX -tags all

installs the packages matching the tags on the remote node. before installing all templates are expanded for the specified environment.

## model introduction
xtricate.build relies heavily on an environment model (the model), like a dsl, which contains all the environments important for the project. 
examples of environments are : the local development workstation, a test or production environment. xtricate.build can manage the deployment of your project
for all these environments. the model file to use is specified within the properties of the psake buildfile.

> ...
> $modelfile=resolvedefaultmodel
> ...

the defaultmodel function resolves to `default.model.psm1` if the psake buildfile used is named `default.ps1`.
an environment consists of nodes (e.g. computers, load balancers). each node has resources and packages assigned to it
* a resource is something that will be there or must be created (e.g. accounts, apppools, websites, certificates).
* a package is something that is created by your project, for example : webapplication, folders, webservices, console apps, scheduled tasks, windows services

### the environment model dsl :
    configuration
        settings
            environment -id 'local' -name
                settings
                node 'localhost' -id -name
                    resources -id -name -skipinstall -skipuninstall -tags
                    packages -id -name -skipinstall -skipuninstall -tags
            environment -id 'test' -name
                settings
                node -id 'webserver' -name
                    resources
                    packages
                node -id 'dbserver' -name
                    resources
            		package
					
### the basic node resources `.\modules\xtricate.build.model.nodes.resouces.psm1`
* remoting: configure the remote session for this node, used during remote installation
* certificate
* apppool
* localidentity
* website
* hostsfile 

### the basic node packages `.\modules\xtricate.build.model.nodes.packages.psm1`
* genericpackage
* webapppackage
* databasepackage
* systemtestpackage

### solution packages
packages in the model most often represent a project you are working on, to couple the model to a project location a 'solution.package.psm1' file is placed in the project folder. 
this file contains the id of the package in the model. 

> solutionpackage "demo.webapp" 

an alternative way to do the project coupling is by modifying the 'loadmodel' functions in the 'model' and 'modellocal' tasks. in this way no 'solution.package.psm1' has to be placed in the project folder. 

	loadmodel `
		-modelfile $modelfile `
		-environment $environment `
		-packagesPath $sources_dir `
		-solutionpackages {
			solutionpackage -packageid "demo.webservices" -name "demo.webservices" -location "$($sources_dir)\demo.webservices"
		}

## template expansion
the model serves as the basis for all kind of templating. templates are files which contain template functions and are expanded by executing the `template` or `templatelocal`
tasks. 
template expansion is not done on build or package time, the output folder with its packages does not contain expanded templates for each environment.
for examples: the various install tasks depend on the template tasks, so template expansion is executed when needed.  
all files ending with `.template` are expanded to files without this suffix. a web.config.template becomes a regular web.config this way.

### the basic template functions `.\modules\xtricate.build.template.functions.psm1`
all template functions are used like `[[templatefunction -params]]` in the template, regular powershell scripting is allowed too.

* getsetting
* getenvironment
* getnoderesource
* getnoderesources
* getnoderesourcepath
* getnodepackage
* getnodepackagepath
* getnodepackagename
* getnodepackageurl

### template examples

> connectionString="data source=[[fullpath (getnodepackagepath demo.db)]]\[[getnodepackagename demo.db]]"


> compilation debug="[[getsetting 'debug']]" targetFramework="4.0"

## local and remote project installation

the contents of the `.\build` folder contains everything needed for deployment on any node within an environment. 
starting with the following command to create the output packages :

> .\psake.cmd package

then manually copying the build folder to a node and executing :

> .\psake.cmd install

will install, according to the environment model, all applicable resources and packages on that node. 

or, let xtricate.build handle everything. building, copying and installation on a node can be done like this :

> .\psake.cmd remotepackageinstall -environment test -nodes dev-srv-1

## advanced usage examples
run the following commands from the `.\build` folder

> .\psake.cmd spectest -environment test -tags all

runs all spectest systemtestpackages within the `.\output` folder. the configuration templates are expanded for the specified environment, systemtests can be run anywhere.

## the demo solution uses the following tools and technologies :
* microsoft visual studio 2010
* microsoft asp.net mvc 3
* microsoft sql ce 4.0
* specflow 1.5
* watin 2.0
* nunit 2.5.7
* entityframework 4.1
* iis7 (webadministration module)
* **[nuget](http://nuget.org/List/Packages/xtricate.build)**

### some modules are based on work by:
* **[chewie](https://github.com/Ang3lFir3/Chewie)** : nuget package management
* **[soever](http://weblogs.asp.net/soever/archive/2006/12/31/a-templating-engine-using-powershell-expressions.aspx)** : powershell template engine
* **[poshcode.org](http://poshcode.org)** : various powershell scripts

xtricate.build contains a modified version of **[psake](http://github.com/JamesKovacs/psake)** by James Kovacs. some small
improvements in module loading were made.