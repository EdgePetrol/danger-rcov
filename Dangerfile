# frozen_string_literal: true

danger.import_plugin('../lib/rcov/plugin.rb')

if ENV['CIRCLE_TOKEN']
  markdown rcov.report('master')
end
