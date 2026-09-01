# Philosophy
This document is for everyone (observers, users, contributors, and you), and it serves to outline the *why* of OpenMinerva.

## OpenMinerva
In short, OpenMinerva is designed to be a virtual and immersive collaborative space for humanity. The design goal of OpenMinerva is specifically designed to integrate into the roles of, but not limited to, classrooms, office spaces, training simulations, art exhibits, informational kiosks.
Below are a few examples of situations where the feature-complete version of OpenMinerva will do well in.

### Educational:
- Educators build interactive presentations.
- Students join saved presentations, and interact with the provided materials.
- Live analytics of curated / managed sessions.
- Join a student live to provide guidance.

### Work spaces:
- Whiteboarding and diagramming.
- Collaborative synchronized world.
- Low performance requirements for the software.
- Offline / internal network capable. Never leave your infrastructure.

### Training Simulations:
- Experts design interactive scenarios.
- Trainees progress through these scenarios.
- Export data and a replay of the session for analysis and review. (See [issue #188](https://github.com/OpenMinerva/client/issues/188))
- Simple experience export: Create a virtual reality application with OpenMinerva as nothing more than the core. (See [issue #120](https://github.com/OpenMinerva/client/issues/120))

### Art Exhibits.
- Low hardware requirements enable cheaper device usage.
- Virtual Reality and flat-screen interoperability allows a mix and match of VR headsets and flat screen experiences.
- Visitor analytics: Track a history of usage of your exhibitions. (See [issue #188](https://github.com/OpenMinerva/client/issues/188))
- Network availability for free, open your gallery to the world with no extra charge.
- Scheduled exhibit publishing. Get ahead of your crowd to prepare your experience. (See [issue #187](https://github.com/OpenMinerva/client/issues/187))

### Large Events:
- Live / recorded video playback in world. (See [issue #30](https://github.com/OpenMinerva/client/issues/30))
- Strict host-authoritative permission controls.
- Live audio streams directly in-world. (See [issue #189](https://github.com/OpenMinerva/client/issues/189))


## Out of Scope
- Live service / subscription-based functionality. Any officially provided services can be entirely self-hosted on your own hardware at your own expense.
- In-platform economy: OpenMinerva is not a marketplace and does not support buying or selling items, assets, projects, or other creations natively within the platform. Users are free to utilize external storefronts to market their creations, but OpenMinerva itself remains a non-commercial collaboration platform. (Note: In the future there may be integrations with existing storefronts to make accessing purchased creations easier, however these integrations will be scoped and limited)
- AI automation tool integration. It is the belief of the sole maintainer that artificial intelligence created assets and tools do not provide a meaningful improvement to the goals of this project. Information provided by these tools are often times wrong, and the customers of these artificial intelligence tools will often times not provide the required care such as fact-checking or sourcing. These tools are extremely dangerous for educational environments and are not / will not be officially supported in any capacity. 
- Platform lock-in: Protecting user-generated content *is* important and will remain in-scope, however "vendor lock-in" specifically into OpenMinerva itself is not. Owners of content will be allowed to export their assets into common standards from the application to use anywhere else. Protections to user-generated content provided by OpenMinerva can be easily confused for vendor lock-in, but controls of the user generated content protection system will always be in the hands of the owners of the content and can be removed at any time at their own discretion.
- Data exploitation: No information is sent back to OpenMinerva servers or services without consent. Data that can be sent back to OpenMinerva servers is targeted and exclusively opt-in.

## Priorities
OpenMinerva is guided with a commitment to simplicity, stability, and consistency. These base principles steer the development workflow and feature evaluation.
Below is the list of development priorities by maintainers. These are the issues that typically get reviewed, triaged, and fixed first.

### Security: 

OpenMinerva is designed to have a minimal attack surface. Security issues are triaged and addressed as quickly as possible. In-application scripting is sandboxed and will be handled though approved APIs though Web Assembly (See [issue #71](https://github.com/OpenMinerva/client/issues/71)). 

### Stability: 

The application should be able to run unattended and reliably for extended periods of time. Issues that prevent this from happening are prioritized so as to limit the number of interruptions caused by issues resulting from the core application.

### Usability: 

If something does not make sense at first glance, then it is considered a poor implementation and a remediation is scheduled. The software should be very intuitive and simple to understand without relying on external tools or websites to learn about it.

### Consistency: 

There should not be multiple API calls that do the same thing. The application should provide a single simple interface for performing a task. Core maintainers and in-application content creators should not have to re-invent the wheel.

### Features: 

New features to enhance content creation, or impress visitors are always under consideration for implementation. Is is the goal of this project to provide any and all tools required for your success, if OpenMinerva is missing something you need, you can always open a new [feature request](https://github.com/OpenMinerva/client/issues/new/choose)

### Modularity: 

OpenMinerva is built to be broken into modules so that other developers can take what works for us, modify it to their needs if required, and use our software solutions with no additional hassle. [All of our modules](https://github.com/OpenMinerva/repositories) are licensed under MIT allowing free use for whatever they might need it for. This allows an expanded reach of our solutions to provide more testing for the users of OpenMinerva.



## Decision-Making
All major decisions are publicly announced through official channels. You can find official community channels on the [OpenMinerva](https://openminerva.org) website. This project is the life's work of a single maintainer, and as such all decisions are handled and made by them. Comments, opinions, and concerns are always allowed to be voiced so long as these comments are constructive and abide by the [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md). Other perspectives are invaluable to the decision-making process.


## Licensing
OpenMinerva is licensed under MIT, ensuring free use, modification, and distribution of the application. Items, assets, creations, or other user-generated content remains the sole property of the original content creators. 

## Contribution Expectations
Please see [CODE_OF_CONDUCT](./CODE_OF_CONDUCT.md) for expectations of users and maintainers.

