## [0.0.7]
## [0.0.6] - 2022-01-24
### Change
- Move jekyll patch files to patch/ dir.
- Bump jekyll-wikilinks version number (0.0.10).
## [0.0.5] - 2021-11-23
### Change
- 'relatives' -> 'lineage' for tree nodes.

## [0.0.4] - 2021-11-22
### Fix
- Custom path config related fix in scripts.

## [0.0.3] - 2021-11-22
### Change
- Fix javascript inheritance.
- Decrement missing node log messages from 'warn' to 'debug'.
- Update license.
### Fix
- Display log messages related to dependencies (see [#2](https://github.com/manunamz/jekyll-graph/issues/2)).
- Custom path configs.

## [0.0.2] - 2021-09-17
### Change
- Liquid tag `force-graph` -> `jekyll_graph`.  

## [0.0.1] - 2021-09-17
- Initial release
### Added
- Migrated graph logic from [jekyll-namespaces](https://github.com/manunamz/jekyll-namespaces/) and [jekyll-wikilinks](https://github.com/manunamz/jekyll-wikilinks/) to this gem.
- Added javascript scripts for cleaner user experience (simply insert a div and subclass the javascript class to get a graph up and running).
### Changed
- Cleaned up testing
