function Show-Usage() {
    Write-Host "usage:
tp <aliasName>
tp -set <aliasName> <path>
tp -<delete|remove> <alias1> [...] [...] (at least one required)
tp -rename <aliasName> <newName>
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

$SETCMD_ALIASES = @(
    "-set",
    "-add" # NOTE - this might be a bit misleading because it overwrites, but i have muscle memory to type this lol
)
$LISTCMD_ALIASES = @(
    "-list",
    "-ls",
    "-l"
)
$DELCMD_ALIASES = @(
    "-delete",
    "-d",
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

    default {
        if (($otherargs.Length -ne 0) -or ($arg0.ToString().StartsWith("-"))) {
            Show-Usage | Out-Null
            exit
        }

        if (-not $aliases_to_paths.ContainsKey($arg0)) {
            Write-Host -ForegroundColor Red "error: " -NoNewline
            Write-Host "alias '" -NoNewLine 
            Write-Host -ForegroundColor Blue $arg0 -NoNewLine 
            Write-Host "' doesn't exist"
            exit
        }

        $path = $aliases_to_paths[$arg0]
        if (-not (Test-Path $path)) {
            Write-Host -ForegroundColor Red "error: " -NoNewline
            Write-Host "alias '" -NoNewline
            Write-Host -ForegroundColor Blue $arg0 -NoNewline
            Write-Host "' points to nonexistent path '" -NoNewline
            Write-Host -ForegroundColor Magenta $path -NoNewline
            Write-Host "'"
        } else {
            Set-Location -Path $path
        }
    }        
}
