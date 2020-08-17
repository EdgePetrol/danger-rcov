# frozen_string_literal: true

danger.import_plugin('../lib/rcov/plugin.rb')

if ENV['CIRCLE_TOKEN']
  markdown rcov.report(
    current_url: "https://circleci.com/api/v1.1/project/github/#{ENV['CIRCLE_PROJECT_USERNAME']}/#{ENV['CIRCLE_PROJECT_REPONAME']}/#{ENV['CIRCLE_BUILD_NUM']}/artifacts?circle-token=#{ENV['CIRCLE_TOKEN']}",
    master_url: "https://circleci.com/api/v1.1/project/github/#{ENV['CIRCLE_PROJECT_USERNAME']}/#{ENV['CIRCLE_PROJECT_REPONAME']}/latest/artifacts?circle-token=#{ENV['CIRCLE_TOKEN']}&branch=master"
  )
end
