# frozen_string_literal: true

require "json"
require "yaml"
require "tmpdir"
require "fileutils"
require "open3"
require "bundler"

mode = ARGV[0]
unless %w[verify regenerate].include?(mode)
  abort "Usage: #{$PROGRAM_NAME} <verify|regenerate>"
end

gem_dir = File.expand_path("..", __dir__)
results_file = File.join(gem_dir, "spec", "primer_verification.json")

Dir.mktmpdir do |clone_dir|
  puts "Cloning primer/view_components into #{clone_dir}..."
  system("git", "clone", "--depth", "1", "https://github.com/primer/view_components.git", clone_dir, exception: true)

  Dir.chdir(clone_dir) do
    puts "Configuring ViewComponentParentClasses in .rubocop.yml..."
    rubocop_yml = YAML.load_file(".rubocop.yml") || {}
    rubocop_yml["AllCops"] ||= {}
    parents = rubocop_yml["AllCops"]["ViewComponentParentClasses"] || []
    unless parents.include?("Primer::Component")
      parents << "Primer::Component"
      rubocop_yml["AllCops"]["ViewComponentParentClasses"] = parents
      File.write(".rubocop.yml", YAML.dump(rubocop_yml))
    end

    puts "Adding rubocop-view_component gem to Gemfile..."
    File.open("Gemfile", "a") { |f| f.puts "gem 'rubocop-view_component', path: '#{gem_dir}'" }

    # Use unbundled env so the Primer clone gets its own independent bundle
    Bundler.with_unbundled_env do
      puts "Running bundle install..."
      system("bundle", "install", exception: true)

      puts "Running RuboCop (ViewComponent cops only)..."
      rubocop_output, status = Open3.capture2("bundle", "exec", "rubocop", "--require", "rubocop-view_component", "--only", "ViewComponent", "--format", "json")

      puts "RuboCop exit status: #{status.exitstatus}"

      if rubocop_output.strip.empty?
        abort "ERROR: RuboCop produced no output (exit status: #{status.exitstatus})"
      end

      data = JSON.parse(rubocop_output)
      offenses = data["files"].flat_map do |file|
        file["offenses"].map do |offense|
          {
            "path" => file["path"],
            "line" => offense["location"]["start_line"],
            "cop" => offense["cop_name"],
            "message" => offense["message"]
          }
        end
      end

      current_json = "#{JSON.pretty_generate(offenses)}\n"

      case mode
      when "regenerate"
        File.write(results_file, current_json)
        puts "#{offenses.length} offense(s) written to #{results_file}"
      when "verify"
        unless File.exist?(results_file)
          abort "ERROR: #{results_file} not found. Run '#{$PROGRAM_NAME} regenerate' first."
        end

        expected_json = File.read(results_file)

        if current_json.strip == expected_json.strip
          puts "Verification passed: output matches #{results_file}"
        else
          puts "Verification failed: output differs from #{results_file}"
          expected = JSON.parse(expected_json)
          added = offenses - expected
          removed = expected - offenses

          added.each { |o| puts "  + #{o["cop"]}: #{o["path"]}:#{o["line"]}" }
          removed.each { |o| puts "  - #{o["cop"]}: #{o["path"]}:#{o["line"]}" }

          exit 1
        end
      end
    end
  end
end
