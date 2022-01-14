# frozen_string_literal: false

require "open-uri"
require "net/http"
require "circle_ci_wrapper"

module Danger
  class DangerRcov < Plugin
    # report will get the urls from circleCi trough circle_ci_wrapper gem
    def report(pull_request_target_branch_name, build_job_name)
      puts "Start debugging for pull_request_target_branch_name = #{pull_request_target_branch_name}, build_job_name = #{build_job_name}..."

      pull_request_source_branch_name = ENV["CIRCLE_BRANCH"]

      target_branch_coverage = find_latest_branch_coverage_report_with_job(pull_request_target_branch_name, build_job_name)
      source_branch_coverage = find_latest_branch_coverage_report_with_job(pull_request_source_branch_name, build_job_name)

      puts "target_branch_coverage (#{pull_request_target_branch_name}): "
      p target_branch_coverage.dig("metrics")
      p target_branch_coverage.dig("command_name")

      puts "source_branch_coverage (#{pull_request_source_branch_name}): "
      p source_branch_coverage.dig("metrics")
      p source_branch_coverage.dig("command_name")

      # report_by_urls(current_url, master_url, show_warning)
      output_report(source_branch_coverage, target_branch_coverage)
    end

    private

    def find_latest_branch_coverage_report_with_job(branch_name, build_job_name)
      gh_project = ENV["CIRCLE_PROJECT_USERNAME"]
      gh_repo = ENV["CIRCLE_PROJECT_REPONAME"]
      circleci_token = ENV["CIRCLE_TOKEN"]

      # iterate through recent builds to find the most recent completed build with coverage artifacts in the same workflow job
      number_of_build_items_per_page = 30
      page = 0
      while true
        branch_builds_api = "https://circleci.com/api/v1.1/project/github/#{gh_project}/#{gh_repo}/tree/#{branch_name}?circle-token=#{circleci_token}&limit=#{number_of_build_items_per_page}&filter=completed&offset=#{page * number_of_build_items_per_page}"
        branch_builds = JSON.parse(URI.parse(branch_builds_api).read, { max_nesting: 5 })
        if branch_builds.length == 0
          return nil
        end

        for branch_build in branch_builds
          if branch_build&.dig("workflows", "job_name") == build_job_name && branch_build&.dig("has_artifacts")
            build_number = branch_build&.dig("build_num")
            build_artifacts_api = "https://circleci.com/api/v1.1/project/github/#{gh_project}/#{gh_repo}/#{build_number}/artifacts?circle-token=#{circleci_token}"
            build_artifacts = JSON.parse(URI.parse(build_artifacts_api).read, { max_nesting: 3 })
            for build_artifact in build_artifacts
              if build_artifact.dig("path") == "coverage/coverage.json"
                artifact_file_url = build_artifact.dig("url")
                return JSON.parse(URI.parse("#{artifact_file_url}?circle-token=#{circleci_token}").read)
              end
            end
          end
        end

        page += 1
      end
    end

    def output_report(source_branch_coverage, target_branch_coverage)
      source_branch_covered_percent = source_branch_coverage&.dig("metrics", "covered_percent")&.round(2)
      source_branch_files_count = source_branch_coverage&.dig("files")&.count
      source_branch_total_lines = source_branch_coverage&.dig("metrics", "total_lines")
      source_branch_misses_count = source_branch_total_lines - source_branch_coverage&.dig("metrics", "covered_lines")

      target_branch_covered_percent = target_branch_coverage&.dig("metrics", "covered_percent")&.round(2)
      target_branch_files_count = target_branch_coverage.dig("files")&.count
      target_branch_total_lines = target_branch_coverage.dig("metrics", "total_lines")
      target_branch_misses_count = target_branch_total_lines - target_branch_coverage.dig("metrics", "covered_lines")

      message = "```diff\n@@           Coverage Diff            @@\n"
      message << "## #{justify_text("master", 16)} #{justify_text("#" + ENV["CIRCLE_PULL_REQUEST"].split("/").last, 8)} #{justify_text("+/-", 7)} #{justify_text("##", 3)}\n"
      message << separator_line
      message << new_line("Coverage", source_branch_covered_percent, target_branch_covered_percent, "%")
      message << separator_line
      message << new_line("Files", source_branch_files_count, target_branch_files_count)
      message << new_line("Lines", source_branch_total_lines, target_branch_total_lines)
      message << separator_line
      message << new_line("Misses", source_branch_misses_count, target_branch_misses_count)
      message << "```"
    end

    def separator_line
      "========================================\n"
    end

    def new_line(title, current, master, symbol = nil)
      formatter = symbol ? "%+.2f" : "%+d"
      currrent_formatted = current.to_s + symbol.to_s
      master_formatted = master ? master.to_s + symbol.to_s : "-"
      prep = calulate_prep(master_formatted, current - master)

      line = data_string(title, master_formatted, currrent_formatted, prep)
      line << justify_text(format(formatter, current - master) + symbol.to_s, 8) if prep != "  "
      line << "\n"
      line
    end

    def justify_text(string, adjust, position = "right")
      string.send(position == "right" ? :rjust : :ljust, adjust)
    end

    def data_string(title, master, current, prep)
      "#{prep}#{justify_text(title, 9, "left")} #{justify_text(master, 7)}#{justify_text(current, 9)}"
    end

    def calulate_prep(master_formatted, diff)
      return "  " if master_formatted != "-" && diff.zero?

      diff.positive? ? "+ " : "- "
    end
  end
end
