# frozen_string_literal: true

#
# Copyright 2015 Shawn Neal <sneal@sneal.net>
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "base64" unless defined?(Base64)
require "tmpdir" unless defined?(Dir.mktmpdir)

describe WinRM::FS::FileManager do
  # Serves a real file over the same protocol download.ps1.erb speaks, and
  # counts how many shells get opened along the way.
  let(:shells_opened) { [] }
  let(:source) { "0123456789abcdef" * 512 } # 8 KiB

  let(:shell) do
    contents = source
    shell = double("shell", logger: logger)
    allow(shell).to receive(:run) do |cmd|
      output = WinRM::Output.new
      match = cmd.match(/\$index = (\d+)\n\$chunkSize = (\d+)/)
      chunk = match ? contents.byteslice(match[1].to_i, match[2].to_i).to_s : ""
      # download.ps1.erb reads $chunk[0..$bytesRead], one byte past the data
      chunk += "\x00" unless chunk.empty?
      output << { stdout: [chunk].pack("m0") }
      output.exitcode = 0
      output
    end
    allow(shell).to receive(:close)
    shell
  end

  let(:logger) { double("logger", debug: nil, debug?: false) }

  let(:connection) do
    connection = double("connection", logger: logger)
    allow(connection).to receive(:shell) do |_type|
      shells_opened << shell
      shell
    end
    connection
  end

  subject(:file_manager) { described_class.new(connection) }

  it "downloads the whole file across multiple chunks" do
    Dir.mktmpdir do |dir|
      dest = File.join(dir, "out.bin")

      expect(file_manager.download("C:/src.bin", dest, 1024)).to eq true
      expect(File.binread(dest)).to eq source
    end
  end

  it "opens a single shell regardless of how many chunks are transferred" do
    Dir.mktmpdir do |dir|
      file_manager.download("C:/src.bin", File.join(dir, "out.bin"), 1024)
    end

    expect(shells_opened.size).to eq 1
    expect(shell).to have_received(:close).once
  end

  it "closes the shell when the transfer fails part way through" do
    failure = WinRM::Output.new
    failure.exitcode = 1
    allow(shell).to receive(:run).and_return(failure)

    Dir.mktmpdir do |dir|
      expect(file_manager.download("C:/src.bin", File.join(dir, "out.bin"), 1024)).to eq false
    end

    expect(shells_opened.size).to eq 1
    expect(shell).to have_received(:close).once
  end

  it "closes the shell when the transfer raises" do
    allow(shell).to receive(:run).and_raise(WinRM::WinRMError, "boom")

    Dir.mktmpdir do |dir|
      expect { file_manager.download("C:/src.bin", File.join(dir, "out.bin"), 1024) }
        .to raise_error(WinRM::WinRMError)
    end

    expect(shell).to have_received(:close).once
  end
end
