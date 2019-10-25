#!/usr/bin/env ruby

require "optparse"
require "json"
require_relative "repology"
require_relative "livecheck"

Options = Struct.new(:verbose, :dry, :livecheck_file, :repology_file, :installed)

class Parser
    def self.parse(options)

        args = Options.new()

        opt_parser = OptionParser.new do |opts|
            opts.banner = "Usage: bump.rb [options]"
            opts.program_name = "Bump"

            opts.on("-h", "--help", "Prints this help") do
                puts opts
                exit
            end

            opts.on("-v", "--verbose", "Show errors and warnings.") do
                args.verbose = true
            end

            opts.on("-n", "--dry-run", "Doesn't run livecheck or make a repology api call, and runs bump-formula-pr with the \'-n\' flag.") do
                args.dry = true
            end

            opts.on("-lFILE", "--livecheck-file=FILE", "Parse a .txt file containing the output of a \'brew livecheck\' run, instead of running it.") do |filename|
                args.livecheck_file = filename 
            end

            opts.on("-rFILE", "--repology-file=FILE", "Parse a .json file containing a response from the repology api instead of calling it.") do |filename|
                args.repology_file = filename
            end

            opts.on("-i", "--livecheck-installed", "Pass the \'--installed\' flag to brew livecheck; It will only run against installed formulae.") do
                args.installed = true
            end

        end

        opt_parser.parse!(options)
        return args
    end
end

#TODO: Add unit tests instead of mock methods.
#TODO: Add more utility functions (get all urls/ checksums, use on a subset of packages / one package)
#TODO: flag to avoid/include libs
def main
    ARGV << '-h' if ARGV.empty?

    options = Parser.parse(ARGV)

    get_formulae(options)
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

    formulae.each { |formula|
        bump_formula_pr(formula)
    }
end

main()
