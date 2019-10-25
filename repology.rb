require "rubygems/version"
require "json"
require "net/http"
require_relative "formula"

# add arg for parsing file instead of http call?
def repology_formulae(res, options)
    formulae = []
    return formulae if res.nil?

    res.each do |name, repos|
        latest_repo = repos.reduce do |memo, repo|
            begin
                memo_version = Gem::Version.create(memo["version"])
                repo_version = Gem::Version.create(repo["version"])
                memo_version > repo_version ? memo : repo
            rescue ArgumentError => e
                memo
            end
        end
        homebrew_repo = repos.select { |repo| repo["repo"] == "homebrew" }.first
        begin
            latest = Gem::Version.create(latest_repo["version"])
            current = Gem::Version.create(homebrew_repo["version"])
            formulae << Formula.new(name, current, latest, true)
        rescue ArgumentError => e
            warn e.to_s + ": #{name}" if options.verbose
        end 
    end
    formulae
end

def repology_responses(options)
    joined_res = Hash.new
    first_package = ""
    uri = URI('https://repology.org/api/v1/projects/?inrepo=homebrew&outdated=1&families_newest=2-')
    loop do
        uri.path = '/api/v1/projects/' + first_package
        response = JSON.parse(fetch(uri).body) # This only gets up to 200 packages
        puts response if options.verbose
        joined_res.merge!(response)
        first_package = response.keys.last
        break if response.length < 200
    end
    joined_res
end  

def fetch(uri, limit = 2)
    raise ArgumentError, 'too many HTTP redirects' if limit == 0
    response = Net::HTTP.get_response(URI(uri))
    case response
    when Net::HTTPSuccess then
        response
    when Net::HTTPRedirection then
        location = URI(response['location'])
        fetch(location, limit - 1)
    else
        response.value
    end
end
