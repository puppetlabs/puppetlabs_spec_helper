# Changelog

## 0.8 (2020.11.11)

- Added support for branch coverage - thanks [@robotdana!](https://github.com/robotdana) ([#19](https://github.com/chetan/simplecov-console/pull/19))

## 0.7.2 (2020.03.05)

- Fix: table output include ([#17](https://github.com/chetan/simplecov-console/issues/17))

## 0.7.1 (2020.03.05)

- Fix: block output doesn't work with frozen string literal ([#16](https://github.com/chetan/simplecov-console/issues/16))

## 0.7 (2020.03.04)

- Added new 'block' style output option - thanks [@hpainter](https://github.com/hpainter)! ([#15](https://github.com/chetan/simplecov-console/issues/15))

## 0.6 (2019.11.08)

- Added new config options: `sort`, `show_covered`, and `max_rows`

## 0.5 (2019.05.24)

- Replaced `hirb` gem with `terminal-table` due to multiple warnings thrown ([#11](https://github.com/chetan/simplecov-console/issues/11))
- Support [disabling colorized](https://no-color.org/) output via `NO_COLOR` env var
