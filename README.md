[![EdgePetrol](https://circleci.com/gh/EdgePetrol/danger-rcov.svg?style=shield)](https://app.circleci.com/pipelines/github/EdgePetrol/danger-rcov)
![EdgePetrol](https://github.com/EdgePetrol/coverage/blob/master/danger-rcov/master/badge.svg)

# danger-rcov

This plugin will provide an interface similar to codecov.

![Screenshot 2020-06-08 at 22 24 18](https://user-images.githubusercontent.com/756762/84170757-e2b8a700-aa71-11ea-8573-da077ec07267.png)



## Installation

    $ gem install danger-rcov

## Usage

  [circleCI] Inside your Dangerfile:

  ```
    # stable branch to check against (default: 'master')
    # build name (default: 'build')
    # warning (default: true)
    markdown rcov.report('master', 'build', true)
  ```

  [Others] Generic

  ```
    # current branch url to coverage.json
    # stable branch url to coverage.json
    # warning (default: true)
    markdown rcov.report_by_urls('http://current_branch/coverage.json', 'http://master_branch/coverage.json', true)
  ```
