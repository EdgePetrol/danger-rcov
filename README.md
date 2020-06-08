# danger-rcov

This plugin will provide an interface similar to codecov.

![Screenshot 2020-06-08 at 22 24 18](https://user-images.githubusercontent.com/756762/84170757-e2b8a700-aa71-11ea-8573-da077ec07267.png)



## Installation

    $ gem install danger-rcov

## Usage

  Inside your Dangerfile:

  ```
    markdown rcov.report(
      current_url: "https://circleci.com/api/v1.1/project/github/#{ENV['CIRCLE_PROJECT_USERNAME']}/#{ENV['CIRCLE_PROJECT_REPONAME']}/#{ENV['CIRCLE_BUILD_NUM']}/artifacts?circle-token=#{ENV['CIRCLE_TOKEN']}",
      master_url: "https://circleci.com/api/v1.1/project/github/#{ENV['CIRCLE_PROJECT_USERNAME']}/#{ENV['CIRCLE_PROJECT_REPONAME']}/latest/artifacts?circle-token=#{ENV['CIRCLE_TOKEN']}&branch=master",
      warning: true # this will warn when the code coverage decrease!
    )
  ```
