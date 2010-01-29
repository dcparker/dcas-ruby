require 'ftools'

module DCAS
  TESTING = false
  BUCKET_HOST = 'ftp.ezpaycenters.net'
  DEFAULT_OUTGOING_BUCKET = 'outgoing'
  INCOMING_BUCKET = 'incoming'
  STAGING_BUCKET  = 'staging'
  DEFAULT_CACHE_LOCATION = 'EFT'

  class << self
    # Parses the responses from a response file and returns an array of DCAS::Response objects.
    def parse_response_file(filename_or_content)
    end
  end

  class Client
    # Instantiate a new Client object which can do authenticated actions in a DCAS FTPS bucket.
    def initialize(options={})
      raise ArgumentError, "must include :username, :password, :company_alias, :company_username, and :company_password" if [:username, :password, :company_alias, :company_username, :company_password].any? {|k| options[k].to_s.length == 0}
      @username = options[:username].to_s
      @password = options[:password].to_s
      @company_alias = options[:company_alias].to_s
      @company_username = options[:company_username].to_s
      @company_password = options[:company_password].to_s
      @cache_location = options[:cache_location].to_s || DEFAULT_CACHE_LOCATION
      @outgoing_bucket = DEFAULT_OUTGOING_BUCKET
      @testing = TESTING
    end

    attr_reader :username, :password, :company_alias, :company_username, :company_password
    attr_accessor :cache_location, :outgoing_bucket, :testing

    # :nodoc:
    def batches
      @batches ||= []
    end

    # Begin a new batch associated with this client.
    def new_batch(batch_id)
      batches << DCAS::PaymentBatch.new(self, batch_id)
      batches.last
    end

    # Uploads a single payments file to the DCAS outgoing payments bucket.
    # You can optionally supply a 'lock' object, which must respond to:
    #   #submit_locked?(filename)
    #   #submit_lock!(filename)
    #   #submit_finished!(filename)
    #   #submit_failed!(filename)
    # If a lock_object is supplied, the method will mark it as failed and return false instead of raising an error, in case of failure.
    def submit_payments_file!(filename, lock_object=nil)
      shortname = filename.match(/[\\\/]([^\\\/]+)$/)[1]
      if lock_object && lock_object.submit_locked?(shortname)
        # raise RuntimeError, "Submit for #{shortname} is locked!"
        return nil
      else
        lock_object.submit_lock!(shortname) if lock_object
        with_ftp do |ftp|
          # 1) Create the STAGING folder if it's not already there.
          begin
            ftp.mkdir(DCAS::STAGING_BUCKET) unless ftp.nlst.include?(DCAS::STAGING_BUCKET)
            ftp.chdir(DCAS::STAGING_BUCKET)
            # 2) Delete the same filename from the STAGING folder if one exists.
            ftp.delete(shortname) if ftp.nlst.include?(shortname)
            # 3) Upload the file into the STAGING folder.
            puts "Uploading #{filename} as #{shortname}..."
            ftp.put(filename, shortname)
          rescue Object
            false
          end && begin
            # 4) If we're still connected, check the file size of the file, then move it out of STAGING and mark file as completed.
            if ftp.nlst.include?(shortname) && ftp.size(shortname) == File.size(filename)
              ftp.rename(shortname, "../#{outgoing_bucket}/#{shortname}") unless testing || outgoing_bucket == DCAS::STAGING_BUCKET
              lock_object.submit_finished!(shortname) if lock_object
              true
            else
              if lock_object
                lock_object.submit_failed!(shortname)
                false
              else
                raise RuntimeError, "FAILED uploading `#{filename}' - incomplete or unsuccessful upload. Please try again."
              end
            end
          rescue Object
            false
          end
        end
      end
    end

    # Writes one batch to file and submits it to the DCAS outgoing payments bucket.
    # You can optionally supply a 'lock' object, which must respond to:
    #   #submit_locked?
    #   #submit_lock!(filename)
    #   #submit_finished!(filename)
    #   #submit_failed!(filename)
    # If a lock_object is supplied, the method will mark it as failed and return false instead of raising an error, in case of failure.
    def submit_batch!(batch, lock_object=nil)
      File.makedirs(cache_location)
      filename = cache_location + "/" + batch.filename
      # 1) Create the file locally.
      File.open(filename, 'w') {|f| f << batch.to_csv }
      # 2) Upload it to the DCAS outgoing payments bucket.
      submit_payments_file!(filename, lock_object)
    end

    # Writes all batches to file and submits them to the DCAS outgoing payments bucket.
    # You can optionally supply a 'lock' object, which must respond to:
    #   #submit_locked?
    #   #submit_lock!(filename)
    #   #submit_finished!(filename)
    #   #submit_failed!(filename)
    def submit_batches!(lock_object=nil)
      File.makedirs(cache_location)
      batches_submitted = 0
      with_ftp do # causes all batches to be uploaded in a single session
        # 1) Gather all payments for this client.
        batches.each do |batch| # 2) For each file type (ach, cc) yet to be uploaded:
          batches_submitted += 1 if submit_batch!(batch, lock_object)
        end
      end
      batches_submitted
    end

    # Checks for response files in the DCAS incoming responses bucket.
    def available_response_files
      with_ftp do |ftp|
        # 3) List the *.csv files in the INCOMING bucket.
        result = if ftp.nlst.include?(DCAS::INCOMING_BUCKET)
          ftp.chdir(DCAS::INCOMING_BUCKET)
          ftp.nlst.select {|f| f =~ /\.csv$/}
        else
          []
        end
      end
    end

    # Downloads all response files in the DCAS incoming responses bucket.
    def download_response_files!
      files_downloaded = []
      File.makedirs(cache_location + '/returns')
      with_ftp do |ftp|
        files = ftp.list('*.csv')
        files.each do |filels|
          size, file = filels.split(/ +/)[4], filels.split(/ +/)[8..-1].join(' ')
          ftp.get(file, cache_location + '/returns/' + user_suffix + '_' + file)
          files_downloaded << file
        end
      end
      files_downloaded
    end


    private
      def user_suffix
        company_username.match(/(?:malibu|maltan|malent)?(.*)(?:VT)?/)[1]
      end

      def ftp_connection
        @ftp ||= Net::FTPS::Implicit.new(DCAS::BUCKET_HOST, username, password, nil, OpenSSL::SSL::VERIFY_NONE)
      end
      # This allows all functionality to share the same connection, then log out after all work is finished.
      def with_ftp(&block)
        @inside_with_ftp = @inside_with_ftp.to_i + 1
        result = false
        begin
          result = if block.arity == 1
            yield ftp_connection
          else
            yield
          end
        rescue Object
        ensure
          @inside_with_ftp -= 1
          ftp_done
        end
        result
      end
      def ftp_done
        close_ftp if @inside_with_ftp.to_i == 0
      end
      def close_ftp
        if @ftp
          @ftp.quit
          @ftp.close
          @ftp = nil
        end
      end
  end
end

require 'dcas/payment'
require 'dcas/response'
