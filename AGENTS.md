# omarchy-drift

Omarchy shell service plugin: animated gradient wallpaper (shader). See README.md for use.

- Edit `shaders/drift.frag`, then run `scripts/build-shaders.sh` and commit the `.qsb` too.
- Test with the devkit's nested session (`DEVKIT_APP_ROOT=$PWD ../omarchy-plugin-devkit/bin/dev up`); it never touches the real shell. Look with `dev shot`.
- Never name a property `enabled` (it shadows Item.enabled and the plugin fails to load).
- Notes outside the repo: workbench/omarchy-drift.
