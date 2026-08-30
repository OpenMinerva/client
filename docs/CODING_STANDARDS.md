# Coding Standards

This is a living document that will change and update as the project grows. Please check back every so often to ensure you are using the latest version of this document.
If this document changes while you are working on a pull request, it is expected that you will change your pull request to meet the requirements of the most recent, active CODING_STANDARDS.md. 

## Formatting

### License Headers
All files should have a license header with information about the file at the very top. If you are creating a new file, you can simply copy and paste a header from any other file and update all of the information.
Otherwise, this is a template you can quickly paste into the file.
```gdscript
# --- License
# File: /client/src/.../CHANGE_ME.gd
# Project: OpenMinerva
# Created Date: 16 April 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
```

> [!IMPORTANT] 
> File: Must always start with /client/src/
> Created Date: The date when the file was first committed to the git repository. (DD MMMM YYYY)
> Copyright: Must be updated to the correct year whenever a change is made to the file. If the file says "2026", but you make a change in "2027", the file should be updated to reflect a copyright year in "2027".

## Naming Conventions
### Quick Reference
| Type | Convention | Example |
| ---- | ---------- | ------- |
| Variables         | `snake_case`       | `player_count`           |
| Private vars      | `_snake_case`      | `_session_db`            |
| Functions         | `snake_case`       | `join_server()`          |
| Private functions | `_snake_case`      | `_log_to_file()`         |
| Classes           | `PascalCase`       | `NetworkManager`         |
| Node Names        | `PascalCase`       | `PortScanner`         |
| Constants         | `CONSTANT_CASE`   | `MAX_CLIENTS`            |
| Signals           | `snake_case`       | `session_joined`         |
| Enums             | `PascalCase`       | `Enum.LogLevel.DEBUG`    |
| File names        | `snake_case`       | `network_manager.gd`     |

### Signals
Always use the `.emit()` syntax, never use `emit_signal()`

```gdscript
# ✅ Good
Events.dash_session_changed.emit(session_id)

# ❌ Bad
Events.emit_signal("dash_session_changed", session_id)
```
## Structure
### File Structure
Files should be stored in directories that make sense and can easily be found.
Several application managers are split into smaller, library-like child nodes. This can be thought of similar to "components" in other game engines, but instead the functionality of the "component" requires an additional node.

Here is an example of the in-editor layout of the Network Manager nodes for the application.
```
- NetworkManager
    - PortScanner
    - Registry
    - Advertiser
```

To replicate the intended file structure, all of these files should match their corresponding node names, converted to `snake_case`.
The file name on disk should be in `snake_case` while the node names should be in `PascalCase`.
All of the files related to the NetworkManager node should live in the same directory as the orchestrator node `network_manager.gd`

### Coding Structure
#### Logging
In a majority of functions, logging should be included at the beginning and/or end of the function.
For the majority of these logging functions, it is often not necessary to increase the log level up from `debug`. Debug logging functions are intended only for development or for tracking down bugs.
Debug logs do not require an explicit level parameter; it is acceptable to not include the level in a debug log.

```gdscript
# ✅ Good 
GlobalLogger.log("Debug Log")
GlobalLogger.log("Debug Log", Enum.LogLevel.DEBUG)
GlobalLogger.log("Warning Log!", Enum.LogLevel.WARNING)

# ❌ Bad
print("Debug Log") # Do not use `print()`
```

#### Type Safety
Always use type safe variables wherever possible. The type must be as specific as possible. This is so that errors or invalid variable values are caught as early as possible.
```gdscript
# ✅ Good 
var _my_id: int = 1
var _node_database: Array[Dictionary] = []

# ❌ Bad
var test_variable = "6"
const MAGIC_NUMBER = 52
```

#### Documentation and Comments
Try to avoid useless or redundant comments. The goal is to write self-explanatory enough code that comments are unnecessary.
The primary documentation provider for this project is the Godot supported [Documentation Comments](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html). It is necessary to write descriptive comments here so that the intention of the functions, parameters, or variables is crystal clear.


## Testing Requirements
Before making a commit, you should test your changes by launching the application and testing your new feature. While testing you should monitor the logs to make sure there are no new errors caused by your changes.
When making a pull request, your final commit before being submitted should not introduce any new errors. Do not defer fixes; all logged issues must be resolved before sent for review.
## Commits and Messages
### Branch Names
- Branch names should be targeted and descriptive to the contents of the pull request.
- Use an appropriate branch type.

| Branch Type | Intention |
| ----------- | --------- |
| feature     | A new feature to be added to the project |
| fix         | Bug or issue fix for an existing issue   |
| hotfix      | Urgent issue resolution to a release     |
| refactor    | Code restructuring without changes to the functionality |
| docs        | Documentation changes only |
| chore       | Routine maintainance, addon updates |
| test        | Adding or improving tests |
| revert      | Rolling back to a previous commit or pull request |

- Separate branch type with a slash (`/`), and use hyphens (`-`) to separate words:
    - `fix/spawn-manager-database-id`:
        - `fix/` - Explicitly states that this pull request is a fix.
        - `spawn-manager-database-id` - States the target or scope of the pull request.
    - `feature/new-rendering-method`:
        - `feature/` - This pull request is adding a new feature.
        - `new-rendering-method` - Explicitly states the new intended feature being added.

```gdscript
# ✅ Good
- fix/spawn-manager-database-id
- feature/new-rendering-method
- feature/links-to-readme
- fix/issue-23

# ❌ Bad
- looks-better                      # What looks better? "Looks better" is also subjective.
- issue-resolve                     # What issue was resolved?
- fix/hotfix-for-new-issue          # What issue?
```


### Commits
Commits should be small and targeted. For large projects, there should be dozens of smaller commits that make up the larger change in the pull request. In simpler words: make many small commits.
Small commits make your pull request easier to follow, and will speed up code review time significantly. Failure to abide by this can be, although unlikely, grounds for a rejected pull request by itself.

### Commit Messages
Commit messages should likewise be detailed about what was changed, and what the intention of that change was. Aim for ~2 sentences per commit message.
Bullet point commit messages documenting changes and intentions are acceptable!
