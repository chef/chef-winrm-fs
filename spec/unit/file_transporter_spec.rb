# frozen_string_literal: true

#
# Author:: Fletcher (<fnichol@nichol.ca>)
#
# Copyright (C) 2015, Fletcher Nichol
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

require "base64"
require "csv"
require "digest"
require "logger"
require "stringio"
require "tempfile"
require "tmpdir"

require "chef-winrm"
require "chef-winrm/shells/power_shell"
require "chef-winrm-fs/core/file_transporter"

# FileTransporter is a protocol serializer wearing a network client's clothes:
# it turns a set of local paths into PowerShell scripts and turns the CSV those
# scripts emit back into a report. Only #run crosses the wire, so the whole
# pipeline can be exercised against a doubled shell with no Windows host.
describe WinRM::FS::Core::FileTransporter do
  let(:logged_output) { StringIO.new }
  let(:logger)        { Logger.new(logged_output) }

  # An instance_double is deliberate: it fails loudly if chef-winrm renames or
  # drops any of these, which is how the previous generation of these specs
  # silently rotted against a plain double.
  let(:shell) do
    instance_double(
      WinRM::Shells::Powershell,
      logger: logger,
      max_fragment_blob_size: 400_000
    )
  end

  let(:transporter) { described_class.new(shell) }

  # Every script handed to shell.run, in order.
  let(:executed) { [] }

  # How the fake remote host answers check_files for every requested digest.
  #   :missing     - nothing is there, upload everything
  #   :up_to_date  - the destination already matches the local digest
  let(:remote_file_state) { :missing }

  # Whether the fake remote host reports the destination as an existing folder.
  let(:target_is_folder) { false }

  let(:remote) { 'C:\dest' }

  before do
    allow(shell).to receive(:run) do |script|
      executed << script
      case script
      when /Check-Files \$hash_file/ then check_files_response(script)
      when /Decode-Files \$hash_file/ then extract_files_response(script)
      else ok_output
      end
    end
  end

  after { @tempfiles&.each(&:close!) }

  describe "uploading a single file the remote host does not have" do
    let(:content)  { "." * 12_003 }
    let(:local)    { create_tempfile("input.txt", content) }
    let(:src_sha1) { Digest::SHA1.file(local).hexdigest }

    it "renders a check_files hash table keyed by the local SHA1 digest" do
      transporter.upload(local, remote)

      expect(script_matching(/Check-Files/)).to include(<<~PS.chomp)
        @{
          "#{src_sha1}" = @{
            "target" = "#{remote}";
            "src_basename" = "#{File.basename(local)}";
            "dst" = "#{remote}"
          }
        }
      PS
    end

    it "opens a file stream at the destination and disposes of it" do
      transporter.upload(local, remote)

      expect(script_matching(/New-Object -TypeName System.IO.FileStream/))
        .to include(%{GetUnresolvedProviderPathFromPSPath("#{remote}")})
      expect(executed).to include(a_string_including("$fileStream.Dispose()"))
    end

    it "streams the file contents to the destination intact" do
      transporter.upload(local, remote)

      expect(streamed_bytes).to eq content
    end

    it "skips extract_files when no directories are being uploaded" do
      transporter.upload(local, remote)

      expect(executed).not_to include(a_string_matching(/Decode-Files/))
    end

    it "returns the Base64 transfer size and a report keyed by SHA1" do
      size, files = transporter.upload(local, remote)

      expect(size).to eq((content.bytesize / 3) * 4)
      expect(files[src_sha1]).to include(
        "src" => local,
        "dst" => remote,
        "size" => content.bytesize,
        "chk_dirty" => "True",
        "xfered" => (content.bytesize / 3) * 4
      )
    end

    it "yields upload progress for the local file" do
      progress = []
      transporter.upload(local, remote) do |xfered, total, local_path, remote_path|
        progress << [xfered, total, local_path, remote_path]
      end

      expect(progress).not_to be_empty
      expect(progress.last).to eq(
        [(content.bytesize / 3) * 4, (content.bytesize / 3) * 4, local, remote]
      )
    end
  end

  describe "uploading a single file the remote host already has" do
    let(:content)  { "." * 12_003 }
    let(:local)    { create_tempfile("input.txt", content) }
    let(:src_sha1) { Digest::SHA1.file(local).hexdigest }
    let(:remote_file_state) { :up_to_date }

    it "does not stream any file contents" do
      transporter.upload(local, remote)

      expect(streamed_bytes).to eq ""
    end

    it "reports nothing to transfer" do
      size, files = transporter.upload(local, remote)

      expect(size).to eq 0
      expect(files[src_sha1]).to include(
        "chk_dirty" => "False",
        "verifies" => "True"
      )
    end
  end

  describe "when the destination is an existing folder" do
    let(:content) { "hello" }
    let(:local)   { create_tempfile("input.txt", content) }
    let(:target_is_folder) { true }

    it "appends the source basename to the destination" do
      _, files = transporter.upload(local, remote)

      expect(files.values.first["dst"]).to eq File.join(remote, File.basename(local))
    end
  end

  describe "uploading a directory" do
    let(:src_dir) { create_tempdir("apple.txt" => "apple", "veggies/carrot.txt" => "carrot") }

    it "uploads a zip of the directory and asks the remote host to extract it" do
      _, files = transporter.upload(src_dir, remote)
      sha1, data = files.first

      expect(data["dst"]).to eq "#{remote}\\#{File.basename(src_dir)}"
      expect(data["tmpzip"]).to eq "$env:TEMP\\winrm-upload\\tmpzip-#{sha1}.zip"
      expect(script_matching(/Decode-Files/)).to include(<<~PS.chomp)
        @{
          "#{sha1}" = @{
            "dst" = "#{data["dst"]}";
            "tmpzip" = "#{data["tmpzip"]}"
          }
        }
      PS
    end

    it "checks the temporary zip rather than the destination directory" do
      _, files = transporter.upload(src_dir, remote)
      data = files.values.first

      expect(script_matching(/Check-Files/))
        .to include(%{"target" = "#{data["tmpzip"]}"})
    end

    it "streams a zip containing the directory contents" do
      transporter.upload(src_dir, remote)

      zip = Tempfile.new(["streamed", ".zip"]).tap(&:binmode)
      zip.write(streamed_bytes)
      zip.close
      expect(Zip::File.open(zip.path).map(&:name).sort).to eq %w{apple.txt veggies/carrot.txt}
      zip.unlink
    end

    it "cleans up the temporary zip once the upload finishes" do
      _, files = transporter.upload(src_dir, remote)
      data = files.values.first

      expect(data).not_to have_key("zip_io")
      expect(File.exist?(data["src_zip"])).to be false
    end
  end

  describe "uploading a StringIO" do
    let(:content)  { "hello from a buffer" }
    let(:src_sha1) { Digest::SHA1.hexdigest(content) }

    it "keys the report on the digest of the buffer contents" do
      _, files = transporter.upload(StringIO.new(content), remote)

      expect(files.keys).to eq [src_sha1]
      expect(files[src_sha1]["size"]).to eq content.bytesize
    end

    it "streams the buffer contents" do
      transporter.upload(StringIO.new(content), remote)

      expect(streamed_bytes).to eq content
    end

    it "uses the destination as the source basename" do
      transporter.upload(StringIO.new(content), remote)

      expect(script_matching(/Check-Files/)).to include(%{"src_basename" = "#{remote}"})
    end

    it "refuses to upload more than one buffer at a time" do
      expect { transporter.upload([StringIO.new("a"), StringIO.new("b")], remote) }
        .to raise_error(WinRM::FS::Core::UploadSourceError)
    end

    it "refuses to mix a buffer with a file path" do
      expect { transporter.upload([StringIO.new("a"), create_tempfile("b.txt", "b")], remote) }
        .to raise_error(WinRM::FS::Core::UploadSourceError)
    end
  end

  describe "uploading multiple files" do
    let(:locals) do
      [create_tempfile("one.txt", "one" * 100), create_tempfile("two.txt", "two" * 100)]
    end

    it "reports on every file" do
      _, files = transporter.upload(locals, remote)

      expect(files.keys).to match_array(locals.map { |l| Digest::SHA1.file(l).hexdigest })
    end

    it "checks every file in a single check_files invocation" do
      transporter.upload(locals, remote)

      expect(executed.grep(/Check-Files/).size).to eq 1
    end

    it "sums the Base64 transfer size across files" do
      size, = transporter.upload(locals, remote)

      expect(size).to eq((300 / 3 * 4) * 2)
    end
  end

  describe "when the remote host reports a failure" do
    let(:local) { create_tempfile("input.txt", "hello") }

    it "raises when check_files exits non-zero" do
      allow(shell).to receive(:run).with(/Check-Files/).and_return(failed_output(10, "Oh noes\n"))

      expect { transporter.upload(local, remote) }.to raise_error(
        WinRM::FS::Core::FileTransporterFailed, /Upload failed \(exitcode: 10\)/
      )
    end

    it "raises when check_files exits zero but writes to stderr" do
      allow(shell).to receive(:run).with(/Check-Files/).and_return(failed_output(0, "Oh noes\n"))

      expect { transporter.upload(local, remote) }.to raise_error(
        WinRM::FS::Core::FileTransporterFailed, /exitcode: 0\), but stderr present/
      )
    end

    it "raises when extract_files exits non-zero" do
      src_dir = create_tempdir("apple.txt" => "apple")
      allow(shell).to receive(:run).with(/Decode-Files/).and_return(failed_output(10, "Oh noes\n"))

      expect { transporter.upload(src_dir, remote) }.to raise_error(
        WinRM::FS::Core::FileTransporterFailed, /Upload failed \(exitcode: 10\)/
      )
    end
  end

  it "raises when the local file or directory is not found" do
    expect { transporter.upload("/a/b/c/nope", 'C:\nopeland') }.to raise_error Errno::ENOENT
  end

  it "closes the underlying shell" do
    allow(shell).to receive(:close)

    transporter.close

    expect(shell).to have_received(:close)
  end

  # -- helpers ---------------------------------------------------------------

  def check_files_columns
    %w{chk_exists src_sha1 dst_sha1 chk_dirty verifies target_is_folder}
  end

  def extract_files_columns
    %w{dst src_sha1 tmpzip}
  end

  # Answers check_files for whichever digests the transporter actually asked
  # about. Digests of zipped directories are not predictable ahead of time, so
  # the fake reads them back out of the rendered script.
  def check_files_response(script)
    up_to_date = remote_file_state == :up_to_date
    rows = parse_ps_hash(script).keys.map do |sha1|
      {
        "chk_exists" => up_to_date.to_s.capitalize,
        "src_sha1" => sha1,
        "dst_sha1" => up_to_date ? sha1 : nil,
        "chk_dirty" => (!up_to_date).to_s.capitalize,
        "verifies" => up_to_date.to_s.capitalize,
        "target_is_folder" => target_is_folder.to_s.capitalize,
      }
    end
    csv_output(check_files_columns, rows)
  end

  def extract_files_response(script)
    rows = parse_ps_hash(script).map do |sha1, entry|
      { "dst" => entry["dst"], "src_sha1" => sha1, "tmpzip" => entry["tmpzip"] }
    end
    csv_output(extract_files_columns, rows)
  end

  # Reads back the PowerShell hash table the transporter rendered, as
  # { sha1 => { "dst" => ..., "tmpzip" => ... } }.
  def parse_ps_hash(script)
    script.scan(/"([0-9a-f]{40})" = @\{([^}]*)\}/).to_h do |sha1, body|
      [sha1, body.scan(/"(\w+)" = "([^"]*)"/).to_h]
    end
  end

  def csv_output(columns, rows)
    csv = CSV.generate(force_quotes: true) do |out|
      out << columns
      rows.each { |row| out << columns.map { |column| row[column] } }
    end
    output = WinRM::Output.new
    output.exitcode = 0
    output << { stdout: csv }
    output
  end

  def ok_output
    output = WinRM::Output.new
    output.exitcode = 0
    output
  end

  def failed_output(exitcode, stderr)
    output = WinRM::Output.new
    output.exitcode = exitcode
    output << { stderr: stderr }
    output
  end

  # The Base64 payloads the transporter streamed, decoded and rejoined. This
  # asserts the contract that matters -- the bytes arrive intact -- without
  # pinning the test to a particular chunk size.
  def streamed_bytes
    executed.join.scan(/FromBase64String\('([^']*)'\)/).flatten.map do |chunk|
      Base64.decode64(chunk)
    end.join
  end

  def script_matching(regex)
    executed.grep(regex).first ||
      raise("no script matching #{regex.inspect} was run; got:\n#{executed.join("\n---\n")}")
  end

  def create_tempfile(name, content)
    pre, _, ext = name.rpartition(".")
    file = Tempfile.open(["#{pre}-", ".#{ext}"])
    (@tempfiles ||= []) << file
    file.write(content)
    file.close
    file.path
  end

  def create_tempdir(files)
    dir = Dir.mktmpdir
    files.each do |path, content|
      full = File.join(dir, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, content)
    end
    dir
  end
end
