require 'open-uri'
require 'net/http'

module Danger
  class DangerRcov < Plugin
    def report(current_url:, master_url:, show_warning: true)
      # Get code coverage report as json from url
      current_report = get_report(url: current_url)

      master_report = get_report(url: master_url)

      @current_report = current_report

      @master_report = master_report

      if show_warning && master_report && master_report.dig('metrics', 'covered_percent').round(2)  > current_report.dig('metrics', 'covered_percent').round(2)
        warn("Code coverage decreased from #{master_report.dig('metrics', 'covered_percent').round(2).to_s}% to #{current_report.dig('metrics', 'covered_percent').round(2)}%")
      end

      # Output the processed report
      output_report(current_report, master_report)
    end

    private

    def get_report(url:)
      artifacts = JSON.parse(URI.parse(url).read).map { |a| a['url'] }

      coverage_url = artifacts.find { |artifact| artifact.end_with?('coverage/coverage.json') }

      return nil if !coverage_url

      uri = URI.parse("#{coverage_url}?circle-token=#{ENV['CIRCLE_TOKEN']}")

      response = Net::HTTP.get_response(uri)

      JSON.parse(response.body)
    end

    def output_report(results, master_results)
      @current_covered_percent = results.dig('metrics', 'covered_percent').round(2)
      @current_files_count = results.dig('files')&.count
      @current_total_lines = results.dig('metrics', 'total_lines')
      @current_misses_count = @current_total_lines - results.dig('metrics', 'covered_lines')

      if master_results
        @master_covered_percent = master_results.dig('metrics', 'covered_percent').round(2)
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
      message << "```"
    end

    def separator_line
      "========================================\n"
    end

    def new_line(title, current, master, symbol=nil)
      formatter = symbol ? '%+.2f' : '%+d'
      currrent_formatted = current.to_s + symbol.to_s
      master_formatted = master ? master.to_s + symbol.to_s : '-'
      prep = (master_formatted != '-' && current - master != 0) ? '+ ' : '  '

      line = data_string(title, master_formatted, currrent_formatted, prep)
      line << justify_text(sprintf(formatter, current - master) + symbol.to_s, 8) if prep == '+ '
      line << "\n"
      line
    end

    def justify_text(string, adjust, position='right')
      string.send(position == 'right' ? :rjust : :ljust, adjust)
    end

    def data_string(title, master, current, prep)
      "#{prep}#{justify_text(title, 9, 'left')} #{justify_text(master, 7)}#{justify_text(current, 9)}"
    end
  end
end
