require 'spec_helper'

describe GithubCB::Asset do
  describe "ClassMethods" do
    describe "::new" do
      let(:fqrn) { "berkshelf/berkshelf-cookbook" }
      let(:options) { {
        :release => "v0.3.1",
        :name => "cookbooks.tar.gz"
      } }
      subject { described_class.new(fqrn, options) }

      its(:organization) { should eq("berkshelf") }
      its(:repo) { should eq("berkshelf-cookbook") }
      its(:host) { should eq("https://github.com") }
      its(:tag_name) { should eq("v0.3.1") }
      its(:name) { should eq("cookbooks.tar.gz") }
    end
  end

  subject { described_class.new("berkshelf/berkshelf-cookbook", {
    :release => "v0.3.1",
    :name => "cookbooks.tar.gz"
  })}

  describe "#asset_url" do
    let(:options) { {
    } }
    it "gets the url of the asset" do
        expect(subject.asset_url(options)).not_to be_empty
    end
  end
end
