# Copyright 2018- The Pixie Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

ENV['CLOUDSDK_CORE_DISABLE_PROMPTS'] = '1'
ENV['CLOUDSDK_INSTALL_DIR'] = '/opt'
ENV['PATH'] = "/opt/google-cloud-sdk/bin:#{ENV['PATH']}"

if node[:platform] == 'ubuntu'
  apt_pkg_list = [
    'emacs',
    'jq',
    'vim',
    'zsh',
  ]

  apt_package apt_pkg_list do
    action :upgrade
  end

  include_recipe 'px_dev::linux_gperftools'
elsif node[:platform] == 'mac_os_x' || node[:platform] == 'macos'
  homebrew_package 'emacs'
  homebrew_package 'vim'
  homebrew_package 'jq'
  homebrew_package 'gperftools'
end

remote_file '/usr/local/share/zsh/site-functions/_bazel' do
  source node['bazel']['zsh_completions']
  mode 0644
  checksum node['bazel']['zcomp_sha256']
end

remote_bin 'faq'
remote_bin 'kubectl'
remote_bin 'minikube'
remote_bin 'opm'
remote_bin 'skaffold'
remote_bin 'sops'

remote_tar_bin 'lego'

execute 'install gcloud' do
  command 'curl https://sdk.cloud.google.com | bash'
  creates '/opt/google-cloud-sdk'
  action :run
end

execute 'update gcloud' do
  command 'gcloud components update'
  action :run
end

execute 'install components' do
  command 'gcloud components install beta gke-gcloud-auth-plugin docker-credential-gcr'
  action :run
end

directory '/opt/google-cloud-sdk/.install/.backup' do
  action :delete
  recursive true
end

execute 'remove gcloud pycache' do
  action :run
  cwd '/opt/google-cloud-sdk'
  command "find . -regex '.*/__pycache__' -exec rm -r {} +"
end

execute 'configure docker-credential-gcr' do
  command 'docker-credential-gcr configure-docker'
  action :run
end

remote_file '/tmp/packer.zip' do
  source node['packer']['download_path']
  mode 0644
  checksum node['packer']['sha256']
end

execute 'install packer' do
  command 'unzip -d /opt/px_dev/tools/packer -o /tmp/packer.zip'
end

link '/opt/px_dev/bin/packer' do
  to '/opt/px_dev/tools/packer/packer'
  link_type :symbolic
  owner node['owner']
  group node['group']
  action :create
end

file '/tmp/packer.zip' do
  action :delete
end
