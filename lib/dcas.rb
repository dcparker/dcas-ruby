module DCAS
  BUCKET_HOST = 'ftp.ezpaycenters.net'
  OUTGOING_BUCKET = 'outgoing'
  INCOMING_BUCKET = 'incoming'
  STAGING_BUCKET  = 'staging'

  class << self
    # Parses the responses from a response file and returns an array of DCAS::Response objects.
    def parse_response_file(filename_or_content)
    end
  end

  class Client
    # Instantiate a new Client object which can do authenticated actions in a DCAS FTPS bucket.
    def initialize(options={})
      raise ArgumentError, "must include :username, :password, :company_alias, :company_username, :company_password, and :cache_location" if [:username, :password, :company_alias, :company_username, :company_password, :cache_location].any? {|k| !options.has_key?(k)}
      @username = options[:username]
      @password = options[:password]
      @company_alias = options[:company_alias]
      @company_username = options[:company_username]
      @company_password = options[:company_password]
      @cache_location = options[:cache_location]
    end

    attr_reader :company_alias, :company_username, :company_password, :cache_location

    def new_batch(batch_id)
      DCAS::PaymentBatch.new(self, batch_id)
    end

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

require 'dcas/payment'
