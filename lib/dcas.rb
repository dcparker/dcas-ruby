module DCAS
  class << self
    def generate!(filename, payments_collection)
    end

    def parse_response_file(filename_or_content)
    end
  end

  class Client
    def initialize(options={})
      raise ArgumentError, "must include :username, :password, and :cache_location" unless options.has_key?(:username) && options.has_key?(:password) && options.has_key?(:cache_location)
      @username = options[:username]
      @password = options[:password]
      @cache_location = options[:cache_location]
    end

    attr_reader :cache_location

    def submit_file!(filename)
    end

    def submit_files!(filenames)
    end

    def available_response_files
    end

    def download_response_files!
    end

    def each_response_in(filename_or_content)
      raise ArgumentError, "must include a block!" unless block_given?
    end
  end
end
