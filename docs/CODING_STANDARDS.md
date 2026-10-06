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

Please note that any addons (Found under `/client/src/addons`) are exempt from this license header as not everything in this directory is owned by OpenMinerva. Unless you are adding a new addon, assume that everything under this directory to be set up correctly in regards to licenses and headers.

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
See [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html#naming-conventions).

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

#### Usage of "unrecommended" aliases
This project makes use and encourages the use of "unrecommended" operator aliases as [defined by Godot](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#operators).
Instead of writing "and", use the symbols "&&". Instead of writing "not", use "!". This is to make this codebase more consistent with other languages that this project uses.
Using the Godot recommended aliases "not" as well as "and" is not recommended for this project. Using Godot aliases *is* acceptable however and will not cause your pull request to be closed by itself.

```gdscript
# ✅ Good
var is_contant_not_equal: bool = MY_AWESOME_CONSTANT != 35.25
var trigger_action: bool = IS_FEATURE_ENABLED && action_just_pressed

# ❌ Bad
var is_contant_not_equal: bool = not MY_AWESOME_CONSTANT == 35.25
var trigger_action: bool = IS_FEATURE_ENABLED and action_just_pressed
```

#### No Magic Numbers / Values
Do not use magic numbers or magic "values". All constant values must be defined as a variable or constant.

```gdscript
# ✅ Good
# ...
const TARGET_POSITION = 32
if node_positon == TARGET_POSITION:
# ...
const initial_height: int = 105
const height_of_target_node_half: int = 32 / 2
var new_position: float = initial_height + height_of_target_node_half * offset
# ...

# ❌ Bad
# ...
if node_position == 32:
# ...
var new_position: float = 105 + 32 / 2 * offset
```

#### No Commented Code
Do not leave code commented out. If code is not used, it should be removed.
```gdscript
func _log_to_file(message: String = "", level: int = 0):
	if file_logging_enabled && log_file:
		var formatted_log = "[%s] %s" % [log_level_names[level], message]
		log_file.store_line(formatted_log)
		log_file.flush()

# ❌ Bad
# func _parse_log_file_name(file_name: String) -> Dictionary:
# 	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
# 	var date = file_name.split(".")[1].split("-")
# 	var year = date[0].split("_")[0]
# 	var month = date[0].split("_")[1]
# 	var day = date[0].split("_")[2]
# 	var hour = date[1].split("_")[0]
# 	var minute = date[1].split("_")[1]
# 	var second = date[1].split("_")[2]
# 	var time_dictionary = Time.get_datetime_dict_from_datetime_string("%s-%s-%sT%s:%s:%s" % [year, month, day, hour, minute, second], true)
# 	return time_dictionary
```
[Example of bad practice](https://github.com/OpenMinerva/client/blob/f2a96a0ded2723f2e1960aa510055596e50a26f1/src/scripts/logger.gd#L97)

#### Variables Definition 
Variables should be defined at the top of their respective scope, and assigned a `null` value if they can not be immediately defined.

```gdscript
# ✅ Good - Defined at the top of the scope.
func awesome_function() -> void:
    var good_position: Vector3 = Vector3(10, 5, 12)
    var second_position: Vector3 = Vector3()
    # ...
    return

# ❌ Bad - Defined as they are used in the function.
func not_great_function() -> void:
    # Code ...

    var good_position = Vector3(10, 5, 12)

    # ...
    return
```

#### Conditionals 
Conditionals should explicitly declare their target value. Alternatively, they should explicitly declare that the value is not null / is defined.

```gdscript
# ✅ Good 
func handle_something() -> void:
    var some_node: Node3D = get_node_or_null("Target")
    if some_node != null:
        # ...

func next_thing() -> void:
    var something_that_is_true: bool = true

    if something_that_is_true == true:
        # ...
    return

# ❌ Bad
func handle_something() -> void:
    var some_node: Node3D = get_node_or_null("Target")
    if some_node:
        # ...

func next_thing() -> void:
    var something_that_is_true: bool = true

    if something_that_is_true:
        # ...
    return
```

#### Valid / Intended Function Exits
All intended function exists should be marked explicitly with a `return` statement, even when the return statement would otherwise be implied.
This means that all functions must end with a `return` statement.

```gdscript
# ✅ Good
func example_function() -> void:
    if day_of_the_week == "Friday":
        GlobalLogger.log("This function refuses to work on Friday.")
        return

    GlobalLogger.log("Now that Friday is not in the room, lets talk about our favorite day of the week.")
    return

# ❌ Bad
func example_function() -> void:
    if day_of_the_week == "Friday":
        GlobalLogger.log("This function refuses to work on Friday.")
        return

    GlobalLogger.log("Now that Friday is not in the room, lets talk about our favorite day of the week.")
    # Missing `return`
```

## Testing Requirements
Before making a commit, you should test your changes by launching the application and testing your new feature. While testing you should monitor the logs to make sure there are no new errors caused by your changes.
When making a pull request, your final commit before being submitted should not introduce any new errors. Do not defer fixes; all logged issues must be resolved before sent for review.

### Making automated tests
When you make a new feature, you should make unit tests for your new feature. OpenMinerva uses [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) to make unit tests for the application. For examples of using this testing suite, please see the [/src/test](https://github.com/OpenMinerva/client/tree/feature/unit-tests/src/test) folder. Tests are expected to follow the coding standards just the same as any other code in the codebase would.

### Retroactively adding automated tests
As the testing suite is relatively new compared to the rest of the code base, a substantial part of the codebase does not have testing coverage. When touching a relevant file, it would be courteous (although not a requirement) to add tests relating to the file or at least related functions you are working with.

## Key Branches
OpenMinerva separates the repository into four separate key branches. `alpha`, `beta`, `stable`, and `lts-XXXX`.

- `alpha`: This is the bleeding edge of the application. This includes early implementations of upcoming features, hot-fixes and any other kind of development work. This is similar to the `nightly` branch in other projects or repositories. This branch will typically target the `beta` branch.
- `beta`: This is for feature-freezes. When the beta branch gets updated, it will typically be frequently updated exclusively with bug and issue fixes until the application is in a stable state for the `stable` branch.
- `stable`: Recommended and default installations of the OpenMinerva software. This branch is the primarily distributed branch on all major distribution platforms.
- `lts-XXXX`: LTS, or Long-Term-Support, is a special branch that is feature frozen and exclusively receives bug or issue fixes for a extended period of time. The branch name is a year in the format of YYYY. Example: `lts-2026`, `lts-2028`.
- `lts-XXXX-beta`: This extension of the `lts-XXXX` branch is similar to the `beta` branch in that this branch only focuses on bugs and issues before being merged back into `lts-XXXX`.


## Commits and Messages
All new pull requests by default should target the [`alpha`](https://github.com/OpenMinerva/client/tree/alpha) branch. This includes fixes, features, documentation, hot-fixes, and anything else. If you do not know which branch to use, use `alpha`.

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
