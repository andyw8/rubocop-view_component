# frozen_string_literal: true

require "json"
require "yaml"
require "tmpdir"
require "fileutils"
require "open3"
require "bundler"

GEM_DIR = File.expand_path("..", __dir__)
RESULTS_FILE = File.join(GEM_DIR, "spec", "primer_verification.json")
REPO_URL = "https://github.com/primer/view_components.git"

def main
  mode = ARGV.include?("--regenerate") ? :regenerate : :verify

  Dir.mktmpdir do |clone_dir|
    clone_repo(clone_dir)

    Dir.chdir(clone_dir) do
      configure_rubocop
      add_gem_to_gemfile

      Bundler.with_unbundled_env do
        output = run_rubocop
        offenses = extract_offenses(output)

        case mode
        when :regenerate then regenerate(offenses)
        when :verify then verify(offenses)
        end
      end
    end
  end
end

def system!(*args)
  system(*args, exception: true)
end

def clone_repo(clone_dir)
  puts "Cloning primer/view_components into #{clone_dir}..."
  system!("git", "clone", "--depth", "1", REPO_URL, clone_dir)
end

def configure_rubocop
  puts "Configuring ViewComponentParentClasses in .rubocop.yml..."
  config = YAML.load_file(".rubocop.yml") || {}
  config["AllCops"] ||= {}
  parents = config["AllCops"]["ViewComponentParentClasses"] || []
  unless parents.include?("Primer::Component")
    parents << "Primer::Component"
    config["AllCops"]["ViewComponentParentClasses"] = parents
    File.write(".rubocop.yml", YAML.dump(config))
  end
end

def add_gem_to_gemfile
  puts "Adding rubocop-view_component gem to Gemfile..."
  File.open("Gemfile", "a") { |f| f.puts "gem 'rubocop-view_component', path: '#{GEM_DIR}'" }
end

def run_rubocop
  puts "Running bundle install..."
  system!("bundle", "install")

  puts "Running RuboCop (ViewComponent cops only)..."
  output, status = Open3.capture2(
    "bundle", "exec", "rubocop",
    "--require", "rubocop-view_component",
    "--only", "ViewComponent",
    "--format", "json"
  )

  puts "RuboCop exit status: #{status.exitstatus}"

  if output.strip.empty?
    abort "ERROR: RuboCop produced no output (exit status: #{status.exitstatus})"
  end

  output
end

def extract_offenses(rubocop_output)
  data = JSON.parse(rubocop_output)
  data["files"].flat_map do |file|
    file["offenses"].map do |offense|
      {
        "path" => file["path"],
        "line" => offense["location"]["start_line"],
        "cop" => offense["cop_name"],
        "message" => offense["message"]
      }
    end
  end
end

def regenerate(offenses)
  json = "#{JSON.pretty_generate(offenses)}\n"
  File.write(RESULTS_FILE, json)
  puts "#{offenses.length} offense(s) written to #{RESULTS_FILE}"
end

def verify(offenses)
  unless File.exist?(RESULTS_FILE)
    abort "ERROR: #{RESULTS_FILE} not found. Run '#{$PROGRAM_NAME} --regenerate' first."
  end

  current_json = JSON.pretty_generate(offenses)
  expected_json = File.read(RESULTS_FILE)

  if current_json.strip == expected_json.strip
    puts "Verification passed: output matches #{RESULTS_FILE}"
  else
    puts "Verification failed: output differs from #{RESULTS_FILE}"
    expected = JSON.parse(expected_json)
    added = offenses - expected
    removed = expected - offenses

    added.each { |o| puts "  + #{o["cop"]}: #{o["path"]}:#{o["line"]}" }
    removed.each { |o| puts "  - #{o["cop"]}: #{o["path"]}:#{o["line"]}" }

    exit 1
  end
end

main
