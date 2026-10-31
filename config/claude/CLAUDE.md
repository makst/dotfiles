# How I work, in every project

- **Deleting**: never `rm -rf`. Move things to the trash (`trash <path>` on macOS, `gio trash <path>` on
  Linux) so they can be put back. A hook blocks recursive `rm`.
- **Git**: work on a branch, not on the default one. Commit when I ask; merge and push only when I ask.
  Commits use my git identity; the only Claude line is the `Co-Authored-By` trailer.
