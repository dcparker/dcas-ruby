module DCAS
  OUTGOING_BUCKET = 'outgoing'
  INCOMING_BUCKET = 'incoming'
  STAGING_BUCKET  = 'staging'

  class << self
    # Generates a payment batch file and returns its contents.
    def generate!(payments_collection)
      type = payments_collection.first.class
      raise ArgumentError, "payments_collection given was not a uniform type of payment" unless payments_collection.all? {|p| p.class == type}
    end

    # Parses the responses from a response file and returns an array of DCAS::Response objects.
    def parse_response_file(filename_or_content)
    end
  end

  class Client
    # Instantiate a new Client object which can do authenticated actions in a DCAS FTPS bucket.
    def initialize(options={})
      raise ArgumentError, "must include :username, :password, and :cache_location" unless options.has_key?(:username) && options.has_key?(:password) && options.has_key?(:cache_location)
      @username = options[:username]
      @password = options[:password]
      @cache_location = options[:cache_location]
    end

    attr_reader :cache_location

    # Submits a single file to the DCAS outgoing payments bucket.
    def submit_file!(filename)
      submit_files!([filename])
    end

    # Submits several files to the DCAS outgoing payments bucket.
    def submit_files!(filenames)
      # 1) Gather all clients-to-bill for this location.
      # 2) For each file type (ach, cc) yet to be uploaded:
      #   1) Create the file locally.
      #   2) Log in to FTPS.
      #   3) Create the 'uploading' folder if it's not already there.
      #   4) Delete the same filename from the 'uploading' folder if one exists.
      #   5) Upload the file into the 'uploading' folder.
      #   6) If we're still connected, check the file size of the file, then move it out of 'uploading' and mark file as completed.
    end

    # Checks for response files in the DCAS incoming responses bucket.
    def available_response_files
    end

    # Downloads all response files in the DCAS incoming responses bucket.
    def download_response_files!
    end

    # Runs the given block for each response in the given response file.
    def each_response_in(filename_or_content)
      raise ArgumentError, "must include a block!" unless block_given?
    end
  end
end
