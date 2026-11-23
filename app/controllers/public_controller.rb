class PublicController < ApplicationController
  allow_unauthenticated_access

  include PlayerIdentification

  layout "public"
end
