#!/usr/bin/env bash
set -ex

files=(
  "${HOME}/source/composer.json"
  "${HOME}/source/composer-local.json"
  "${HOME}/merge/composer.json"
  "${HOME}/merge/composer-local.json"
)

branches=(
  "MASTER_THEME_BRANCH"
  "PLUGIN_BLOCKS_BRANCH"
  "PLUGIN_GUTENBERG_BLOCKS_BRANCH"
  "PLUGIN_ENGAGINGNETWORKS_BRANCH"
  "PLUGIN_GUTENBERG_ENGAGINGNETWORKS_BRANCH"
)

echo "rewrite_app_repos"

for branch in "${branches[@]}"
do
  reponame=planet4-$( echo "${branch%_*}" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
  composer_dev_prefix="dev-"
  # temp solution, would be better if this script got branch without dev- before it
  git_branch=${!branch#"$composer_dev_prefix"}

  if [ -n "${!branch}" ] ; then

    echo "Replacing ${reponame} with branch ${!branch}"

    for f in "${files[@]}"
    do
      if [ -e "$f" ]
      then
        echo " - $f"
        sed -i "s|\"greenpeace\\/${reponame}\" : \".*\",|\"greenpeace\\/${reponame}\" : \"${!branch}\",|g" "${f}"
      fi
    done

    #dev branches do not include the built assets, only master does.
    git clone --recurse-submodules --single-branch --branch "${git_branch}" https://github.com/greenpeace/"${reponame}"
    time npm ci --prefix "${reponame}" "${reponame}"
    time npm run-script --prefix "${reponame}" build
    mkdir -p "${HOME}/source/built-dev-assets/${reponame}"
    cp -a "${reponame}/assets/build/." "${HOME}/source/built-dev-assets/${reponame}"
    rm -rf "${reponame}"

    echo "And now, delete any cached version of this package"
    rm -rf "${HOME}/source/cache/files/greenpeace/planet4-master-theme"

  else
    echo "Nothing to replace for the ${reponame}"
  fi
done

echo "DEBUG: We will echo where master theme is defined as what: "
grep -r -H '"greenpeace/planet4-master-theme" :' ./*

