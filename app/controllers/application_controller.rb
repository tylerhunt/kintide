class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern

  # changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
