# add arg for parsig from file or running command internally.
def livecheck_formulae(livecheck_output, options)
    formulae = []
    return formulae if livecheck_output.nil?
    livecheck_output.each_line do |line|
        /(?<name>[\.\w@-]+)\s(?<guessed>(\(guessed\)\s)?):\s(?<current>.+)\s==>\s(?<latest>.+)\n/ =~ line        
        begin
            next if name.nil? || current.nil? || latest.nil?
            current_version = Gem::Version.create(current)
            latest_version = Gem::Version.create(latest)
            guessed = guessed.eql?("(guessed) ")
            formulae << Formula.new(name, current_version, latest_version, guessed)
        rescue ArgumentError => e
            warn e.to_s + ": #{name}" if options.verbose
        end
    end
    formulae
end

def run_livecheck(options)
    `brew livecheck --newer-only #{options.installed ? '--installed' : '--all'} #{options.verbose ? '' : '--quieter'}`
end
