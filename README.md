# teleport
Overly formatted and colorful powershell utility for cd'ing into specific places

<img width="830" height="382" alt="image" src="https://github.com/user-attachments/assets/b6624e30-c841-417a-b1a3-f91f38576c81" />

### Usage
```
tp <alias_name>[/optional_relative_paths]
tp -<e|ex|exact> <alias_name> (slashes don't cause relative pathing)
tp -<s|set> <alias_name> <path> (overwrites if existing)
tp -<d|delete|remove> <alias1> [...] [...] (at least one required)
tp -rename <alias_name> <new_name>
tp -<list|ls|l>"
```
