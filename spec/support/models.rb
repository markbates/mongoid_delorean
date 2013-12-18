class Section
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :body, type: String

  embedded_in :page, inverse_of: :sections
end

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
  embeds_one :footer
end

class Footer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String

  embedded_in :page
end

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Delorean::Trackable

  field :name, type: String
  field :age, type: Integer
end
