require "open-uri"
require_relative "formula"

def bump_formula_pr(formula, options)
    puts formula
    url = get_new_url(formula)
    checksum = get_checksum(url)
    `brew bump-formula-pr #{options.dry ? "-n" : ""} #{formula.name} --url #{url} --sha256 #{checksum} --no-browse`
end

def get_checksum(url)
    puts url
    tempfile = URI.parse(url).open
    tempfile.close
    Digest::SHA256.file(tempfile.path).hexdigest
end

def get_new_url(formula)
    File.foreach("/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/#{formula.name}.rb") { |line|
        m = line.match(/^ *url \"(.+)\",?$/)
        return m[1].gsub(formula.current_version.to_s, formula.latest_version.to_s) if m
    }
end
