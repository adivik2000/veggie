class Like < ActiveRecord::Base
  belongs_to :restaurant
  belongs_to :user
  validate :user_can_like_a_restaurant_once, :on => :create

  #validation method:
  def user_can_like_a_restaurant_once
    errors.add(:restaurant, "Ravintolasta voi tykätä vain kerran") if
    Like.find_by_restaurant_id_and_user_id(restaurant, user)
  end

end