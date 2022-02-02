# frozen_string_literal: false

require 'openssl'
require 'net/http'
require 'uri'

module Danger
  class DangerRcov < Plugin
    # report is called by client Dangerfiles (f.e.: https://github.com/EdgePetrol/edge-danger/blob/master/Dangerfile#L15)
    def report(pull_request_target_branch_name, build_job_name)
      target_branch_coverage = find_latest_branch_coverage_report_with_job(pull_request_target_branch_name, build_job_name)
      source_branch_coverage = find_latest_branch_coverage_report_with_job(pull_request_source_branch_name, build_job_name)

      print_report_diff({
        target: {
          branch_name: pull_request_target_branch_name,
          coverage: target_branch_coverage
        },
        source: {
          branch_name: pull_request_source_branch_name,
          coverage: source_branch_coverage
        }
      })
    end

    private

    # As the job artifacts of the current build has already been generated and persisted
    # by previous workflow job steps, we need to iterate through recent builds
    # in order to find the latest build job for the specified branch.
    #
    # We also treat the pull request target branch (e.g., staging) and the source branch
    # the same, because we assume the coverage report has already been generated for both of them
    # (i.e., it has been done sometime in the past for the target branch), and we want to compare
    # the latest coverage reports of the target branch with the pull request branch, which is
    # possibly generated in the current job run by previous steps.
    def find_latest_branch_coverage_report_with_job(branch_name, build_job_name)
      per_page_build_items = 30
      page = 0
      loop do
        branch_builds = get_branch_builds(branch_name, per_page_build_items, page * per_page_build_items)
        if branch_builds.empty?
          # Reached the end of the builds list, but couldn't find what we wanted yet.
          return nil
        end

        branch_builds.each do |branch_build|
          next unless branch_build.dig('workflows', 'job_name') == build_job_name && branch_build['has_artifacts']

          build_number = branch_build['build_num']
          build_artifacts = get_build_artifacts(build_number)
          build_artifacts['items'].each do |build_artifact|
            # We assume the coverage reports file were stored in "coverage/coverage.json" by previous steps.
            if build_artifact['path'] == 'coverage/coverage.json'
              artifact_file_url = build_artifact['url']
              return JSON.parse(get_circleci_url_with_redirect_follow(artifact_file_url).read_body)
            end
          end
        end

        # Maybe in the next builds page?
        page += 1
      end
    end

    def get_branch_builds(branch_name, limit, offset)
      # See: https://circleci.com/docs/api/#recent-builds-for-a-single-project
      url = "https://circleci.com/api/v1.1/project/github/#{github_project}/#{github_repo}/tree/#{branch_name}?circle-token=#{circleci_token}&limit=#{limit}&filter=completed&offset=#{offset}"
      JSON.parse(get_circleci_url(url).read_body, { max_nesting: 5 })
    end

    def get_build_artifacts(build_number)
      # Ref.: https://circleci.com/docs/api/v2/#operation/getJobArtifacts
      url = "https://circleci.com/api/v2/project/github/#{github_project}/#{github_repo}/#{build_number}/artifacts"
      JSON.parse(get_circleci_url(url).read_body, { max_nesting: 3 })
    end

    def get_circleci_url(url)
      uri = URI(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri)
      request['Circle-Token'] = circleci_token

      http.request(request)
    end

    def get_circleci_url_with_redirect_follow(url, max_redirects = 10)
      raise ArgumentError, 'too many HTTP redirects' if max_redirects.zero?

      response = get_circleci_url(url)

      case response
      when Net::HTTPRedirection
        location = response['location']
        get_circleci_url_with_redirect_follow(location, max_redirects - 1)
      else
        response
      end
    end

    def pull_request_source_branch_name
      ENV['CIRCLE_BRANCH']
    end

    def pull_request_id
      "##{ENV['CIRCLE_PULL_REQUEST'].split('/').last}"
    end

    def github_project
      ENV['CIRCLE_PROJECT_USERNAME']
    end

    def github_repo
      ENV['CIRCLE_PROJECT_REPONAME']
    end

    def circleci_token
      ENV['CIRCLE_TOKEN']
    end

    def print_report_diff(branch_coverage_reports)
      source_branch_coverage = branch_coverage_reports[:source][:coverage]
      source_branch_covered_percent = source_branch_coverage&.dig('metrics', 'covered_percent')&.round(2)
      source_branch_files_count = source_branch_coverage&.dig('files')&.count
      source_branch_total_lines = source_branch_coverage&.dig('metrics', 'total_lines')
      source_branch_misses_count = source_branch_total_lines - source_branch_coverage&.dig('metrics', 'covered_lines')

      target_branch_coverage = branch_coverage_reports[:target][:coverage]
      target_branch_covered_percent = target_branch_coverage&.dig('metrics', 'covered_percent')&.round(2)
      target_branch_files_count = target_branch_coverage['files']&.count
      target_branch_total_lines = target_branch_coverage.dig('metrics', 'total_lines')
      target_branch_misses_count = target_branch_total_lines - target_branch_coverage.dig('metrics', 'covered_lines')

      target_branch_name = branch_coverage_reports[:target][:branch_name]

      message = "```diff\n@@           Coverage Diff            @@\n"
      message << "## #{justify_text(target_branch_name, 16)} #{justify_text(pull_request_id, 8)} #{justify_text('+/-', 7)} #{justify_text('##', 3)}\n"
      message << separator_line
      message << new_line('Coverage', source_branch_covered_percent, target_branch_covered_percent, '%')
      message << separator_line
      message << new_line('Files', source_branch_files_count, target_branch_files_count)
      message << new_line('Lines', source_branch_total_lines, target_branch_total_lines)
      message << separator_line
      message << new_line('Misses', source_branch_misses_count, target_branch_misses_count)
      message << '```'
    end

    def separator_line
      "========================================\n"
    end

    def new_line(title, current, master, symbol = nil)
      formatter = symbol ? '%+.2f' : '%+d'
      currrent_formatted = current.to_s + symbol.to_s
      master_formatted = master ? master.to_s + symbol.to_s : '-'
      prep = calulate_prep(master_formatted, current - master)

      line = data_string(title, master_formatted, currrent_formatted, prep)
      line << justify_text(format(formatter, current - master) + symbol.to_s, 8) if prep != '  '
      line << "\n"
      line
    end

    def justify_text(string, adjust, position = 'right')
      string.send(position == 'right' ? :rjust : :ljust, adjust)
    end

    def data_string(title, master, current, prep)
      "#{prep}#{justify_text(title, 9, 'left')} #{justify_text(master, 7)}#{justify_text(current, 9)}"
    end

    def calulate_prep(master_formatted, diff)
      return '  ' if master_formatted != '-' && diff.zero?

      diff.positive? ? '+ ' : '- '
    end
  end
end
