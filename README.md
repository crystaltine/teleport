# teleport
Overly formatted and colorful powershell utility for cd'ing into specific places!

<img width="1000" height="auto" alt="teleport preview" src="https://github.com/user-attachments/assets/384c33e7-d7d6-4d6c-8209-1f0beb9f31db" />

### Usage
```
tp <alias_name>[/optional_relative_paths]
tp -<e|ex|exact> <alias_name> (slashes don't cause relative pathing)
tp -<s|set> <alias_name> <path> (overwrites if existing)
tp -<d|delete|remove> <alias1> [...] [...] (at least one required)
tp -rename <alias_name> <new_name>
tp -<list|ls|l>"
```
