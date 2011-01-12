class Restaurant < ActiveRecord::Base
  acts_as_taggable
  
  belongs_to :user
  
  has_many :portions, :dependent => :destroy
  has_many :branches, :dependent => :destroy

  has_many :ratings, :dependent => :destroy
  has_many :raters, :through => :ratings, :source => :user
  
  has_many :comments, :dependent => :destroy
  has_many :commenters, :through => :comments, :source => :user
  
  has_many :likes, :dependent => :delete_all
  has_many :fans, :through => :likes, :source => :user
  
  validates :name, :info, :presence => true

  delegate :username, :to => :user

  scope :recent, order('created_at DESC')

  def self.top(attribute, limit)
    # creates [restaurant, rating] ordered hash
    all_restaurants = Rating.group(:restaurant).average(attribute).sort {|a,b| -1*(a[1] <=> b[1])}
    all_restaurants[0..limit-1]
  end

  def self.last_added(limit)
    Restaurant.order('created_at DESC').limit(limit)
  end

  def like(user)
    unless fans.include?(user)
      like = Like.new :user => user
      likes << like
    end
  end

  def average_rating_for(attribute)
    Rating.where(:restaurant_id => self).average(attribute)
  end

  def average_rating
    return 0 if ratings.empty?
    value = 0
    total = 0
    self.ratings.each do |rating|
      value = value + rating.sum_value
      total = total + rating.dimensions
    end
    value.to_f / total.to_f
  end

  # method to get a phone number for a restaurant
  # TODO: what will be the phone number in case of multiple branches
  def phone
    branches[0].phone
  end

  def address
    branches[0].street
  end

  def add_tags(tags)
    tag_list << tags.split(',')
  end


end
