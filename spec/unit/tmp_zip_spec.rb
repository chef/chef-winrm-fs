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

require "chef-winrm-fs/core/tmp_zip"

describe WinRM::FS::Core::TmpZip do
  let(:src_dir) do
    tmpdir = Pathname.new(Dir.mktmpdir)
    @tmpdirs << tmpdir
    src_dir = tmpdir.join("src")
    sub_dir = src_dir.join("veggies")

    src_dir.mkpath
    create_local_file(src_dir.join("apple.txt"), "appleapple")
    create_local_file(src_dir.join("banana.txt"), "bananabanana")
    create_local_file(src_dir.join("cherry.txt"), "cherrycherry")
    create_local_file(src_dir.join(".dotfile"), "dotfiledotfile")
    sub_dir.mkpath
    create_local_file(sub_dir.join("carrot.txt"), "carrotcarrot")
    src_dir
  end

  let(:tmp_zip) { WinRM::FS::Core::TmpZip.new(src_dir) }

  before { @tmpdirs = [] }

  after do
    @tmpdirs.each(&:rmtree)
    tmp_zip.unlink if tmp_zip.path
  end

  it "#path returns path to created zip file" do
    expect(tmp_zip.path.file?).to eq true
  end

  it "#unlink removes the file" do
    path = tmp_zip.path
    expect(path.file?).to eq true

    tmp_zip.unlink

    expect(path.file?).to eq false
    expect(tmp_zip.path).to eq nil
  end

  describe "for a zip file containing the base directory" do
    let(:tmp_zip) { WinRM::FS::Core::TmpZip.new(src_dir) }

    it "contains the input entries" do
      zip = Zip::File.new(tmp_zip.path)

      expect(zip.map(&:name).sort).to eq(
        [".dotfile", "apple.txt", "banana.txt", "cherry.txt", "veggies/carrot.txt"]
      )
      expect(zip.read("apple.txt")).to eq "appleapple"
      expect(zip.read("banana.txt")).to eq "bananabanana"
      expect(zip.read("cherry.txt")).to eq "cherrycherry"
      expect(zip.read(".dotfile")).to eq "dotfiledotfile"
      expect(zip.read("veggies/carrot.txt")).to eq "carrotcarrot"
    end
  end

  describe "entry ordering" do
    # Pathname#<=> sorts "/" below every other character, so a nested entry
    # under "a/" precedes a sibling file named "a-b". Zip entry order decides
    # the archive bytes, and therefore the SHA1 the dirty check relies on, so
    # this ordering has to hold.
    let(:src_dir) do
      tmpdir = Pathname.new(Dir.mktmpdir)
      @tmpdirs << tmpdir
      src_dir = tmpdir.join("src")
      src_dir.join("a").mkpath
      create_local_file(src_dir.join("a", "b"), "nested")
      %w{a-b a.b a0b ab}.each { |name| create_local_file(src_dir.join(name), name) }
      src_dir
    end

    it "sorts nested entries ahead of sibling files that differ after the separator" do
      zip = Zip::File.new(tmp_zip.path)

      expect(zip.map(&:name)).to eq(%w{a/b a-b a.b a0b ab})
    end
  end

  describe "for a directory containing a dot-directory" do
    let(:src_dir) do
      tmpdir = Pathname.new(Dir.mktmpdir)
      @tmpdirs << tmpdir
      src_dir = tmpdir.join("src")
      src_dir.join(".hidden").mkpath
      create_local_file(src_dir.join(".dotfile"), "dotfile")
      create_local_file(src_dir.join(".hidden", "inside.txt"), "inside")
      create_local_file(src_dir.join("plain.txt"), "plain")
      src_dir
    end

    it "includes dotfiles but does not descend into dot-directories" do
      zip = Zip::File.new(tmp_zip.path)

      expect(zip.map(&:name).sort).to eq([".dotfile", "plain.txt"])
    end
  end

  def create_local_file(path, content)
    path.open("wb") { |file| file.write(content) }
  end
end
