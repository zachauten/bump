#!/usr/bin/env ruby

require "optparse"
require "json"
require_relative "repology"
require_relative "livecheck"
require_relative "bump"
require_relative "formula"

Options = Struct.new(:verbose, :dry, :livecheck_file, :repology_file, :installed)

#TODO: Add unit tests instead of mock methods.
#TODO: Add more utility functions (get all urls/ checksums, use on a subset of packages / one package)
#TODO: flag to avoid/include libs
def main
    options = Options.new

    global = OptionParser.new do |opts|
        opts.banner = "Usage: main.rb [options] [subcommand [options]]"
        opts.separator ""
        opts.on("-h", "--help", "Prints this help") do
            puts opts
            exit
        end

        opts.on("-v", "--verbose", "Show errors and warnings.") do
            options.verbose = true
        end

        opts.on("-n", "--dry-run", "Doesn't run livecheck or make a repology api call, and runs bump-formula-pr with the \'-n\' flag.") do
            options.dry = true
        end

        opts.on("-lFILE", "--livecheck-file=FILE", "Parse a .txt file containing the output of a \'brew livecheck\' run, instead of running it.") do |filename|
            options.livecheck_file = filename 
        end

        opts.on("-rFILE", "--repology-file=FILE", "Parse a .json file containing a response from the repology api instead of calling it.") do |filename|
            options.repology_file = filename
        end

        opts.on("-i", "--livecheck-installed", "Pass the \'--installed\' flag to brew livecheck; It will only run against installed formulae.") do
            options.installed = true
        end
    end

    subcommands = {
        "one" => OptionParser.new do |opts|
            opts.banner = "Usage: once [name] [old_version] [new_version]"

        end
    }

    global.order!
    command = ARGV.shift
    subcommands[command].order! if subcommands[command]

    if command == "one"
        formula = Formula.new(ARGV[0], ARGV[1], ARGV[2], false)
        bump_formula_pr(formula, options)
        exit
    else
        get_formulae(options).each { |formula|
            begin
                bump_formula_pr(formula, options)
            rescue Exception => e
                STDERR.puts e.message
                next
            end
        }
    end
end

def get_formulae(options)
    repology_res = if options.repology_file
        # Don't do this with full repology response; It's a big file.
        file = File.read(options.repology_file)
        JSON.parse(file)
    else
        repology_responses(options)
    end
    repology_formulae = repology_formulae(repology_res, options)

    livecheck_output = if options.livecheck_file
        File.read(options.livecheck_file)
    else
        run_livecheck(options)
    end

    livecheck_formulae = livecheck_formulae(livecheck_output, options)

    unique_outdated_formulae = livecheck_formulae.select {|f| !f.guessed}

    # formulae that are not guessed + formulae that match between repology and livecheck.
    (unique_outdated_formulae << ((repology_formulae & livecheck_formulae).select { |f| f.outdated && !unique_outdated_formulae.include?(f) })).flatten!

    unique_outdated_formulae
end

main()
