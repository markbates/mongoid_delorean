# Mongoid::Delorean

A simple Mongoid 3 versioning system that works with embedded documents.

Tracking document changes can be really important to a lot of systems, unfortunately all of the Mongoid versioning plugins either only work with Mongoid 2.x, don't handle embedded document changes, or worse, just don't work. `Mongoid::Delorean` solves those problems.

`Mongoid::Delorean` is a simple plugin that does just what it sets out to do. It stores each version of your document as you make changes and then allows you to revert to earlier versions of the document.

If this wasn't great already, `Mongoid::Delorean` will even track changes made to any embedded documents, or documents that those embedded documents may have, and so on.

## Installation

Add this line to your application's Gemfile:

    gem 'mongoid_delorean'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid_delorean

## Usage

Using Mongoid::Delorean is very simple. Just include the `Mongoid::Delorean::Trackable` module into the `Mongoid::Document` you want to track. There is no need to include it in embedded documents, the parent document will handle that for you.

Now, when you save, or update, the parent (or any of the embedded documents) a new version will be saved for you.

### Example

```ruby
class Article
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Delorean::Trackable

  field :name, type: String
  field :summary, type: String

  embeds_many :pages
end

class Page
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  embedded_in :article, inverse_of: :pages
  embeds_many :sections
end

class Section
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :body, type: String

  embedded_in :page, inverse_of: :sections
end

a = Article.create(name: "Article 1")
a.version # => 1
page = a.pages.create(name: "Page 1")
a.version # => 2
page.update_attributes(name: "The 1st Page")
a.version # => 3
a.revert! # revert to the last version
page.reload
page.name # => "Page 1"
a.version # => 4
page.sections.create(name: "Section 1")
a.version # => 5
a.revert!(2) # revert to version 2
page.reload
a.version # => 6
page.name # => "Page 1"
page.sections.size # => 0
a.versions.size # => 6
```

If you don't want to track changes you can wrap it with `without_history_tracking`:

```ruby
a = Article.create(name: "Article 1")
a.without_history_tracking do
  a.update_attributes(name: "The Article 1")
end
a.version # => 1
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write your tests
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## Contributors

* Mark Bates
* Nick Muerdter
* Felipe Rodrigues
