# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

gem 'rb-readline'

if RUBY_PLATFORM.match?(/mswin|mingw|windows/)
    gem "chef-winrm", git: "https://github.com/chef/chef-winrm.git", branch: "jfm/chef-winrm-update"
end
