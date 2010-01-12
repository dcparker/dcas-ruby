require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Dcas - Comprehensive failure frequency test" do
  it "should be able to complete an entire mock procedure without failing" do
    # 1) For each location yet to be uploaded:
    #   1) Gather all clients-to-bill for this location.
    #   2) For each file type (ach, cc) yet to be uploaded:
    #     1) Create the file locally.
    #     2) Log in to FTPS.
    #     3) Create the 'uploading' folder if it's not already there.
    #     4) Delete the same filename from the 'uploading' folder if one exists.
    #     5) Upload the file into the 'uploading' folder.
    #     6) If we're still connected, check the file size of the file, then move it out of 'uploading' and mark file as completed.
    # 2) Respond with all results as JSON
    
  end
end
