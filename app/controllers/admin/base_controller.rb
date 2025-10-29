class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  private

  def ensure_admin
    # For now, just check if user is admin or has an admin role
    # You might want to implement a proper admin role system
    unless current_user.email.end_with?('@heymarketers.com') || current_user.email == 'admin@example.com'
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
end