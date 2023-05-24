# GitHub Action: Run Standard with Reviewdog 🐶

This action runs [Standard Ruby](https://github.com/standardrb/standard) with
[Reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to improve
code review experience.

## Inputs

### `github_token`

`GITHUB_TOKEN`. Default is `${{ github.token }}`.

### `standard_version`

Optional. Set Standard version. Possible values:
* empty or omit: install latest version
* `gemfile`: install version from Gemfile (`Gemfile.lock` should be presented, otherwise it will fallback to latest bundler version)
* version (e.g. `1.28.2`): install said version

### `standard_plugins`

Optional. Set list of Standard plugins with versions.

By default install `standard-rails` with latest versions.
Provide desired version delimited by `:` (e.g. `standard-minitest:1.0.0`)

Possible version values:
* empty or omit: install latest version
* `standard-rails:gemfile standard-minitest:gemfile`: install version from Gemfile (`Gemfile.lock` should be presented, otherwise it will fallback to latest bundler version)
* version (e.g. `standard-rails:0.1.0 standard-minitest:1.0.0`): install said version

You can combine `gemfile`, fixed and latest bundle version as you want to.

### `standard_flags`

Optional. Standard flags. (standardrb `<standard_flags>`).

### `tool_name`

Optional. Tool name to use for reviewdog reporter. Useful when running multiple
actions with different config.

### `level`

Optional. Report level for reviewdog [`info`, `warning`, `error`].
It's same as `-level` flag of reviewdog.

### `reporter`

Optional. Reporter of reviewdog command [`github-pr-check`, `github-check`, `github-pr-review`].
The default is `github-pr-check`.

### `filter_mode`

Optional. Filtering mode for the reviewdog command [`added`, `diff_context`, `file`, `nofilter`].
Default is `added`.

### `fail_on_error`

Optional.  Exit code for reviewdog when errors are found [`true`, `false`].
Default is `false`.

### `reviewdog_flags`

Optional. Additional reviewdog flags.

### `workdir`

Optional. The directory from which to look for and run Standard. Default `.`.

### `skip_install`

Optional. Do not install Standard or its extensions. Default: `false`.

### `use_bundler`

Optional. Run Standard with bundle exec. Default: `false`.

## Example usage

You can create [Standard Configuration](https://github.com/standardrb/standard#yaml-options) and this action uses that config too.

```yml
name: reviewdog
on: [pull_request]
permissions:
  contents: read
  pull-requests: write
jobs:
  standard:
    name: runner / standard
    runs-on: ubuntu-latest
    steps:
      - name: Check out code
        uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.0.0
      - name: standard
        uses: kirillplatonov/action-standard@v1
        with:
          standard_version: gemfile
          standard_plugins: standard-rails:gemfile standard-minitest:gemfile
          reporter: github-pr-review # Default is github-pr-check
```

## License

[MIT](https://choosealicense.com/licenses/mit)
