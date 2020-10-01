# frozen_string_literal: false

require 'open-uri'
require 'net/http'
require 'circle_ci_wrapper'

module Danger
  class DangerRcov < Plugin
    # report will get the urls from circleCi trough circle_ci_wrapper gem
    def report(branch_name = 'master', build_name = 'build', show_warning = true)
      current_url, master_url = CircleCiWrapper.report_urls_by_branch(branch_name, build_name)

      report_by_urls(current_url, master_url, show_warning)
    end

    def report_by_urls(current_url, master_url, show_warning = true)
      # Get code coverage report as json from url
      @current_report = get_report(url: current_url)
      @master_report = get_report(url: master_url)

      if show_warning && @master_report && @master_report.dig('metrics', 'covered_percent').round(2) > @current_report.dig('metrics', 'covered_percent').round(2)
        warn("Code coverage decreased from #{@master_report.dig('metrics', 'covered_percent').round(2)}% to #{@current_report.dig('metrics', 'covered_percent').round(2)}%")
      end

      # Output the processed report
      output_report(@current_report, @master_report)
    end

    private

    def get_report(url:)
      JSON.parse(URI.parse(url).read) if url
    end

    def output_report(results, master_results)
      @current_covered_percent = results&.dig('metrics', 'covered_percent')&.round(2)
      @current_files_count = results&.dig('files')&.count
      @current_total_lines = results&.dig('metrics', 'total_lines')
      @current_misses_count = @current_total_lines - results&.dig('metrics', 'covered_lines')

      if master_results
        @master_covered_percent = master_results&.dig('metrics', 'covered_percent')&.round(2)
        @master_files_count = master_results.dig('files')&.count
        @master_total_lines = master_results.dig('metrics', 'total_lines')
        @master_misses_count = @master_total_lines - master_results.dig('metrics', 'covered_lines')
      end

      message = "```diff\n@@           Coverage Diff            @@\n"
      message << "## #{justify_text('master', 16)} #{justify_text('#' + ENV['CIRCLE_PULL_REQUEST'].split('/').last, 8)} #{justify_text('+/-', 7)} #{justify_text('##', 3)}\n"
      message << separator_line
      message << new_line('Coverage', @current_covered_percent, @master_covered_percent, '%')
      message << separator_line
      message << new_line('Files', @current_files_count, @master_files_count)
      message << new_line('Lines', @current_total_lines, @master_total_lines)
      message << separator_line
      message << new_line('Misses', @current_misses_count, @master_misses_count)
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
