require 'spec_helper'

describe Mongoid::Delorean::Trackable do
  
  context "simple document" do
  
    it "creates a history object" do
      expect {
        expect {
          u = User.create!(name: "Mark")
        }.to change(User, :count).by(1)
      }.to change(Mongoid::Delorean::History, :count).by(1)
    end

    it "sets the first version to 1" do
      u = User.create!(name: "Mark")
      u.version.should eql(1)
    end

    it "returns a list of the versions" do
      u = User.create!(name: "Mark")
      versions = u.versions
      versions.size.should eql(1)
      versions.first.version.should eql(1)

      u.save!
      versions = u.versions
      versions.size.should eql(2)
      versions.last.version.should eql(2)
    end

    it "does not track created_at changes" do
      u = User.create!(name: "Mark")
      version = u.versions.first
      version.altered_attributes.should_not include("created_at")
    end

    it "does not track updated_at changes" do
      u = User.create!(name: "Mark")
      u.update_attributes(age: 36)
      version = u.versions.last
      version.altered_attributes.should_not include("updated_at")
    end

    it "tracks the changes that were made" do
      u = User.create!(name: "Mark")
      version = u.versions.first
      version.altered_attributes.should eql({"_id"=>[nil, u.id], "version"=>[nil, 1], "name"=>[nil, "Mark"]})

      u.update_attributes(age: 36)
      version = u.versions.last
      version.altered_attributes.should eql({"version"=>[1, 2], "age"=>[nil, 36]})
    end

    it "tracks the full set of attributes at the time of saving" do
      u = User.create!(name: "Mark")

      version = u.versions.first
      version.full_attributes.should eql({"_id"=>u.id, "version"=>1, "name"=>"Mark"})

      u.update_attributes(age: 36)

      version = u.versions.last
      version.full_attributes.except("created_at", "updated_at").should eql({"_id"=>u.id, "version"=>2, "name"=>"Mark", "age"=>36})
    end

    describe "#without_history_tracking" do
      
      it "it doesn't track the history of the save" do
        expect {
          expect {
            u = User.new(name: "Mark")
            u.without_history_tracking do
              u.save!
            end
          }.to change(User, :count).by(1)
        }.to_not change(Mongoid::Delorean::History, :count).by(1)
      end

    end

    describe '#revert!' do
      
      it "reverts to the last version" do
        u = User.create!(name: "Mark")
        u.update_attributes(age: 36)
        u.update_attributes(name: "Mark Bates")
        u.versions.size.should eql(3)
        u.version.should eql(3)
        u.revert!
        u.version.should eql(4)
        u.name.should eql("Mark")
        u.age.should eql(36)
      end

      it "reverts to a specific version" do
        u = User.create!(name: "Mark")
        u.update_attributes(age: 36)
        u.update_attributes(name: "Mark Bates")
        u.versions.size.should eql(3)
        u.version.should eql(3)
        u.revert!(2)
        u.reload
        u.version.should eql(4)
        u.name.should eql("Mark")
        u.age.should eql(36)
      end

      it "does nothing if the specific version doesn't exist" do
        u = User.create!(name: "Mark")
        u.update_attributes(age: 36)
        u.update_attributes(name: "Mark Bates")
        u.versions.size.should eql(3)
        u.version.should eql(3)
        u.revert!(20)
        u.reload
        u.version.should eql(3)
        u.name.should eql("Mark Bates")
        u.age.should eql(36)
      end

    end

  end

  context "complex documents with embeds" do

    it "tracks the changes" do
      a = Article.create!(name: "My Article")

      version = a.versions.first
      version.altered_attributes.should eql({"_id"=>[nil, a.id], "version"=>[nil, 1], "name"=>[nil, "My Article"]})
    end

    it "tracks the changes including embedded docs" do
      a = Article.new(name: "My Article")
      page = a.pages.build(name: "Page 1")
      a.save!

      version = a.versions.first
      version.altered_attributes.should eql({"_id"=>[nil, a.id], "version"=>[nil, 1], "name"=>[nil, "My Article"], "pages"=>[{"_id"=>[nil, page.id], "name"=>[nil, "Page 1"]}]})

      page.name = "The Page 1"
      a.save!

      version = a.versions.last
      version.altered_attributes.should eql({"pages"=>[{"name"=>["Page 1", "The Page 1"]}], "version"=>[1, 2]})

      section = page.sections.build(body: "some body text")
      a.save!

      version = a.versions.last
      version.altered_attributes.should eql({"pages"=>[{"sections"=>[{"_id"=>[nil, section.id], "body"=>[nil, "some body text"]}]}], "version"=>[2, 3]})

      footer = page.build_footer(:content => "some footer text")
      a.save!

      version = a.versions.last
      version.altered_attributes.should eql({"pages"=>[{"sections"=>[{}], "footer"=>{"_id"=>[nil, footer.id], "content"=>[nil, "some footer text"]}}], "version"=>[3, 4]})
    end

    it "tracks the full set of attributes at the time of saving" do
      a = Article.create!(name: "My Article")

      version = a.versions.first
      version.full_attributes.should eql({"_id"=>a.id, "version"=>1, "name"=>"My Article", "pages"=>[]})

      a.update_attributes(summary: "Summary about the article")

      version = a.versions.last
      version.full_attributes.except("created_at", "updated_at").should eql({"_id"=>a.id, "version"=>2, "name"=>"My Article", "summary"=>"Summary about the article", "pages"=>[]})
    end

    it "tracks the full set of attributes including embeds at the time of saving" do
      a = Article.new(name: "My Article")
      page = a.pages.build(name: "Page 1")
      a.save!

      version = a.versions.first
      version.full_attributes.should eql({"_id"=>a.id, "version"=>1, "name"=>"My Article", "pages"=>[{"_id"=>page.id, "name"=>"Page 1", "sections"=>[]}]})

      a.update_attributes(summary: "Summary about the article")

      version = a.versions.last
      version.full_attributes.except("created_at", "updated_at").should eql({"_id"=>a.id, "version"=>2, "name"=>"My Article", "pages"=>[{"_id"=>page.id, "name"=>"Page 1", "sections"=>[]}], "summary"=>"Summary about the article"})
    end

    it "tracks changes when an embedded document is saved" do
      a = Article.new(name: "Article 1")
      page = a.pages.build(name: "Page 1")
      a.save!
      a.version.should eql(1)
      page.name = "The 1st Page"
      page.save!
      a.reload
      a.version.should eql(2)
      page = a.pages.first
      page.name.should eql("The 1st Page")
    end

    describe '#revert!' do
      
      it "reverts to the last version" do
        a = Article.create!(name: "My Article")
        a.pages.create!(name: "Page 1")
        a.pages.should_not be_empty
        a.revert!
        a.name.should eql("My Article")
        a.reload
        a.pages.should be_empty
      end

      it "reverts to a specific version" do
        a = Article.create!(name: "My Article")
        a.pages.build(name: "Page 1")
        a.save!
        a.pages.should_not be_empty
        page = a.pages.first
        page.name = "The 1st Page"
        a.save!
        page.sections.build(name: "Section 1")
        a.save!
        a.pages.first.sections.first.name.should eql("Section 1")
        a.revert!(3)
        page.reload
        page.name.should eql("The 1st Page")
        page.sections.should be_empty
      end

      it "does nothing if the specific version doesn't exist" do
        a = Article.create!(name: "My Article")
        a.pages.build(name: "Page 1")
        a.save!
        a.revert!(20)
        a.reload
        a.version.should eql(2)
      end

    end
    
  end

end
