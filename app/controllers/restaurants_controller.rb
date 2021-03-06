class RestaurantsController < ApplicationController
  load_and_authorize_resource :except => :tag

  add_crumb("Restaurants") { |instance| instance.send :restaurants_path }  

  def like
    if @restaurant.like(current_user)
      redirect_to @restaurant
    else
      redirect_to @restaurant, :alert => 'Voit tykätä vain kerran'
    end
  end

  # POST /restaurants/1/add_tags
  def add_tags
    @restaurant.add_tags(params[:taglist])
    @restaurant.save
    redirect_to @restaurant
  rescue ActiveRecord::RecordInvalid
    # TODO: add validation errors
    redirect_to @restaurant, :alert => 'Et voi lisätä tyhjää tagia'
  end

  def tag
    # Search all restaurants with tag
    @tag_name = params[:id]
    @restaurants_with_tag = Restaurant.tagged_with(@tag_name)
  end

  # GET /restaurants
  # GET /restaurants.xml
  def index
    limit = 5 # how many restaurants are shown on toplists
    time_limit = 7
    @top_food = Restaurant.top_by_attribute('food', limit)
    @top_service = Restaurant.top_by_attribute('service', limit)
    @top_environment = Restaurant.top_by_attribute('environment', limit)
    @last_added = Restaurant.last_added(limit)
    @best_rated = Restaurant.top_by_average_rating(limit)
    @most_rated = Restaurant.most_rated_in_n_days(time_limit, limit)
    logger.info 'Restaurant index::::'
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @restaurants }
    end
  end

  # GET /restaurants/1
  # GET /restaurants/1.xml
  def show
    @tags = @restaurant.tag_counts_on(:tags)
    @food = @restaurant.average_rating_for :food
    @environment = @restaurant.average_rating_for :environment
    @service = @restaurant.average_rating_for :service
    @rating = find_rating

    add_crumb @restaurant.name, @restaurant


    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /restaurants/new
  # GET /restaurants/new.xml
  def new
    @restaurant.branches.build
    3.times {@restaurant.restaurant_images.build}
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /restaurants/1/edit
  def edit
    @restaurant = Restaurant.find(params[:id])

    3.times { @restaurant.restaurant_images.build }

    add_crumb @restaurant.name, @restaurant
    add_crumb "edit", nil
  end

  # POST /restaurants
  # POST /restaurants.xml
  def create
    Rails.logger.info("PARAMS: #{params.inspect}")

    @restaurant = Restaurant.new(params[:restaurant])
    @restaurant.user = current_user
    if @restaurant.save
      redirect_to @restaurant, :notice => 'Ravintola lisätty'
    else
      render :action => 'new'
    end
  end

  # PUT /restaurants/1
  # PUT /restaurants/1.xml
  def update
    @restaurant = Restaurant.find(params[:id])

    respond_to do |format|
      if @restaurant.update_attributes(params[:restaurant])
        format.html { redirect_to(@restaurant, :notice => 'Restaurant was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /restaurants/1
  # DELETE /restaurants/1.xml
  def destroy
    @restaurant = Restaurant.find(params[:id])
    @restaurant.destroy
    redirect_to restaurants_path
  end

  private

  # returns the object the form is modifying: either a new rating (if the current
  # user has never rated this object before) or the user’s existing rating for
  # this object.
  def find_rating

    return Rating.new unless current_user
    if rating = current_user.ratings.find_by_restaurant_id(params[:id])
      rating
    else
      current_user.ratings.new
    end
  end


end
