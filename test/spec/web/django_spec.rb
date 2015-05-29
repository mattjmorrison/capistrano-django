require 'spec_helper'

path = '/var/www/current'
manage_py = "#{path}/virtualenv/bin/python #{path}/manage.py"

describe file("#{path}/virtualenv") do
  it { should be_directory }
end

describe file("#{path}/test_deploy/settings/deployed.py") do
  it { should be_file }
end

describe file("#{path}/test_deploy/live.wsgi") do
  it { should be_file }
end

describe file('/home/vagrant/static') do
  it { should be_directory }
end

describe command("#{manage_py} production migrate --list") do
  its(:stdout) { should_not contain '\[ \]' }
end

# describe command("#{manage_py} production display_s3_settings") do
#   its(:stdout) { should match %r|^STATIC_URL = https://s3.amazonaws.com/my-bucket-prefix-\d{14}/$| }
#   its(:stdout) { should match /^AWS_ACCESS_KEY_ID = asdf$/ }
#   its(:stdout) { should match /^AWS_SECRET_ACCESS_KEY = wxyz$/ }
#   its(:stdout) { should match /^AWS_STORAGE_BUCKET_NAME = my-bucket-prefix-\d{14}$/ }
# end

