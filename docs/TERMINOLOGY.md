# Terminology

This document outlines all of the terminology used both in the client application and the wider project. This document was created to help new contributors understand what variables mean, and existing contributors to have an idea what to call a variable.


## Client
- `session`:
    - A "session" is a multiplayer 'server' as defined by Godot. This is the multiplayer instance where players can connect and collaborate. This is not to be confused with `server`, which is most often used to describe an outside service.
- `server`:
    - A "server" is an outside service, most commonly used to refer to services like the Account Server, and the Session Server.
- `database`:
    - "database" or "the database" refers to the long-term storage on the client machine in any way. This means that data will be persistent in a long term manner.
- `registry`:
    - Commonly used for application or session managers to keep track of information much like a database, but not in a permanent way. This of this like a database in system memory only.
### Variables:
- `session_root`:
    - "session_root" or "root" is the node of the session in which all players and other interactions take place. Everything except the session managers are expected to be under this explicit node. This node is always expected to carry the name "root". In the codebase this specific node will often times be called explicitly "session_root". This is not to be confused with "session_master" which is the actual node that contains the session managers as direct children.
- `session_master`:
    - "session_master" is the explicit node that contains the session in the client application. This is expected to be a direct child of the node `Sessions` in the master scene. This node should only be interacted with in the core codebase, and session clients or the session host should not be able to interact with this specific node in any way outside of using proxies. Example: Leaving a session removes a `session_master` node from the "Sessions" node, joining a session will add a "session_master" node to the "Sessions" node.
- `scene`:
    - "scene" or "scenes" is the name to a physical instance of a node or group of nodes. The "scene" specifically refers to the nodes themselves and not the greater session.

#### Modules
The client uses several different modules in different locations in the application. Some modules live in the absolute root of the "game scene". These modules are named with the word "App" prepended to the name. Some other modules are created per-session and are also prepended with the string "Session" in the name.

*These prepended strings are also inserted into the variable name*

Example application module variable names:
- `app_network_m` -> `application network manager`
- `app_scene_m` -> `application scene manager`

Example session module variable names:
- `sess_network_m` -> `session network manager`
- `sess_scene_m` -> `session scene manager`

## Services

- Account Server:
    - "Account Server" refers to the open source server software that is used for the OpenMinerva project. This project can be found [here](https://github.com/OpenMinerva/account-server)
- Session Server:
    - "Session Server" refers to the open source server software that is used for the OpenMinerva project. This project can be found [here](https://github.com/OpenMinerva/session-server)
