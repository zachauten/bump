require "open-uri"
require_relative "formula"

def bump_formula_pr(formula, options)
    url = get_new_url(formula)
    checksum = get_checksum(url)
    `brew bump-formula-pr #{options.dry? "-n" : ""} #{name} --url #{url} --sha256 #{checksum}`
end

def get_checksum(url)
    tempfile = URI.parse(fetch(url)).open
    tempfile.close
    Digest::SHA256.file(tempfile.path).hexdigest
end

def get_new_url(formula)
    File.foreach("/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/#{formula.name}.rb") { |line|
        m = line.match(/^ *url \"(.+)\",?$/)
        return m[1].gsub(formula.old_version, formula.new_version) if m
    }
end
