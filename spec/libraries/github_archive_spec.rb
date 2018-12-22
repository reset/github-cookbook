require 'spec_helper'

describe GithubCB::Archive do
  describe "ClassMethods" do
    describe "::new" do
      let(:fqrn) { "berkshelf/berkshelf-cookbook" }
      let(:options) { Hash.new }
      subject { described_class.new(fqrn, options) }

      its(:organization) { should eq("berkshelf") }
      its(:repo) { should eq("berkshelf-cookbook") }
      its(:host) { should eq("https://github.com") }
      its(:version) { should eq("master") }

      context "given an explicit host" do
        let(:host) { "https://github.vialstudios.com" }
        before { options[:host] = host }

        its(:host) { should eq(host) }
      end

      context "given an explicit version" do
        let(:version) { "1.2.3" }
        before { options[:version] = version }

        its(:version) { should eq(version) }
      end
    end
  end

  subject { described_class.new("berkshelf/berkshelf-cookbook") }

  describe "#download" do
    before { subject.download }

    it "creates downloads the archive into the chef cache" do
      target = File.join(Chef::Config[:file_cache_path],
        "github_deploy", "archives", "berkshelf-cookbook-master.tar.gz")

      expect(File.exist?(target)).to be_truthy
    end
  end

  describe "#downloaded?" do
    context "when the archive is present on disk" do
      before { subject.download }

      it "returns true" do
        expect(subject.downloaded?).to be_truthy
      end
    end

    context "when it is not present on disk" do
      it "returns false" do
        expect(subject.downloaded?).to be_falsey
      end
    end
  end

  describe "#extract" do
    before { subject.download }
    let(:target) { File.join(tmp_path, "berkshelf-extract") }

    it "extracts the contents of the archive into the target directory" do
      subject.extract(target)
      expect(File.exist?(File.join(target, "metadata.rb"))).to be_truthy
    end
  end
end
