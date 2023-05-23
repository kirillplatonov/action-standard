#!/bin/sh -e
version() {
  if [ -n "$1" ]; then
    echo "-v $1"
  fi
}

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

if [ "${INPUT_SKIP_INSTALL}" = "false" ]; then
  echo '::group:: Installing standard with plugins ... https://github.com/standardrb/standard'
  # if 'gemfile' standard version selected
  if [ "${INPUT_STANDARD_VERSION}" = "gemfile" ]; then
    # if Gemfile.lock is here
    if [ -f 'Gemfile.lock' ]; then
      # grep for standard version
      STANDARD_GEMFILE_VERSION=$(ruby -ne 'print $& if /^\s{4}standard\s\(\K.*(?=\))/' Gemfile.lock)

      # if standard version found, then pass it to the gem install
      # left it empty otherwise, so no version will be passed
      if [ -n "$STANDARD_GEMFILE_VERSION" ]; then
        STANDARD_VERSION=$STANDARD_GEMFILE_VERSION
      else
        printf "Cannot get the standard's version from Gemfile.lock. The latest version will be installed."
      fi
    else
      printf 'Gemfile.lock not found. The latest version will be installed.'
    fi
  else
    # set desired standard version
    STANDARD_VERSION=$INPUT_STANDARD_VERSION
  fi

  gem install -N standard --version "${STANDARD_VERSION}"

  # Traverse over list of standard plugins
  for plugin in $INPUT_STANDARD_PLUGINS; do
    # grep for name and version
    INPUT_STANDARD_PLUGIN_NAME=$(echo "$plugin" |awk 'BEGIN { FS = ":" } ; { print $1 }')
    INPUT_STANDARD_PLUGIN_VERSION=$(echo "$plugin" |awk 'BEGIN { FS = ":" } ; { print $2 }')

    # if version is 'gemfile'
    if [ "${INPUT_STANDARD_PLUGIN_VERSION}" = "gemfile" ]; then
      # if Gemfile.lock is here
      if [ -f 'Gemfile.lock' ]; then
        # grep for standard plugin version
        STANDARD_PLUGIN_GEMFILE_VERSION=$(ruby -ne "print $& if /^\s{4}$INPUT_STANDARD_PLUGIN_NAME\s\(\K.*(?=\))/" Gemfile.lock)

        # if standard plugin version found, then pass it to the gem install
        # left it empty otherwise, so no version will be passed
        if [ -n "$STANDARD_PLUGIN_GEMFILE_VERSION" ]; then
          STANDARD_PLUGIN_VERSION=$STANDARD_PLUGIN_GEMFILE_VERSION
        else
          printf "Cannot get the standard plugin version from Gemfile.lock. The latest version will be installed."
        fi
      else
        printf 'Gemfile.lock not found. The latest version will be installed.'
      fi
    else
      # set desired standard plugin version
      STANDARD_PLUGIN_VERSION=$INPUT_STANDARD_PLUGIN_VERSION
    fi

    # Handle plugins with no version qualifier
    if [ -z "${STANDARD_PLUGIN_VERSION}" ]; then
      unset STANDARD_PLUGIN_VERSION_FLAG
    else
      STANDARD_PLUGIN_VERSION_FLAG="--version ${STANDARD_PLUGIN_VERSION}"
    fi

    # shellcheck disable=SC2086
    gem install -N "${INPUT_STANDARD_PLUGIN_NAME}" ${STANDARD_PLUGIN_VERSION_FLAG}
  done
  echo '::endgroup::'
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

if [ "${INPUT_USE_BUNDLER}" = "false" ]; then
  BUNDLE_EXEC=""
else
  BUNDLE_EXEC="bundle exec "
fi

echo '::group:: Running standard with reviewdog 🐶 ...'
# shellcheck disable=SC2086

${BUNDLE_EXEC}standardrb ${INPUT_STANDARD_FLAGS} --require ${GITHUB_ACTION_PATH}/rdjson_formatter/rdjson_formatter.rb --format RdjsonFormatter \
  | reviewdog -f=rdjson \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

reviewdog_rc=$?
echo '::endgroup::'
exit $reviewdog_rc
