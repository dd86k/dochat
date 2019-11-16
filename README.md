# dochat: Self-Hosted for Everyone

**WARNING**: dochat is currently not usable in its current state!

dochat's goal is be an lean open-source self-hosted text and voice platform team chat for you and your friends (or colleagues)!

- *fast*: Built using D, a [native system language](https://dlang.org), and vibe.d, a [fast Web application framework](https://vibed.org).
- *simple*: We should do the heavylifting, not you. Readable documentation and server settings for everyone!
- *open*: The server, client, and specifications are open and documentated.

This repository includes both the dochat Web client and the dochat server.

## Roadmap

**Not production-ready!**

Current status: In development.

User manual: TODO

Administration manual: TODO

Technical manual: TODO

**Features**

| Feature | Implemented? |
|---|---|
| Text Channels | On-going |
| Direct Messaging | Planned |
| Role/permission system | Planned |
| Voice Channels | Planned |
| Federation | Considering |
| Friend system | Considering |
| End-to-End Encryption | Considering |
| Add-on system | Considering |
| Add-on: Matrix bridge | Considering |
| Add-on: IRC bridge | Considering |
| Add-on: XMPP bridge | Considering |

**APIs**

| API | Implemented? |
|---|---|
| WebSocket-JSON* | On-going |
| TCP-JSON** | Planned |
| TCP-Binary*** | Considering |

\* Includes HTTPS support
\
\*\* Includes TLS encryption support
\
\*\*\* Currently deciding if we should go ala IRC (text) or ala MTProto (binary)

# FAQ

- Why did you make dochat?

I decided to make my own platform to answer my own needs: a self-contained, self-hosted, and Discord/IRC/Teamspeak/Mumble/Wire/XMPP replacement.

- Why with D and vibe.d?

D is simply my primary programming language, and vibe.d is [fast](https://vibed.org/features#performance).

# Projects Used

dochat is built with these following awesome libraries and resources. Give them a star too!

## dochat-client

- Feather Icons v4.8.0 - https://feathericons.com/

## dochat-server

- Vibe.d - https://vibed.org/
- d2sqlite3 - https://github.com/biozic/d2sqlite3/
- sdlang-d - https://github.com/Abscissa/SDLang-D/