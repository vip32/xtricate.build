src\demo* demonstrates a buildable and deployable solution using these xtricate.build extensions

xtricate.build features : 
* environment management
* nuget package management
* solution build
* configuration and script templating
* output packaging
* local and remote deployment
* html and diagram documentation

how can i use xtricate.build in my projects :
* copy the build folder to the root of your branch. 
* create a default.ps1 specfic for your project, modify the properties.
* create a default.model.ps1 specific for your environment.
* run psake.cmd with the appropriate task.

the demo solution uses the following technologies :
* microsoft visual studio 2010
* microsoft asp.net mvc 3
* microsoft sql ce 4.0

some modules are based on work by:
* ang3lfir3/chewie : nuget package management

xtricate.build contains a modified version of psake by James Kovacs. some small
improvements in module loading were made.
