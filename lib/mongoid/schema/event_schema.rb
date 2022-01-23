# frozen_string_literal: true

require 'mongoid'

class Event
  include Mongoid::Document
  field :id, type: String
  embeds_one :repo
  embeds_one :payload
  field :created_at, type: Time

  index({ id: 1 }, { unique: true, name: 'id_index' })
end

class Repo
  include Mongoid::Document
  field :id, type: String
  field :name, type: String
end

class Payload
  include Mongoid::Document
  field :push_id, type: Numeric
  field :size, type: Numeric
  field :distinct_size, type: Numeric
  field :ref, type: String
  field :head, type: String
  field :before, type: String
  embeds_many :commits
end

class Commit
  include Mongoid::Document
  field :sha, type: String
  field :message, type: String
  embeds_one :author
end

class Author
  include Mongoid::Document
  field :name, type: String
end
