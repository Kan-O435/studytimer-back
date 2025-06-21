class ApplicationController < ActionController::API
        include DeviseTokenAuth::Concerns::SetUserByToken
        alias_method :current_api_v1_user,:current_user
end
