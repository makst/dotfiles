#!/usr/bin/env zsh
# Shell functions for Google Cloud (docs/gcloud.md). Sourced by .zshrc with the rest of zsh/functions/*.zsh;
# each function's comment says what it does.

# setup_gcloud: installs gcloud's gke-gcloud-auth-plugin, which kubectl runs to log in to GKE clusters (and so
# `argocd --core`, through kubectl's config); without it every request fails, which some tools only report as a
# timeout. The plugin is a gcloud component, not a Homebrew package. Skipped where gcloud isn't installed (it
# comes from the Brewfile's work block).
function setup_gcloud() {
  (( $+commands[gcloud] )) || return 0
  (( $+commands[gke-gcloud-auth-plugin] )) && return 0
  gcloud components install gke-gcloud-auth-plugin --quiet
}
