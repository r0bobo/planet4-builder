#!/usr/bin/env bash
set -ex

composer_files=(
  "${HOME}/source/composer.json"
  "${HOME}/source/composer-local.json"
  "${HOME}/merge/composer.json"
  "${HOME}/merge/composer-local.json"
)

plugin_branch_env_vars=(
  "MASTER_THEME_BRANCH"
  "PLUGIN_BLOCKS_BRANCH"
  "PLUGIN_GUTENBERG_BLOCKS_BRANCH"
  "PLUGIN_ENGAGINGNETWORKS_BRANCH"
  "PLUGIN_GUTENBERG_ENGAGINGNETWORKS_BRANCH"
)

echo "rewrite_app_repos"

for plugin_branch_env_var in "${plugin_branch_env_vars[@]}"
do
  reponame=planet4-$( echo "${plugin_branch_env_var%_*}" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')

  if [ -n "${!plugin_branch_env_var}" ] ; then
    composer_dev_prefix="dev-"
    # temp solution to remove it and add it again, would be better if this script got branch without dev- before it
    branch=${!plugin_branch_env_var#"$composer_dev_prefix"}

    echo "Replacing ${reponame} with branch ${branch}"

    for f in "${composer_files[@]}"
    do
      if [ -e "$f" ]
      then
        echo " - $f"
        sed -i "s|\"greenpeace\\/${reponame}\" : \".*\",|\"greenpeace\\/${reponame}\" : \"dev-${branch}\",|g" "${f}"
      fi
    done

    #dev branches do not include the built assets, only master does.
    git clone --recurse-submodules --single-branch --branch "${branch}" https://github.com/greenpeace/"${reponame}"
    time npm ci --prefix "${reponame}" "${reponame}"
    time npm run-script --prefix "${reponame}" build
    if [[ "${reponame}" == *theme ]]; then \
        subdir="themes"; \
    else \
        subdir="plugins"; \
    fi; \
    buildDir="${HOME}/source/built-dev-assets/public/wp-content/${subdir}/${reponame}/assets/build/"
    mkdir -p "${buildDir}"
    cp -a "${reponame}/assets/build/." "${buildDir}"
    rm -rf "${reponame}"

    echo "And now, delete any cached version of this package"
    rm -rf "${HOME}/source/cache/files/greenpeace/planet4-master-theme"

  else
    echo "Nothing to replace for the ${reponame}"
  fi
done

echo "DEBUG: We will echo where master theme is defined as what: "
grep -r -H '"greenpeace/planet4-master-theme" :' ./*

