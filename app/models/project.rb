class Project < ActiveRecord::Base
  has_many :deploys

  def to_s
    name
  end
end
