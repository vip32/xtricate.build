function Expand-Templates{
    param(
        [object] $packages
    )
    Write-Host "environment:$($psake.build_configuration_environment.id)"
    $packages | foreach { 
        foreach($template in Get-ChildItem $_.location -Include "*.template" -Recurse){
            expandtemplate `
                -file $template
        }
    }
}
New-Alias -Name ExpandTemplates -value Expand-Templates -Description "" -Force

function Expand-Template{
    param(
        [object] $file = $(throw "file is a required parameter.")
    )
    Template-Expand -path $file -destination $file.fullname.replace(".template", "")
}
New-Alias -Name ExpandTemplate -value Expand-Template -Description "" -Force

# Template-Expand
# Simple templating engine to expand a given template text containing PowerShell expressions.
#
# Arguments:
# $text (optional): The text of the template to do the expansion on (use either $text or $path)
# $path (optional): Path to template to do the expansion on (use either $text or $path)
# $destination (optional): Destination path to write expansion result to. If not specified, the
#                           expansion result is result as text
# $psConfigurationPath (optional) : Path to file containing PowerShell code. File will be 
#                                   sources using ". file", so variables can be declared 
#                                   without global scope
# $leftMarker (optional): Left marker for detecting expand expression in template
# $rightMarker (optional): Right marker for detecting expand expression in template
# $encoding (optional): Encoding to use when reading the template file
#
# Simple usage usage: 
# $message="hello"; ./Template-Delegate -text 'I would like to say [[$message]] to the world'
function Template-Expand
{
	param (
		$text = $null,
		$path = $null,
		$destination = $null,
		$psConfigurationPath = $null,
		$leftMarker = "\[\[",
		$rightMarker = "]]",
        $errorLeftMarker = "-->[[",
        $errorRightMarker = "]]<--",
		$Encoding = "UTF8",
		$skipexpand = $false
	)
	
	if ($path -ne $null)
	{
		if (!(Test-Path -Path $path))
		{
			throw "Template-Expand: path `'$path`' can't be found"
		}
        $relpath = Get-RelativePath (fullpath .) $path
        Write-Host "expand: $relpath"
		# Read text and join the returned Object[] with newlines
		$text = [string]::join([environment]::newline, (Get-Content -Path $path -Encoding $Encoding))
	}

	if ($text -eq $null)
	{
		throw 'Template-Expand: template to expand should be specified through -text or -path option'
	}

	if ($psConfigurationPath -ne $null)
	{
		# Source the powershell configuration, so we don't have to declare variables in the 
		# configuration globally
		if (!(Test-Path -Path $psConfigurationPath))
		{
			throw "Template-Expand: psConfigurationPath `'$psConfigurationPath`' can't be found"
		}
		. $psConfigurationPath
	}

	$pattern = New-Object -Type System.Text.RegularExpressions.Regex `
						-ArgumentList "$leftMarker(.*?)$rightMarker",([System.Text.RegularExpressions.RegexOptions]::Singleline)

	if($skipexpand){
		$result = @()
		$matched = [regex]::Matches($text, $pattern)
		$matched | foreach { $result += ($_ -replace $leftMarker -replace $rightMarker) }
		return $result
	}

	#return
	$matchEvaluatorDelegate = GetDelegate `
		System.Text.RegularExpressions.MatchEvaluator {
			$match = $args[0]
			$expression = $match.get_Groups()[1].Value # content between markers
			trap { 
                Write-Host "Expansion on template `'$path`' failed. Can't evaluate expression `'$expression`'. The following error occured: $_" -ForegroundColor Red
                #   ^^^^ write-error
                "$errorLeftMarker $expression $errorRightMarker"
                continue 
            }
			Invoke-Expression -command $expression
		}

	# Execute the pattern replacements and return the result
	$expandedText = $pattern.Replace($text, $matchEvaluatorDelegate)
	if ($destination -eq $null)
	{
		# Return as string
		$expandedText 
	}
	else
	{
        Write-Verbose "target:$destination`n"
        if(Test-Path $destination){ Set-ItemProperty $destination -name IsReadOnly -value $false}
		Set-Content -Path $destination -value $expandedText -encoding $Encoding
	}
}

# Template-Expand
# Simple templating engine to expand a given template text containing PowerShell expressions.
#
# Arguments:
# $text (optional): The text of the template to do the expansion on (use either $text or $path)
# $path (optional): Path to template to do the expansion on (use either $text or $path)
# $destination (optional): Destination path to write expansion result to. If not specified, the
#                           expansion result is result as text
# $psConfigurationPath (optional) : Path to file containing PowerShell code. File will be 
#                                   sources using ". file", so variables can be declared 
#                                   without global scope
# $leftMarker (optional): Left marker for detecting expand expression in template
# $rightMarker (optional): Right marker for detecting expand expression in template
# $encoding (optional): Encoding to use when reading the template file
#
# Simple usage usage: 
# $message="hello"; ./Template-Delegate -text 'I would like to say [[$message]] to the world'

# Helper function to emit an IL opcode
function emit
{
    param
    (
        $opcode = $(throw "Missing: opcode")
    )
    
    if ( ! ($op = [System.Reflection.Emit.OpCodes]::($opcode)))
    {
        throw "emit: opcode '$opcode' is undefined"
    }

    if ($args.Length -gt 0)
    {
        $ilg.Emit($op, $args[0])
    }
    else
    {
        $ilg.Emit($op)
    }
}

function GetDelegate
{
    param
    (
        [type]$type, 
        [ScriptBlock]$scriptBlock
    )

    # Get the method info for this delegate invoke...
    $delegateInvoke = $type.GetMethod("Invoke")
    
    # Get the argument type signature for the delegate invoke
    $parameters = @($delegateInvoke.GetParameters())
    $returnType = $delegateInvoke.ReturnParameter.ParameterType
    
    $argList = new-object Collections.ArrayList
    [void] $argList.Add([ScriptBlock])
    foreach ($p in $parameters)
    {
        [void] $argList.Add($p.ParameterType);
    }
    
    $dynMethod = new-object reflection.emit.dynamicmethod ("",
        $returnType, $argList.ToArray(), [object], $false)
    $ilg = $dynMethod.GetILGenerator()
    
    # Place the scriptblock on the stack for the method call
    emit Ldarg_0
    
    emit Ldc_I4 ($argList.Count - 1)  # Create the parameter array
    emit Newarr ([object])
    
    for ($opCount = 1; $opCount -lt $argList.Count; $opCount++)
    {
        emit Dup                    # Dup the array reference
        emit Ldc_I4 ($opCount - 1); # Load the index
        emit Ldarg $opCount         # Load the argument
        if ($argList[$opCount].IsValueType) # Box if necessary
     {
            emit Box $argList[$opCount]
     }
        emit Stelem ([object])  # Store it in the array
    }
    
    # Now emit the call to the ScriptBlock invoke method
    emit Call ([ScriptBlock].GetMethod("InvokeReturnAsIs"))
    
    if ($returnType -eq [void])
    {
        # If the return type is void, pop the returned object
        emit Pop
    }
    else
    {
        # Otherwise emit code to convert the result type which looks
        # like LanguagePrimitives.ConvertTo(value, type)
    
        $signature = [object], [type]
        #$convertMethod =
        #    [Management.Automation.LanguagePrimitives].GetMethod(
        #        "ConvertTo", $signature);
		$convertMethod = [Management.Automation.LanguagePrimitives].GetMethod("ConvertTo", [Type[]]$signature);
        $GetTypeFromHandle = [Type].GetMethod("GetTypeFromHandle");
        emit Ldtoken $returnType  # And the return type token...
        emit Call $GetTypeFromHandle
        emit Call $convertMethod
    }
    emit Ret
    
    #
    # Now return a delegate from this dynamic method...
    #
    
    $dynMethod.CreateDelegate($type, $scriptBlock)
}

Export-Modulemember -alias * -Function *