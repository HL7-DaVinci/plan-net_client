require 'test_helper'

class PharmacymixControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get pharmacymix_index_url
    assert_response :success
  end

end
