function Show-Usage() {
    Write-Host "usage:
tp <alias_name>[/optional_relative_paths]
tp -<e|ex|exact> <alias_name> (slashes don't cause relative pathing)
tp -<s|set> <alias_name> <path> (overwrites if existing)
tp -<d|delete|remove> <alias1> [...] [...] (at least one required)
tp -rename <alias_name> <new_name>
tp -<list|ls|l>"
}

$arg0 = $args[0]
$otherargs = $args[1..($args.Length)]

if ($args.Length -eq 0) {
    Show-Usage | Out-Null
    Write-Host "-----"
    $arg0 = "-list" # how nice of us!
}

$arg0 = $arg0.ToString()

# MAIN FILE
$aliasFile = "$HOME\.tp_aliases"

$EXACTCMD_ALIASES = @(
    "-e",
    "-ex",
    "-exact"
)
$SETCMD_ALIASES = @(
    "-s",
    "-set",
    "-add" # NOTE - this might be a bit misleading because it overwrites, but i have muscle memory to type this lol
)
$LISTCMD_ALIASES = @(
    "-l",
    "-ls",
    "-list"
)
$DELCMD_ALIASES = @(
    "-d",
    "-delete",
    "-remove"
)

# if file doesnt exist create emptyt
if (-not (Test-Path $aliasFile)) {
    @() | Set-Content -Path $aliasFile
}

# load aliases
$aliases_to_paths = @{}
$rawtext = Get-Content -Path $aliasFile

foreach ($line in $rawtext) {
    $_line_split = $line -split " ",2
    if ($_line_split[0]) {
        $aliases_to_paths[$_line_split[0]] = $_line_split[1]
    }
}

# save: run on change (eg delete/set/rename)
# this is slow
function Save-Aliases() {
    $savefile_lines = [System.Collections.ArrayList]::new($aliases_to_paths.Count)
    foreach ($key in $aliases_to_paths.Keys) {
        $savefile_lines.Add("${key} $($aliases_to_paths[$key])")
    }

    if ($savefile_lines.Count -eq 0) {
        # using an empty array causes Set-Content to do nothing
        # have to clear the file another way
        Clear-Content -Path $aliasFile | Out-Null
    } else {
        $savefile_lines | Set-Content -Path $aliasFile | Out-Null
    }
}

# scuffed ik but whoever invented the cli argument format is a brick
switch ($arg0) {
    {$SETCMD_ALIASES.Contains($_)} {
        if ($otherargs.Length -ne 2) {
            Write-Host "usage: tp $($_) <aliasName> <path>"
            exit
        }
        $aliasName = $otherargs[0].ToString()
        $path = $otherargs[1].ToString()

        if ($aliasName.ToString().Contains(" ")) {
            Write-Host -ForegroundColor Red "error: " -NoNewline 
            Write-Host "aliases cannot contain space characters"
            exit
        }

        if (-not (Test-Path $path)) {
            Write-Host -ForegroundColor Yellow "warning: " -NoNewline 
            Write-Host "path '" -NoNewline 
            Write-Host -ForegroundColor Magenta $path -NoNewline 
            Write-Host "' doesn't exist"
        }

        if ($aliases_to_paths.ContainsKey($aliasName)) {
            Write-Host -ForegroundColor Green "Note: " -NoNewline 
            Write-Host "overwriting existing map of '" -NoNewline 
            Write-Host -ForegroundColor Blue $aliasName -NoNewline 
            Write-Host "' -> '" -NoNewline 
            Write-Host -ForegroundColor Magenta $aliases_to_paths[$aliasName] -NoNewline
            Write-Host "'"
        }
        
        $aliases_to_paths[$aliasName] = $path
        Write-Host "setting alias '" -NoNewline
        Write-Host -ForegroundColor Blue $aliasName -NoNewline 
        Write-Host "' -> '" -NoNewline 
        Write-Host -ForegroundColor Magenta $path -NoNewline
        Write-Host "'"

        if ($aliasName.ToString().Contains("/") -or $aliasName.ToString().Contains("\")) {
            Write-Host -ForegroundColor Green "hint: " -NoNewline 
            Write-Host "alias contains a slash character, which might be interpreted as a relative path. Use 'tp -<e|ex|exact> " -NoNewline
            Write-Host -ForegroundColor Blue $aliasName -NoNewline
            Write-Host "' for this alias or remove slashes."
        }

        Save-Aliases | Out-Null
    }

    {$DELCMD_ALIASES.Contains($_)} {
        if ($otherargs.Length -eq 0) {
            Write-Host "usage: tp $($_) <alias1> [alias2] [alias3] ... (at least one required)"
            exit
        }

        foreach ($aliasName in $otherargs) {
            $aliasName = $aliasName.ToString()
            if (-not $aliases_to_paths.ContainsKey($aliasName)) {
                Write-Host -ForegroundColor Green "note: " -NoNewline 
                Write-Host "not deleting nonexistent alias '" -NoNewline 
                Write-Host -ForegroundColor Blue ${aliasName} -NoNewline 
                Write-Host "'"
            } else {
                Write-Host "removing alias '" -NoNewline
                Write-Host -ForegroundColor Blue ${aliasName} -NoNewline
                Write-Host "' -> '" -NoNewline
                Write-Host -ForegroundColor Magenta $aliases_to_paths[$aliasName] -NoNewline
                Write-Host "'"
                $aliases_to_paths.Remove($aliasName)
            }
        }
        Save-Aliases | Out-Null
    }

    "-rename" {
        if ($otherargs.Length -ne 2) {
            Write-Host "usage: tp $($_) <aliasName> <newName>"
            exit
        }
        $aliasName = $otherargs[0].ToString()
        $newName = $otherargs[1].ToString()

        if (-not $aliases_to_paths.ContainsKey($aliasName)) {
            Write-Host -ForegroundColor Red "error: " -NoNewline
            Write-Host "alias '" -NoNewline
            Write-Host -ForegroundColor Blue $aliasName -NoNewline
            Write-Host "' does not exist and cannot be renamed"
            exit
        }
        if ($aliases_to_paths.ContainsKey($newName)) {
            Write-Host -ForegroundColor Red "error: " -NoNewline
            Write-Host "new name '" -NoNewline
            Write-Host -ForegroundColor Blue $newName -NoNewline
            Write-Host "' already exists (-> '" -NoNewline
            Write-Host -ForegroundColor Magenta $aliases_to_paths[$newName] -NoNewline
            Write-Host "')"
            exit
        }

        $aliases_to_paths[$newName] = $aliases_to_paths[$aliasName]
        $aliases_to_paths.Remove($aliasName)
        Save-Aliases | Out-Null

        if ($aliasName.ToString().Contains("/") -or $aliasName.ToString().Contains("\")) {
            Write-Host -ForegroundColor Green "hint: " -NoNewline
            Write-Host "alias contains a slash character, which might be interpreted as a relative path. Use 'tp -<e|ex|exact> " -NoNewline
            Write-Host -ForegroundColor Blue $aliasName -NoNewline
            Write-Host "' for this alias or remove slashes."
        }

        Write-Host "alias '" -NoNewLine
        Write-Host -ForegroundColor Blue $aliasName -NoNewLine
        Write-Host "' successfully renamed to '" -NoNewLine
        Write-Host -ForegroundColor Blue $newName -NoNewLine
        Write-Host "'"
    }

    {$LISTCMD_ALIASES.Contains($_)} {
        # find maxlen of key to justify all of the paths text
        $maxlen = 0
        foreach ($key in $aliases_to_paths.Keys) {
            $maxlen = [math]::Max($maxlen, "$key".Length)
        }

        if ($aliases_to_paths.Count -eq 0) {
            Write-Host "no aliases defined yet"
        } else {
            if ($aliases_to_paths.Count -eq 1) {
                Write-Host "1 alias defined:"
            } else {
                Write-Host "$($aliases_to_paths.Count) aliases defined:"
            }

            $sorted_keys_aliases = $aliases_to_paths.Keys | Sort-Object
            foreach ($key in $sorted_keys_aliases) {
                $just = "{0,-${maxlen}}" -f "$key"
                Write-Host -ForegroundColor Blue $just -NoNewLine
                Write-Host " -> " -NoNewline
                Write-Host -ForegroundColor Magenta $($aliases_to_paths[$key])
            }
        }
    }

    # tp to exactly the string passed in, even if it contains slashes
    {$EXACTCMD_ALIASES.Contains($_)} {
        if (($otherargs.Length -ne 1)) {
            Show-Usage | Out-Null
            exit
        }

        $exactalias = $otherargs[0]

        if (-not $aliases_to_paths.ContainsKey($exactalias)) {
            Write-Host -ForegroundColor Red "error: " -NoNewline
            Write-Host "alias '" -NoNewLine
            Write-Host -ForegroundColor Blue $exactalias -NoNewLine
            Write-Host "' doesn't exist"
            exit
        }

        $path = $aliases_to_paths[$exactalias]
        if (-not (Test-Path $path)) {
            Write-Host -ForegroundColor Red "error: " -NoNewline
            Write-Host "alias '" -NoNewline
            Write-Host -ForegroundColor Blue $exactalias -NoNewline
            Write-Host "' points to nonexistent path '" -NoNewline
            Write-Host -ForegroundColor Magenta $path -NoNewline
            Write-Host "'"
        } else {
            Set-Location -Path $path
        }
    }

    # tp to the alias passed in but delimit using "/" or "\" and apply relative paths
    default {
        if (($otherargs.Length -ne 0) -or ($arg0.ToString().StartsWith("-"))) {
            Show-Usage | Out-Null
            exit
        }

        $base_alias, $rel_path = ($arg0 -split "[/\\]",2)

        if (-not $aliases_to_paths.ContainsKey($base_alias)) {
            Write-Host -ForegroundColor Red "error: " -NoNewline
            Write-Host "alias '" -NoNewLine
            Write-Host -ForegroundColor Blue $base_alias -NoNewLine
            Write-Host "' doesn't exist"
            exit
        }

        $basepath = $aliases_to_paths[$base_alias]
        $truepath = Join-Path -Path $basepath -ChildPath $rel_path

        if (-not (Test-Path $truepath)) {
            Write-Host -ForegroundColor Red "error: " -NoNewline
            Write-Host "path '" -NoNewLine
            Write-Host -ForegroundColor Blue $base_alias -NoNewLine
            Write-Host -ForegroundColor Magenta "/${rel_path}" -NoNewLine
            Write-Host "' does not exist (resolved to '" -NoNewLine
            Write-Host -ForegroundColor Magenta $truepath -NoNewLine
            Write-Host "')"
        } else {
            Set-Location -Path $truepath
        }
    }        
}
