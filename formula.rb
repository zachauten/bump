class Formula
    attr_accessor :name
    attr_accessor :current_version
    attr_accessor :latest_version
    attr_accessor :guessed

    #TODO: Maybe when one version has a decimal and the other doesn't, invalidate the formula?
    def initialize(name, current_version, latest_version, guessed)
        @name = name
        @current_version = current_version
        @latest_version = latest_version
        @guessed = guessed
    end

    def outdated()
        current_version < latest_version
    end

    def eql?(other)
        self.name == other.name
        self.latest_version == other.latest_version
    end

    def to_s
        "#{self.name} #{self.current_version} #{self.latest_version} #{guessed}"
    end
end

