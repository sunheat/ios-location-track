# Source audit and permission-change rescan

Upstream baseline: `40b800fe7a6354f1a13fedc1d94ec98f447ab9e8` (`main`, 2026-10-28).

Initial scope: all 84 tracked files in `sunheat/ios-location-track`, including application source, web UI, scripts, installer configuration, and committed resources. The initial review was static. No application or installer was run. All 37 Python files parsed successfully with `ast.parse`.

## Rescan after the permission change

- The only functional changes remove mandatory elevation in `Location.spec`, remove the administrator gate from `core/setup_window.py`, and make normal startup call `ensure_apple_driver(..., allow_install=False)` in `main.py`. The explicit `--install-driver` path remains available. Build-script and English documentation changes reflect this behavior. No device-control, web API, or network destination was added by the fork.
- `tests/test_standard_user_startup.py` failed on all three privilege assertions before the change and passed afterward. Existing repository self-checks passed: 83 + 40 + 13 checks. `pip check` found no broken requirements, and `git diff --check` passed.
- A local portable build completed with PyInstaller 6.22.3. Its embedded Windows manifest was extracted from PE resource type 24 and contains `requestedExecutionLevel level="asInvoker"`. The final executable SHA-256 is `8E88984F472C0BE1ABA5131B3FA46D64BD15622BE6939CDAC3ABA24F1EE39D06`. A packaged `--check-driver` run exited successfully.
- On this machine, the read-only driver check ran without administrator privileges: Apple Mobile Device Support 19.4.0.10 was running, `usbmuxd` answered a protocol probe, and no iPhone was connected. Every required environment-check item passed in the source environment.
- Microsoft Defender reported completion of an on-demand custom scan of the final `dist/iOSLocationTrack` build on 2026-10-28 (scan ID `55E1059A-88BA-41D4-912B-44D201B24D7C`), with no threat detection returned. This is a malware-signature check, not a proof that the program or its dependencies are harmless.
- The normal application UI was not started and no iPhone location was changed. Real-device compatibility and runtime network behavior remain unverified.

## Findings

1. **Resolved in the fork — The upstream Windows executable required administrator privileges for every launch.** The baseline set `uac_admin=True` in `Location.spec`, required administrator status in `core/setup_window.py`, and allowed automatic driver installation during normal startup in `main.py`. The fork removes these three requirements; the local build's actual manifest says `asInvoker`.

2. **High — Install and image download paths are not consistently authenticated to a fixed artifact.** `core/apple_driver.py:529-548` downloads Apple Application Support without a digest and executes the MSI. The iTunes fallback at `core/apple_driver.py:573-583` executes a downloaded EXE without a digest. Developer image downloads at `core/apple_driver.py:765-821` follow a moving `main` branch and accept files using minimum size alone; `core/server.py:835-843` also treats equal size as sufficient to reuse an image. The AMDS MSI does have a pinned SHA-256 (`core/apple_driver.py:61,66`). Require trusted hashes or verified signatures for executable downloads and pin the developer image source before enabling these flows.

3. **Medium — Dependency installation is unpinned and defaults to a third-party package index.** `pip.conf:2`, `scripts/run.ps1:38,70`, `scripts/build.ps1:46-47`, and the shell scripts select the Aliyun PyPI mirror by default and install packages without exact versions or hashes. A local build cannot currently be reproduced from reviewed dependency artifacts. Use a reviewed lockfile with hashes and a deliberate index choice.

4. **Medium — Device-control HTTP and WebSocket endpoints have no authentication token.** `core/server.py:1015-1045` checks `Origin` and `Host`; these checks cover both HTTP methods and the WebSocket upgrade (`core/server.py:1100-1156`). The default bind address is loopback (`main.py:48`, `core/protocol.py:17`), reducing exposure. However, local processes and clients without an `Origin` header can issue state-changing commands, and starting with `--host 0.0.0.0` exposes the API to the LAN without authentication. Keep loopback binding and add a per-session authorization token before any non-loopback use.

5. **Medium — No repository-wide license grant is present.** There is no tracked `LICENSE`, `COPYING`, or equivalent statement in the README. GitHub reports the upstream and this fork as unlicensed. Do not label the inherited repository Apache-2.0 without authorization from the relevant copyright holders. New, separable contributions can carry their own license notices.

## Observed behavior and limits

- Static string and call-path review found no direct code path reading browser credentials, SSH keys, or password stores, and no apparent telemetry or arbitrary file-upload endpoint. This does not establish absence of malicious behavior in dependencies or release binaries.
- The application contacts map tile providers, the public OSRM route service, Apple download/signing services, and a developer-image repository/CDN. Configured tile and OSRM URLs can be changed through the local API (`core/config_store.py:190-209,279-282`), so actual network destinations depend on local configuration.
- Device interaction in the reviewed paths uses `pymobiledevice3` for discovery, pairing, tunneling, developer-image mounting, and simulated location. No app-specific backup or file-extraction feature was found in this repository. The behavior of installed third-party packages was outside this review.
- Committed non-text resources consist of icons, a developer-image build manifest, and trust caches. The 15 MB `Image.dmg` is not committed (`.gitignore`) and was not examined. Published EXE/installer binaries were not downloaded or compared to source.

## Before use

The standard-user permission change is complete and the local portable build is ready for manual launch. The dependency and download choices listed above remain upstream behavior, as requested. Verify real-device compatibility and runtime network activity during first use; static review and antivirus scanning cannot establish either.
