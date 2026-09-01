> [!WARNING] 
> This repository is currently pre-alpha, breaking changes happen frequently, there have not been any security audits, and data loss is expected.

<p align="center">
  <br>
  <img height="150" src="https://github.com/openminerva/client/blob/alpha/docs/logos/om-logo-big.webp?raw=true" />
</p>
<p align="center">
  <br>
  <a href="https://discord.gg/Kx6avB52gK">
    <img src="https://dcbadge.limes.pink/api/server/https://discord.gg/Kx6avB52gK" alt="Discord" />
  </a>
  <br>
  <a href="https://discord.gg/Kx6avB52gK">Join the Discord!</a>
</p>

# Client

OpenMinerva is the no-nonsense self-hosted virtual collaboration environment for flatscreen / VR / AR.

<p align="center">
  <img height="200" src="./docs/preview/wwyb_promo.webp?raw=true" style="margin-right: 16px;" />
  <img height="200" src="./docs/preview/sponza_example.webp?raw=true" />
</p>

## About
OpenMinerva aims to be a platform-agnostic flatscreen / virtual reality / augmented reality sandbox application that is fully self-hostable, and completely open source.

To learn more about the OpenMinerva project, please read the [PHILOSOPHY.md](./docs/PHILOSOPHY.md) document. This document provides use-cases targets and other reasoning for this project.

## Installation
It is not currently possible to install OpenMinerva client as a stand-alone executable, as the application is still in early alpha. For now, please download and install OpenMinerva as a developer. Please see [Development Quick Start](#development-quick-start)

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
See [CONTRIBUTING.md](https://github.com/OpenMinerva/client/blob/alpha/docs/CONTRIBUTING.md) for guidelines, and information.

## Used Addons
These addons are used in building the OpenMinerva client:

| Addon Name | Status | Code URL | License | Source URL |
| ---------- | ------ | -------- | ------- | ---------- |
| Gizmo3DScript   |  Forked   | [Usage](https://github.com/OpenMinerva/client/tree/alpha/src/addons/Gizmo3DScript) | MIT | [Source](https://github.com/chrisizeful/Gizmo3D) |
| Discord-RPC-GD  | Forked   |  [Usage](https://github.com/OpenMinerva/client/tree/alpha/src/addons/discord-rpc-gd) | MIT | [Source](https://codeberg.org/DiscordGodot/RPC-Legacy) |
| rpc-await | Forked | [Usage](https://github.com/OpenMinerva/client/tree/alpha/src/addons/rpc-await) | MIT | [Source](https://github.com/dominiks/rpc-await) |
| at-icons     | Forked     | [Usage](https://github.com/OpenMinerva/client/tree/alpha/src/resources/icons/at-icons) | MIT | [Source](https://github.com/Voxybuns/at-icons) |
| godot-oauth2client | Owner | [Usage](https://github.com/OpenMinerva/client/tree/alpha/src/addons) | MIT | [Source](https://github.com/OpenMinerva/godot-oauth2client/tree/a835738a2674feb2679576a247169fc53c2d4682) |
| godot-urlparser | Owner | [Usage](https://github.com/OpenMinerva/client/tree/alpha/src/addons) | MIT | [Source](https://github.com/OpenMinerva/godot-urlparser/tree/50632506d6a5a8a65bda52640339df98957fd0cd) |
| godot-sqlite | Downloaded | Not included | MIT | [Source](https://github.com/2shady4u/godot-sqlite) |



