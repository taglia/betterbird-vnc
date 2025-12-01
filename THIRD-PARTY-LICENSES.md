# Third-Party Software Licenses

This Docker image includes the following third-party software components.
Each component is licensed under its respective open source license.

## BetterBird

- **Version**: 140.5.0esr-bb14
- **License**: Mozilla Public License 2.0
- **Website**: https://www.betterbird.eu/
- **Source Code**: https://github.com/Betterbird/thunderbird-patches
- **Copyright**: Copyright (c) BetterBird Project
- **License Text**: https://www.mozilla.org/en-US/MPL/2.0/

BetterBird is a fine-tuned version of Mozilla Thunderbird, licensed under
the Mozilla Public License 2.0. BetterBird contains new features, bug fixes,
and improvements not yet available in standard Thunderbird.

## noVNC

- **Version**: Latest from GitHub (cloned during build)
- **License**: Multiple licenses depending on component:
  - **Core JavaScript**: Mozilla Public License 2.0
  - **HTML/CSS files**: BSD 2-Clause License
  - **Orbitron fonts**: SIL Open Font License 1.1
  - **Images**: Creative Commons Attribution-ShareAlike 3.0
  - **Pako library**: MIT License
- **Website**: https://novnc.com/
- **Source Code**: https://github.com/novnc/noVNC
- **Copyright**: Copyright (c) 2022 The noVNC authors
- **License Text**: https://github.com/novnc/noVNC/blob/master/LICENSE.txt

noVNC is an HTML VNC client JavaScript library and application that allows
VNC access through a web browser without any browser plugins.

### noVNC License Details

The noVNC core library files (JavaScript code necessary for full noVNC
operation) are licensed under MPL 2.0. The HTML, CSS, font, and image files
are licensed under more permissive licenses to allow easy integration.

## TigerVNC

- **Version**: As provided by Debian Bookworm repositories
- **License**: GNU General Public License v2.0
- **Website**: https://tigervnc.org/
- **Source Code**: https://github.com/TigerVNC/tigervnc
- **Debian Package**: https://packages.debian.org/bookworm/tigervnc-standalone-server
- **License Text**: https://www.gnu.org/licenses/old-licenses/gpl-2.0.html

TigerVNC is a high-performance, platform-neutral implementation of VNC
(Virtual Network Computing), distributed under the GNU General Public
License version 2.

### TigerVNC License Notice

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; version 2 of the License.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

The complete source code for the version of TigerVNC included in this image
is available at the GitHub repository listed above, and from the Debian
source package repositories.

## Fluxbox

- **Version**: As provided by Debian Bookworm repositories
- **License**: MIT License
- **Website**: http://fluxbox.org/
- **Source Code**: https://github.com/fluxbox/fluxbox
- **Debian Package**: https://packages.debian.org/bookworm/fluxbox
- **Copyright**: Copyright (c) 2001-2011 The Fluxbox Team

Fluxbox is a lightweight window manager for X, licensed under the MIT License.

### Fluxbox License Text

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Debian GNU/Linux

- **Distribution**: Debian Bookworm (version 12)
- **Base Image**: debian:bookworm-slim
- **License**: Various DFSG-compliant open source licenses
- **Website**: https://www.debian.org/
- **Package Sources**: https://packages.debian.org/bookworm/
- **Source Code**: https://www.debian.org/distrib/packages

Debian packages are licensed under various Free Software licenses that comply
with the Debian Free Software Guidelines (DFSG). Common licenses include GPL,
LGPL, BSD, MIT, Apache, and others.

### Key Debian Packages Used

This image includes various Debian packages, including but not limited to:

- **X11 and VNC components**: xvfb, x11vnc, tigervnc-standalone-server, tigervnc-common
- **System libraries**: libasound2, libdbus-glib-1-2, libdbus-1-3, libgtk-3-0, etc.
- **Graphics libraries**: libgl1-mesa-glx, libgl1-mesa-dri, libegl1-mesa, libgbm1
- **Fonts**: fonts-liberation, fonts-dejavu
- **Utilities**: wget, bzip2, xz-utils, ca-certificates, supervisor, procps, curl

For complete license information about any specific Debian package, you can:

1. Run inside the container: `dpkg -L <package-name> | grep copyright`
2. Visit the Debian package page: `https://packages.debian.org/bookworm/<package-name>`
3. View copyright files in the container at: `/usr/share/doc/<package-name>/copyright`

## Python and Dependencies

- **Python 3**: Python Software Foundation License (PSF)
- **python3-numpy**: BSD License
- **websockify**: LGPLv3 or later (cloned with noVNC)

Python and its standard libraries are licensed under the PSF License, which
is GPL-compatible and approved by the OSI.

## Supervisor

- **License**: BSD-like (Repoze Public License)
- **Debian Package**: https://packages.debian.org/bookworm/supervisor

Supervisor is a process control system licensed under a BSD-style license.

## Source Code Availability

As required by the GPL and MPL licenses, source code for all components is
freely available:

### GPL Components (TigerVNC)

The complete and corresponding source code for TigerVNC is available at:
- GitHub: https://github.com/TigerVNC/tigervnc
- Debian Sources: `apt-get source tigervnc-standalone-server`

You can also request the source code in writing within three years of
receiving this software.

### MPL Components (BetterBird, noVNC)

The complete source code for MPL-licensed components is available at:
- BetterBird: https://github.com/Betterbird/thunderbird-patches
- BetterBird releases: https://www.betterbird.eu/downloads/
- noVNC: https://github.com/novnc/noVNC

### All Other Components

All other components are available from their respective upstream sources
and Debian package repositories as listed above.

## Verification

To verify the licenses of components in a running container, you can:

```bash
# List all installed packages
docker exec <container-name> dpkg -l

# View copyright information for a specific package
docker exec <container-name> cat /usr/share/doc/<package-name>/copyright

# Example: View TigerVNC license
docker exec <container-name> cat /usr/share/doc/tigervnc-standalone-server/copyright
```

## Summary

This Docker image is an aggregation of separately-licensed software components.
Each component retains its original license. The Docker configuration files
(Dockerfile, scripts, docker-compose.yml, etc.) in the source repository are
licensed under the MIT License.

No modifications have been made to the source code of any included software
components. All software is used in its original, unmodified form as provided
by the respective upstream projects or Debian repositories.

---

For questions about licenses of specific components, please refer to the
respective upstream projects or package maintainers listed above.

Last updated: December 2025
