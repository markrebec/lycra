class Vehicle < ActiveRecord::Base
  include Lycra::Document::Model

  def summary
    "#{name} #{description}"
  end
end
