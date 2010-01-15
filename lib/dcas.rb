require 'ftools'

module DCAS
  TESTING = false
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

    attr_reader :username, :password, :company_alias, :company_username, :company_password, :cache_location

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
    def submit_payments_file!(filename)
      shortname = filename.gsub(/.*[\\\/][^\\\/]+$/,'')
      with_ftp do |ftp|
        # 1) Create the STAGING folder if it's not already there.
        ftp.mkdir(DCAS::STAGING_BUCKET) unless ftp.nlst.include?(DCAS::STAGING_BUCKET)
        ftp.chdir(DCAS::STAGING_BUCKET)
        # 2) Delete the same filename from the STAGING folder if one exists.
        ftp.delete(shortname) if ftp.nlst.include?(shortname)
        # 3) Upload the file into the STAGING folder.
        ftp.put(filename, shortname)
        # 4) If we're still connected, check the file size of the file, then move it out of STAGING and mark file as completed.
        if ftp.nlst.include?(shortname) && ftp.size(shortname) == File.size(filename)
          ftp.rename(shortname, "../#{DCAS::OUTGOING_BUCKET}/#{shortname}") unless DCAS::TESTING
        else
          raise RuntimeError, "FAILED uploading `#{filename}' - incomplete or unsuccessful upload. Please try again."
        end
      end
      true
    end

    # Writes all batches to file and submits them to the DCAS outgoing payments bucket.
    def submit_batches!
      File.makedirs(cache_location)
      batches_submitted = 0
      with_ftp do
        # 1) Gather all payments for this client.
        batches.each do |batch| # 2) For each file type (ach, cc) yet to be uploaded:
          filename = cache_location + "/#{company_user}_#{batch.type}_#{Time.now.strftime("%Y%m%d")}.csv"
          # 1) Create the file locally.
          File.open(filename) {|f| f << batch.to_csv }
          # 2) Upload it to the DCAS outgoing payments bucket.
          batches_submitted += 1 if submit_payments_file!(filename)
        end
      end
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
        if block.arity == 1
          yield ftp_connection
        else
          yield
        end
        @inside_with_ftp -= 1
        ftp_done
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
