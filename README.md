# Mesa-AAR-Builder

Pulls native libs from MojoLauncher's nightly APK that are missing from Copper's
`app_pojavlauncher/libs`, and packages them into `mesa.aar`.

Libs bundled:
- `libEGL_mesa.so` (all ABIs)
- `libgallium_dri.so` (all ABIs)
- `libdrm.so` (all ABIs)
- `libvulkan_freedreno.so` (arm64-v8a only)

## Workflow

`.github/workflows/build-aar.yml` runs daily at 03:00 UTC and on manual dispatch.
Each run downloads the current Mojo nightly APK, extracts the libs above, builds
`mesa.aar`, and uploads it as a workflow artifact (kept 14 days). No releases are
created — grab it from the Actions run's artifact list.

## Using the AAR in Copper

Drop `mesa.aar` into `app_pojavlauncher/libs/` and add it as a dependency, e.g. in
`app_pojavlauncher/build.gradle`:

```gradle
dependencies {
    implementation files('libs/mesa.aar')
}
```

Gradle will merge the `jni/<abi>/*.so` entries into the final APK at build time.

## Local build

```bash
scripts/build_aar.sh
```

Produces `out/mesa.aar`.

## Updating the lib list

Edit `LIBS_ALL_ABI` / `LIBS_ARM64_ONLY` in `scripts/build_aar.sh` if Copper's own
native libs change and the missing-lib set shifts.
