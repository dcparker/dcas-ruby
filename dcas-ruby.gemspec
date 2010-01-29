# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dcas-ruby}
  s.version = "0.3.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["BehindLogic"]
  s.date = %q{2010-01-29}
  s.description = %q{Ruby codebase for creating payment batch files for DCAS, uploading them, and receiving response files from DCAS.}
  s.email = %q{gems@behindlogic.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "API.rdoc",
     "HISTORY.rdoc",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "dcas-ruby.gemspec",
     "lib/dcas.rb",
     "lib/dcas/ach_response.rb",
     "lib/dcas/ach_return.rb",
     "lib/dcas/payment.rb",
     "lib/dcas/response.rb",
     "lib/net/ftps_implicit.rb",
     "spec/dcas/response_spec.rb",
     "spec/dcas_spec.rb",
     "spec/fixtures/ach_first_response.csv.sample",
     "spec/fixtures/ach_payments.csv",
     "spec/fixtures/ach_payments.yml",
     "spec/fixtures/ach_second_response.csv.sample",
     "spec/fixtures/cc_response.csv.sample",
     "spec/fixtures/clients.yml.sample",
     "spec/fixtures/credit_card_payments.csv",
     "spec/fixtures/credit_card_payments.yml",
     "spec/fixtures/test_upload0.txt",
     "spec/fixtures/test_upload1.txt",
     "spec/fixtures/test_upload2.txt",
     "spec/fixtures/test_upload3.txt",
     "spec/fixtures/test_upload4.txt",
     "spec/fixtures/test_upload5.txt",
     "spec/fixtures/test_upload6.txt",
     "spec/fixtures/test_upload7.txt",
     "spec/fixtures/test_upload8.txt",
     "spec/fixtures/test_upload9.txt",
     "spec/ftps_implicit_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/dcparker/dcas-ruby}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Ruby codebase for managing payments with DCAS.}
  s.test_files = [
    "spec/dcas/response_spec.rb",
     "spec/dcas_spec.rb",
     "spec/ftps_implicit_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<fastercsv>, [">= 0"])
    else
      s.add_dependency(%q<fastercsv>, [">= 0"])
    end
  else
    s.add_dependency(%q<fastercsv>, [">= 0"])
  end
end

