class Store < ActiveRecord::Base
  has_and_belongs_to_many :flavors

  def address
    "#{street}, #{city}, #{state} #{zipcode}"
  end
end
