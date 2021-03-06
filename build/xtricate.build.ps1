properties {
    $branch="master"
    $name="$(buildname).$($branch)"
    $build_dir="."
    $base_dir=".."
    $sources_dir="$base_dir\src"
    $output_dir="$build_dir\output\$name"
    $tools_dir="$build_dir\tools"
    $build_version=datetimeversion 0 20 2010
}

Task init {
    Write-Host "executing build script: $($psake.build_script_file)"
    Write-Host "properties.name: $name, properties.build_version: $build_version"
}

Task default -depends init, package

Task clean -depends init {
    removefolder $output_dir
    removefolder bin -recurse -root $sources_dir
    removefolder obj -recurse -root $sources_dir
	ensurefolder $output_dir
	Write-Host $build_version
}

Task package -depends clean {
    exportnugetpackages `
        -path $base_dir `
        -targetpath $output_dir `
        -toolsdir $tools_dir 
}

Task publish -depends package {
    pushnugetpackages `
        -path $output_dir `
        -accesskey $env:nugetaccesskey `
        -toolsdir $tools_dir -publish `
}

