# Building GnuCash as an AppImage with Docker Compose

This project compiles [GnuCash](https://github.com/gnucash/gnucash) and packages it as an AppImage using Docker Compose.

# 📁 Project Structure

```
./
├─ Dockerfile                      # Docker image for compilation
├─ docker-compose.yml              # Docker Compose configuration
├─ build.sh                        # Helper script to simplify build commands
├─ build-gnucash.sh                # Main build and packaging script
├─ shell.sh                        # Open an interactive shell in the container
├─ diagnose-appimage.sh            # Diagnostics for AppImages
├─ release.sh                      # Build and push a release to GitHub
├─ .gitignore                      # Files ignored by Git
├─ .github/
│  ├─ workflows/
│  |  ├─ GITHUB_ACTIONS.md         # GitHub Actions documentation
│  |  ├─ build-appimage.yml        # Standard CI/CD build
│  |  ├─ build-release.yml         # Optimized build for releases
│  |  ├─ nightly.yml               # Automated daily builds
│  |  ├─ check-new-version.yml     # Build with upstream version
│  │  └─ pr-validation.yml
| -- Directories and files automatically created by the build:
├─ build/                          # Cache directory
│  ├─ gnucash-x.xx.tar.bz2         # Source archive
│  ├─ gnucash-x.xx/                # Extracted sources (clean, unmodified)
│  ├─ gnucash-x.xx_build/          # Separate build directory (CMake + compilation)
│  ├─ AppDir/                      # Temporary installation for AppImage
│  │  └─ usr/local/                # All of GnuCash is installed here
│  │     ├─ bin/                   # Binaries, including the "gnucash" application
│  │     ├─ lib/                   # GnuCash libraries and dependencies
│  │     └─ share/                 # Data and resources
│  ├─ linuxdeploy-x86_64.AppImage  # Packaging tool
│  └─ appimagetool-x86_64.AppImage # AppImage creation tool
└─ output/                         # Output directory
   └─ GnuCash-x.xx-x86_64.AppImage # Final AppImage file
```

**Advantages of this structure:**

- ✅ **Clean sources**: `gnucash-x.xx/` remains intact and unpolluted by build files
- ✅ **Separate build**: `gnucash-x.xx_build/` contains all compilation output (CMake, Makefiles, objects)
- ✅ **Consistent structure**: Everything under `/usr/local` (no mixing of `/usr` and `/usr/local`)
- ✅ **Smart cache**: AppImage tools are downloaded once and reused
- ✅ **Editable scripts**: No need to rebuild the Docker image to modify scripts
- ✅ **Fully accessible**: No hidden Docker volumes — everything is on your filesystem
- ✅ **Interactive shell**: `docker` user with sudo rights for debugging

### Dockerfile

**Python**

The latest version of Python is pulled from the "deadsnakes" PPA and set as the default Python, replacing the one bundled with Ubuntu.

**Guile and its dependencies** (runtime):

```dockerfile
    guile-3.0 \
    guile-3.0-dev \
    guile-3.0-libs \
    libgc1 \
    libgmp10 \
    libunistring2 \
    libffi8 \
```

Explanation: `guile-3.0-dev` installs the headers needed for compilation, but not necessarily all the runtime libraries. The runtime packages and their dependencies are added explicitly so they can be bundled into the AppImage.

### Advantages of the volume-based architecture

**Modify scripts without rebuilding:**

- You can edit `build-gnucash.sh` directly
- No need to rebuild the Docker image
- Just re-run `docker compose up`

**Persistent and accessible cache:**

- The `build/` directory holds all cached files
- Accessible from your host system for inspection and debugging
- No hidden Docker volumes

**Fast development workflow:**

```bash
# Edit build-gnucash.sh with your editor
nano build-gnucash.sh

# Test immediately
./build.sh build
```

**Interactive shell for debugging:** The container runs as a `docker` user with passwordless sudo:

```bash
# Open a shell in the container
./shell.sh

# Once inside, you have access to:
docker@container:/workspace$ ls build/
docker@container:/workspace$ sudo apt install strace
docker@container:/workspace$ cd build/gnucash-x.xx_build
docker@container:/workspace$ make  # Manual compilation
```

### Build process

The automated process (`build.sh`) will:

1. Build the Docker image with all dependencies (patchelf, cmake, gcc, etc.)
2. Download GnuCash (if not already cached)
3. Extract the sources into `build/gnucash-x.xx/`
4. Compile in `build/gnucash-x.xx_build/` (separate from the sources)
5. Install into `build/AppDir/`
6. Download linuxdeploy and appimagetool (if not already cached)
7. Collect dependencies with linuxdeploy
8. Create the AppImage with appimagetool
9. Place the AppImage at `output/GnuCash-x.xx-x86_64.AppImage`

# 📋 Prerequisites

#### For GitHub Actions

- GitHub repository (public or private)
- GitHub Actions enabled (free for public repositories)

#### For local builds

- Docker installed
- Docker Compose installed
- Approximately 5–10 GB of available disk space

# 🎯 Build

### Via GitHub Actions

See the full documentation in [.github/workflow/GITHUB_ACTIONS.md](.github/workflow/GITHUB_ACTIONS.md)

**Summary:**

- **Push to main/develop** → Automatic build
- **Pull Request** → Verification build
- **Version tag** → Release of the compiled GnuCash application
- **Manual** → Via the GitHub Actions interface

**Option 1 – Manual build:**
Triggered from the repository's "Actions" tab, under "Build GnuCash AppImage".
The artifact is available but no release is created.

**Option 2 – Automatic release:**

```bash
git tag -a 5.14 -m "Release GnuCash 5.14"
git push origin v5.14
```

A release will be created automatically with the AppImage.

### Local build

#### Simple method (with helper script)

```bash
chmod +x build.sh

# Normal build (fast, uses the cache)
./build.sh build

# Full rebuild (clears the build cache)
./build.sh rebuild

# Full cleanup (cache + Docker images + volumes)
./build.sh clean

# Deep cleanup (+ Docker buildkit cache)
./build.sh clean-deep
```

#### Manual method (docker compose)

```bash
# Normal build
docker compose up --build

# Full rebuild
docker compose down
rm -rf build/gnucash-x.xx_build
docker compose up --build

# Total cleanup
docker compose down --volumes --rmi all
rm -rf build/ output/
```

#### Why multiple build methods?

**`./build.sh build`:**

- Uses the build cache (archive, sources, CMake compilation)
- Incremental compilation: only modified files are recompiled
- **Fast** for subsequent builds (~5–10 minutes instead of 30–60)
- Tools (linuxdeploy, appimagetool) are reused if they already exist

**`./build.sh rebuild`:**

- Deletes `build/gnucash-x.xx_build/` (clears the CMake cache)
- Forces a full recompilation from scratch
- **Required when you modify:**
  - CMake options in `build-gnucash.sh`
  - The `Dockerfile` (system dependencies)
  - Build scripts
- Keeps the archive and sources (no re-download)

**`./build.sh clean`:**

- Full cleanup: removes `build/`, `output/`, Docker containers and images
- Use when you want to start completely from scratch
- Tools will be re-downloaded on the next build

**`./build.sh clean-deep`:**

- Performs a standard `clean`
- Plus: clears the Docker buildkit cache (layers)
- Guarantees a "first-time" state
- **Useful for**: resolving persistent issues or freeing disk space

#### Debug mode

To enable verbose logging during compilation:

```bash
DEBUG=1 ./build.sh build
```

This will print all executed commands (`set -x`).

Useful environment variables for debugging:

- `GUILE_WARN_DEPRECATED=detailed` : Show Guile deprecation warnings
- `GNC_DEBUG=1` : Enable GnuCash debug mode
- `LD_DEBUG=libs` : Debug library loading

## Build times

| Scenario                              | Local duration | GitHub Actions duration |
| ------------------------------------- | -------------- | ----------------------- |
| First full build                      | 30–60 min      | 45–90 min               |
| Subsequent builds (with cache)        | 5–10 min       | 10–20 min               |
| Rebuild after minor modification      | 10–20 min      | 15–30 min               |

# 🎨 Build customization

## CMake options

Edit `build-gnucash.sh`:

```bash
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_PYTHON=ON \          # Python support
    -DWITH_AQBANKING=ON \       # Online banking
    -DENABLE_BINRELOC=ON        # Required for AppImage
```

After making changes, run a rebuild:

```bash
./build.sh rebuild
```

## Changing the GnuCash version

**GitHub Actions:** Edit the workflows:

```yaml
env:
  GNUCASH_VERSION: 5.15  # New version
```

**Local:** Edit `build-gnucash.sh`:

```bash
GNUCASH_VERSION="5.15"  # New version
```

# 📥 Retrieving the AppImage

### From GitHub Actions

1. "Actions" tab → Completed workflow
2. "Artifacts" section → Download
3. Or from a Release (if created via a tag)

### From a local build

Once the build is complete, the AppImage can be found at:

```bash
./output/GnuCash-x.xx-x86_64.AppImage
```

# 🚀 Using the AppImage

```bash
chmod +x ./output/GnuCash-x.xx-x86_64.AppImage
./output/GnuCash-x.xx-x86_64.AppImage
```

The AppImage is **portable** and can be copied to any recent Linux distribution (glibc 2.35+).

# 🐛 Troubleshooting

### Local debugging

### Interactive shell

To investigate issues, open a shell in the container:

```bash
./shell.sh

# Inside the container, you can:
# - Inspect the sources
cd build/gnucash-x.xx

# - View the build
cd build/gnucash-x.xx_build

# - Check dependencies
ldd build/AppDir/usr/bin/gnucash

# - Install additional tools
sudo apt update && sudo apt install vim strace

# - Manually run compilation steps
cd build/gnucash-x.xx_build
cmake /workspace/build/gnucash-x.xx -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
```

### AppImage diagnostics

```bash
./diagnose-appimage.sh output/GnuCash-5.14-x86_64.AppImage
```

### Debug mode

```bash
DEBUG=1 ./build.sh build
```

## GitHub Actions debugging

**View detailed logs:**

1. Actions → Workflow → Job → Step logs

**Enable debug mode (build-release.yml workflow):**

1. Actions → Build and Release → Run workflow
2. Check "Enable debug mode"

**Re-run with debug:**

1. Completed workflow → "Re-run jobs"
2. Check "Enable debug logging"

## Common issues

### Insufficient disk space (GitHub Actions)

The `build-release.yml` workflow cleans up automatically. If the issue persists, see [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md#troubleshooting).

### Invalid cache

```bash
./build.sh clean-deep  # Local
```

For GitHub Actions: delete the cache manually under Settings → Actions → Caches

### Segmentation fault when running the AppImage

If the AppImage crashes with "Segmentation fault", use the diagnostic script:

```bash
./diagnose-appimage.sh output/GnuCash-x.xx-x86_64.AppImage
```

This script will:

- Extract the AppImage
- Check for missing dependencies
- Test execution with strace
- Display detailed error output

**Common solutions:**

1. **Missing dependencies**: linuxdeploy should collect them automatically. Verify with:

   ```bash
   ./diagnose-appimage.sh output/GnuCash-x.xx-x86_64.AppImage
   ```

2. **Library conflict**: Try building in Debug mode:

   ```bash
   # Edit build-gnucash.sh, cmake line:
   -DCMAKE_BUILD_TYPE=Debug
   ```

3. **Python issue**: Try disabling Python:

   ```bash
   # Edit build-gnucash.sh, cmake line:
   -DWITH_PYTHON=OFF
   ```

4. **Test in the container**: Before creating the AppImage:

   ```bash
   ./shell.sh
   cd build/AppDir
   ./usr/bin/gnucash --version
   ```

### Build logs

To follow the build in real time:

```bash
docker compose up --build
```

To see only errors:

```bash
docker compose up --build 2>&1 | grep -i error
```

For verbose logs:

```bash
DEBUG=1 ./build.sh build
```

## Customization

### CMake build options

You can modify the CMake options in `build-gnucash.sh` (lines 53–58). Common options:

- `-DWITH_PYTHON=ON/OFF` : Python support (default: ON)
- `-DCMAKE_BUILD_TYPE=Release/Debug` : Build type (default: Release)
- `-DWITH_AQBANKING=ON/OFF` : Online banking support (default: ON)
- `-DENABLE_BINRELOC=ON/OFF` : Binary relocation for AppImage (default: ON, **required**)

After making changes, use `./build.sh rebuild` to force CMake reconfiguration.

# Technical architecture

### Consistent AppDir structure: /usr/local only

```
AppDir/
├── AppRun                   ← Launch script
├── gnucash.desktop         ← .desktop file (required at root)
├── gnucash.png             ← Icon (required at root)
└── usr/local/              ← All of GnuCash lives here
    ├── bin/
    │   └── gnucash         ← Main executable
    ├── lib/
    │   ├── libgnc*.so      ← GnuCash libraries
    │   └── gnucash/        ← GnuCash modules (.so and .go)
    └── share/
        ├── applications/
        ├── icons/
        └── gnucash/        ← GnuCash data
```

**Why /usr/local only?**

- ✅ Compatible with BINRELOC (binary relocation):
  With prefix=/usr, CMake's GNUInstallDirs module automatically transforms CMAKE_INSTALL_SYSCONFDIR=etc into /etc (an absolute path), following GNU standards. This breaks BINRELOC because /etc is not under the prefix.
  With /usr/local, CMake honours sysconfdir=etc and produces /usr/local/etc as expected.
- ✅ No confusion between `/usr` and `/usr/local`

### Tool cache

```
/workspace/build/
├── linuxdeploy-x86_64.AppImage    ← Downloaded once
└── appimagetool-x86_64.AppImage   ← Downloaded once

/usr/local/ (inside the Docker container)
├── bin/
│   ├── linuxdeploy      → wrapper script
│   └── appimagetool     → wrapper script
└── share/
    ├── linuxdeploy/     → fully extracted structure
    └── appimagetool/    → fully extracted structure
```

The tools are:

1. Downloaded to `/workspace/build/` (mounted volume, therefore persistent)
2. Fully extracted (all their dependencies included)
3. Installed to `/usr/local/share/` in the container with a wrapper in `/usr/local/bin/`
4. Reused on subsequent runs without re-downloading or reinstalling

## Notes

- The generated AppImage is **self-contained** and includes all dependencies
- It can be run on most modern Linux distributions (glibc 2.35+)
- The first build takes a long time, but the cache significantly speeds up subsequent ones
- Scripts can be edited live without rebuilding the Docker image
- All content (sources, build output, final artifact) is accessible on your filesystem
- The out-of-source build structure makes cleanup and debugging straightforward

## System dependencies bundled in the AppImage

The AppImage automatically includes (via linuxdeploy):

- GTK3, WebKit2, and other system library dependencies
- Guile modules and their dependencies
- GSettings schemas and required data

**Exclusions:**

- Core system libraries (libc, libm, etc.): present on all systems

## License

This project is provided as-is, without warranty. GnuCash is licensed under GPLv2+.
