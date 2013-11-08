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
  field :publish_year, type: String

  embeds_many :pages

  validates :publish_year, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
end

class Page
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :number, type: Integer

  embedded_in :article, inverse_of: :pages
  embeds_many :sections

  validates :number, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
end



class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Delorean::Trackable

  field :name, type: String
  field :age, type: Integer
  field :email, type: String

  validates :email, format: { with: /.+@.+\..+/, allow_nil: true }
end
