> [!WARNING] 
> This repository is currently pre-alpha, breaking changes happen frequently, there have not been any security audits, and data loss is expected.

<p align="center">
  <img height="150" src="https://github.com/openminerva/client/blob/alpha/docs/logos/om-logo-big.webp?raw=true" />
</p>
<p align="center">
  <a href="https://discord.gg/Kx6avB52gK">
    <img src="https://dcbadge.limes.pink/api/server/https://discord.gg/Kx6avB52gK" alt="Discord" />
  </a>
</p>

# Client

Client is the interface used to connect and interact with the virtual world of OpenMinerva.

## Development Quick Start

### Download source code
For cloning this project on Linux:
```bash
# Clone this repository.
git clone --recurse-submodules https://github.com/OpenMinerva/client 
```

### Setup the environment
This repository does not ship some required addons in order to prevent unnecessary weight in the git history. Instead there is a script `/src/setup_environment.sh` (Linux only) that can be executed to automatically download the addons. Windows users will need to install these addons manually for now.

For simplicity, here is a list of the missing addons:
- [godot-sqlite](https://github.com/2shady4u/godot-sqlite) - Tagged `v4.8` - [Download](https://github.com/2shady4u/godot-sqlite/releases/download/v4.8/addons.zip)

Download these addons into the `/src/addons/` folder of this repository. 
Example:
```
/src
    /addons
        /godot-sqlite
        /discord-rpc-gd
        /rpc-await
```

### Import project into Godot.
- Open your copy of the [Godot Engine](https://godotengine.org/).
- Click on "Import" near the top of the application window.
- Navigate to the location where the source code was downloaded to.
- Navigate to the sub-directory `/src`.
- Select `project.godot` to import this project.

## Contributing
See [CONTRIBUTING.md](https://github.com/OpenMinerva/client/blob/alpha/CONTRIBUTING.md) for guidelines, and information.
