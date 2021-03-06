$framework = '4.0x86'

properties {
    $branch="master"
    $name="$(buildname).$($branch)"
    $environment="LOCAL"
	$build_dir="."
    $base_dir=".."
    $buildconfig="Debug"
    $out_dir="bin"
    $output_dir="$build_dir\output\$name"
    $sources_dir="$base_dir\src"
    $tools_dir="$build_dir\tools"
    $libs_dir="$base_dir\lib"
    $modelfile=resolvedefaultmodel #$environment
    $build_version=datetimeversion 0 6 2010
	$build=build{solution "web" "$sources_dir\demo.web.sln" -dependson "core"
				 solution "core" "$sources_dir\demo.sln"}
	$build_solutions=$build.solutions()
	#$build_solutions=solution "core" (firstsolution $sources_dir)
    $nodes=$null
	$tags=$null
}

task init {
    #resetlogger "$name"
    Write-Host "executing build script: " (Get-RelativePath (fullpath $build_dir) $psake.build_script_file)
    Write-Host "properties.name: $name, properties.build_version: $build_version"
	$build_solutions | foreach { Write-Host "resolved solution: $($_.path) [$($_.id)]"  }
}

task default -depends init, package

task clean -depends init {
    cleansolutions $build_solutions
    removefolder $output_dir
    removefolder $out_dir -recurse -root $sources_dir
	removefolder obj -recurse -root $sources_dir
	ensurefolder $output_dir
    # todo : remove all expanded templates from $sources_dir
}

task assemblyinfo -depends init {
	try{$commit=(git log -1 --pretty=format:%H)} catch{}
	
	assemblyinfo `
        "$sources_dir\demo.app\properties\assemblyinfo.cs", 
        "$sources_dir\demo.webapp\properties\assemblyinfo.cs",
        "$sources_dir\demo.webservices\properties\assemblyinfo.cs" `
        -title "xtricate.build demo" -description "xtricate.build demo description" `
        -company "" -product "xtricate.build demo $build_version" `
        -copyright "vip32 2010 - 2011" -clscompliant "false" `
		-version $build_version -commit $commit
}

task updatelib -depends init {
    lib {
        toolsdir (fullpath $tools_dir)
        installto $libs_dir
        package 'common.logging' '2.0.0'
        package 'common.logging.log4net' '2.0.0'
        package 'commonservicelocator' '1.0'
        package 'nunit' '2.5.7.10213'
        package 'structuremap' '2.6.1.0'
        package 'watin' '2.0.50'
        package 'specflow' '1.5.0'
        package 'entityframework' '4.1.10311.0'
        package 'sqlservercompact' '4.0.8482.1'
		# extra xtricate.build packages
		#package 'xtricate.build.model.sharepoint2010' -contentcopy '$build_dir\modules'
		#package 'xtricate.build.documentation' -contentcopy '$build_dir\modules' -toolscopy '$build_dir\tools'
    }
}

task compile -depends init, clean, assemblyinfo, updatelib {
	#if(Find-Path iisreset.exe){ iisreset.exe | out-null }# todo : sqlce4 refs locked
	iisreset.exe | out-null
	buildsolutions `
		-solutions $build_solutions `
		-outdir $out_dir `
		-buildconfig $buildconfig
}

task unittest -continueonerror -depends init {
    runtestpackages `
		-outdir $out_dir -toolsdir $tools_dir `
		-sourcesdir $sources_dir -assemblypattern "*.unittests.dll"
}

# runs all systemtestpackages in the package output folder (run 'package' task before or on remote env)
task integrationtest -continueonerror -depends init, template {
    runtestpackages `
		-outdir $out_dir -toolsdir $tools_dir `
		-assemblypattern "*.integrationtests.dll"
}

# runs all systemtestpackages in the package output folder (run 'package' task before or on remote env)
task spectest -continueonerror -depends init, template {
	runtestpackages `
		-outdir $out_dir -toolsdir $tools_dir `
		-assemblypattern "*.specs.dll"
}

task package -depends init, modellocal, compile {
    exportpackages `
        -path $output_dir `
        -packages $psake.build_solution_packages
        
#    exportnugetpackages `
#        -path $base_dir `
#        -targetpath $output_dir `
#        -toolsdir $tools_dir `
}

task modellocal -depends init { 
   loadmodel `
        -modelfile $modelfile `
        -environment $environment `
        -packagesPath $sources_dir `
		-solutionpackages {
			solutionpackage -packageid "demo.webservices" -name "demo.webservices" -location "$($sources_dir)\demo.webservices"
		}
}

task model -depends init { 
   loadmodel `
        -modelfile $modelfile `
        -environment $environment `
        -packagesPath $output_dir `
		-solutionpackages {
			solutionpackage -packageid "demo.webservices" -name "demo.webservices" -location "$($output_dir)\demo.webservices"
		}
}

task templatelocal -depends init, modellocal {
    expandtemplates `
        -packages $psake.build_solution_packages
}

task template -depends init, model {
    expandtemplates `
        -packages $psake.build_solution_packages
}

task packageinstall -depends init, package, install {
    # .\psake.cmd -tasks 'package,install'
}

task install -depends init, template { 
    installenvironment `
        -environment $psake.build_configuration_environment `
        -path $output_dir -tags $tags
}

# .\psake.cmd package
# .\psake.cmd remoteinstall -environment TEST -nodes "dev-srv-1,dev-srv-2"
task remoteinstall -depends init, model  { #-depends package
    installremoteenvironment `
        -environment $psake.build_configuration_environment `
        -nodes $nodes -name $name -tags $tags
}

# .\psake.cmd remotepackageinstall -environment TEST -nodes "dev-srv-1,dev-srv-2"
task remotepackageinstall -depends init, package, model, pushremote  { 
    installremoteenvironment `
        -environment $psake.build_configuration_environment `
		-nodes $nodes -name $name -tags $tags `
        -skipcopy
}

task uninstall -depends init, template { 
    uninstallenvironment `
        -environment $psake.build_configuration_environment `
        -path $output_dir -tags $tags
}

# .\psake.cmd remoteuninstall -environment TEST -nodes "dev-srv-1,dev-srv-2"
task remoteuninstall -depends init, model  { #-depends package
}

task packageuninstall -depends init, uninstall {
    # .\psake.cmd -tasks 'package,uninstall'
}

# .\psake.cmd pushremote -environment TEST -nodes "dev-srv-1,dev-srv-2"
task pushremote -depends init,  model   {  #package,
    installremoteenvironment `
        -environment $psake.build_configuration_environment `
		-nodes $nodes -name $name -tags $tags `
        -skipinstall
}

task pushdroplocation -depends init, package {
    # todo : push build output (export) folder to drop location
    #pushbuild  `
    #    -path $build_dir `
    #    -targetpath `
    #    -name $name `
    #    -version $build_version `
    #    -zip

    pushnugetpackages `
        -path $output_dir `
        -accesskey $env:nugetaccesskey `
        -toolsdir $tools_dir `
    }

task list -depends init, package, {
    # todo : environment overview
}

# ================================================================
# TODO : move below to module
# ================================================================
task smoketest -continueonerror -depends model {
	foreach($node in $nodes) {
		$processed=$false
	    foreach($modelnode in $psake.build_configuration_environment.nodes()){
			if(comparenodes $node $modelnode.name){
		        Write-Host "node: $($modelnode.name) [$($modelnode.id)] $($node)`n"
				
				if(Get-Member -InputObject $modelnode -Name SmokeTest -MemberType ScriptMethod){ 
		            $modelnode.SmokeTest($node)
		        }
				
		        Get-Resources-TopologicalSort $modelnode.resources() | foreach {
		            foreach($resource in $modelnode.resources()) { 
		                if($resource.type -eq $_){ 
		                    if(comparetags $tags $resource.tags){ 
		                        if(Get-Member -InputObject $resource -Name SmokeTest -MemberType ScriptMethod){ 
		                            $resource.SmokeTest($node) 
		                        }
		                    }
		                }
		            }
		        }
		        Get-Packages-TopologicalSort $modelnode.packages() | foreach {
		            foreach($package in $modelnode.packages()) { 
		                if($package.id -eq $_){ 
		                    if(comparetags $tags $package.tags){ 
		                        if(Get-Member -InputObject $package -Name SmokeTest -MemberType ScriptMethod){ 
		                            $package.SmokeTest($node) 
		                        }
		                    }
		                }
		            }
		        }
				$processed=$true
			}
		}
		if(!$processed) {Write-Warning "node $node not found in model"}
    }
}

task documentation -depends model {
    # http://www.graphviz.org/pdf/dotguide.pdf
    # http://www.graphviz.org/doc/info/attrs.html#d:aspect
    ensurefolder $output_dir
    $doc = $psake.build_configuration_environment.documentation($tags) 

    $graph = "digraph ""$name [$($psake.build_configuration_environment.id)]"" {`n"
    $graph += "	 graph [fontsize=20 labelloc=""t"" label=""$($psake.build_configuration_environment.name) [$($psake.build_configuration_environment.id)]\n$($name)"" splines=true overlap=false rankdir = ""TB""]`n"
	$graph += "   size = 25; ratio = auto;`n"
#	$graph += "  subgraph clustertje {`n"
#	$graph += "    ""template\n[packageid]"" [shape=parallelogram,color=cyan4];`n"
#	$graph += "    subgraph cluster {`n label=""resources""`n ""resource\n[id]"" [shape=hexagon,style=filled,fillcolor=darkgoldenrod1];`n"
#   $graph += "                               ""resource2\n[id2]"" [shape=hexagon,style=filled,fillcolor=darkgoldenrod1];`n}`n"
#	$graph += "    ""package\n[id]"" [shape=box,style=filled,fillcolor=darkolivegreen1];`n"
#   $graph += "    ""package2\n[id2]"" [shape=box,style=filled,fillcolor=darkolivegreen1];`n"
#	$graph += "	   ""package\n[id]"" -> ""resource\n[id]"" [penwidth=3,color=darkolivegreen3,label=uses];"
#	$graph += "	   ""package\n[id]"" -> ""template\n[packageid]"" [penwidth=2,color=cyan4,style=dashed,label=contains];"
#   $graph += "	   ""template\n[packageid]"" -> ""package2\n[id2]"" [penwidth=2,color=cyan4,label=template];"
#   $graph += "    label = ""node"";`n"
#   $graph += "  }`n"
    $pc = 0
    $psake.build_configuration_environment.nodes() | foreach { 
            $graph += "  subgraph cluster$($_.id) {`n"
            $graph += "    label=""$($_.id) [$($_.name)]""`n"
            $graph += "    subgraph clusterresources$($_.id) {`n"
            #$graph += "    style=filled;`ncolor=gray93`n"
            $graph += "    label=""resources""`n"
            foreach($resource in $_.resources()) { 
                $idprop = (Get-Member -InputObject $resource -MemberType NoteProperty -Name "id")
                $refprop = (Get-Member -InputObject $resource -MemberType NoteProperty -Name "*ref")
                $idvalue = $($resource.$($idprop.name))
                # resource
                $graph += "    ""$idvalue"" [shape=hexagon,style=filled,fillcolor=darkgoldenrod1,label=""$($resource.type)\n[$($idvalue)]""];`n"
                
                # resource -> resource refs
                $refprop | foreach { 
                        $refvalue = $($resource.$($_.name))
                        $reftype = $($resource.type)
                        if(NotNullOrEmpty $refvalue){ $graph += "    ""$($idvalue)"" -> ""$($refvalue)"" [penwidth=3,color=darkgoldenrod3,label=depends];`n" }
                    }
            }
            $graph += "    }`n" # resources subgraph
            
            foreach($package in $_.packages()) { 
                $idprop = (Get-Member -InputObject $package -MemberType NoteProperty -Name "id")
                $refprop = (Get-Member -InputObject $package -MemberType NoteProperty -Name "*ref")
                $idvalue = $($package.$($idprop.name))
                # package
                $graph += "    subgraph clusterpackage$($pc) {`n label=""$($package.type)""`n"
                #$graph += "     style=filled;`ncolor=gray93`n"
                $graph += "     ""$idvalue"" [width=3,height=1.2,shape=folder,style=filled,fillcolor=darkolivegreen1,label=""$($package.type)\n[$($idvalue)]""];`n"
                # package -> resource refs
                $refprop | foreach { 
                        $refvalue = $($package.$($_.name))
                        if(NotNullOrEmpty $refvalue){ $graph += "    ""$($idvalue)"" -> ""$($refvalue)"" [penwidth=4,color=darkolivegreen3,label=uses];`n" }
                    }
                # package -> template file
				$psake.build_solution_packages | foreach { 
			        foreach($template in Get-ChildItem $_.location -Include "*.template" -Recurse){
						if($package.id -eq $_.packageid){
							$graph += "    ""$($template.name)\n[$($package.id)]"" [shape=parallelogram,color=cyan4];`n"
				            $graph += "    ""$($_.packageid)"" -> ""$($template.name)\n[$($package.id)]"" [penwidth=2,color=cyan4,style=dashed,label=contains];`n"
						}
			        }
			    }
                $graph += "  }`n"    # package subgraph
                $pc += 1
                
            }
            $graph += "  }`n"    # node subgraph
    }
    
    # template files -> node packages 
    $psake.build_configuration_environment.nodes() | foreach { 
        foreach($package in $_.packages()) { 
            $psake.build_solution_packages | foreach { 
                foreach($template in Get-ChildItem $_.location -Include "*.template" -Recurse){
                    if($package.id -eq $_.packageid){
                        $expressions = Template-Expand -path $template.fullname -skipexpand:$true 
                        foreach($expression in $expressions){
                            $expression -split " " | % { 
                                if(NotNullOrEmpty $_) {
                                    #$noderesource = Get-NodeResource -resourceid $_ -throwerror:$false
                                    $nodepackage = Get-NodePackage -packageid $_ -throwerror:$false
                                    #if($noderesource -ne $null){ $graph += " ""$_"" -> ""$($template.name)\n[$($package.id)]"""}
                                    if($nodepackage -ne $null){ $graph += " ""$($template.name)\n[$($package.id)]"" -> ""$_"" [penwidth=2,color=cyan4,label=""template\n[$($expression)]""];`n"}
                                }
                            }
                        }
                    }
                }
           }
        }
    }
    
    
    $graph += "}"
    
    $filename = Join-Path $output_dir "$($name).$($environment.tolower()).html"
    $filename2 = Join-Path $output_dir "$($name).$($environment.tolower()).svg"
    Write-Host "documentation output: $filename" 
    #Write-Host "graph output: $filename2" 
    Out-File -FilePath $filename -Force -InputObject $doc
    #Out-File -FilePath $filename2 -Force -InputObject $graph
    Write-Host $graph
    $graph | & '.\tools\graphviz\bin\dot.exe' -Tsvg -o $filename2
}