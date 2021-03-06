require 'test_helper'

require "action_controller"
require "action_controller/test_case"

class RendersControllerTest < ActionController::TestCase
  test "render latest version of partial" do
    get :index
    assert_equal @response.body, "index.v2.html.erb"
  end

  test "exposes the requested version" do
    get :index, "api_version" => "1"
    assert_equal @controller.requested_version, 1
  end

  test "exposes latest version when requesting the latest" do
    get :index, "api_version" => "4"
    assert @controller.is_latest_version
  end

  test "reports not the latest version" do
    get :index, "api_version" => "1"
    assert !@controller.is_latest_version
  end
end

class ParameterStragegyTest < ActionController::TestCase
  tests RendersController

  setup do
    ActionView::Template::Versions.extraction_strategy = :query_parameter
  end

  test "render version 1 of the partial based on the parameter _api_version" do
    get :index, "api_version" => "1"
    assert_equal @response.body, "index.v1.html.erb"
  end

  test "render version 2 of the partial based on the parameter _api_version" do
    get :index, "api_version" => "2"
    assert_equal @response.body, "index.v2.html.erb"
  end

  test "render the latest available version (v2) of the partial based on the parameter _api_version" do
    get :index, "api_version" => "3"
    assert_equal @response.body, "index.v2.html.erb"
  end
end

class CustomHeaderStrategyTest < ActionController::TestCase
tests RendersController

  setup do
    ActionView::Template::Versions.extraction_strategy = :http_header
  end

  test "renders version 1 of the partial based on the header API-Version" do
    @controller.request.stubs(:headers).returns({"HTTP_API_VERSION" => "1"})
    get :index
    assert_equal @response.body, "index.v1.html.erb"
  end

  test "renders version 2 of the partial based on the header API-Version" do
    @controller.request.stubs(:headers).returns({"HTTP_API_VERSION" => "2"})
    get :index
    assert_equal @response.body, "index.v2.html.erb"
  end

  test "renders the latest available version (v2) of the partial based on the header API-Version" do
    @controller.request.stubs(:headers).returns({"HTTP_API_VERSION" => "3"})
    get :index
    assert_equal @response.body, "index.v2.html.erb"
  end
end

class AcceptHeaderStrategyTest < ActionController::TestCase
  tests RendersController

  setup do
    ActionView::Template::Versions.extraction_strategy = :http_accept_parameter
  end

  test "render version 1 of the partial based on the header Accept" do
    @controller.request.stubs(:headers).returns({"HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;api_version=1"})
    get :index
    assert_equal @response.body, "index.v1.html.erb"
  end

  test "render version 2 of the partial based on the header Accept" do
    @controller.request.stubs(:headers).returns({"HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;api_version=2"})
    get :index
    assert_equal @response.body, "index.v2.html.erb"
  end

  test "render the latest available version (v2) of the partial based on the header Accept" do
    @controller.request.stubs(:headers).returns({"HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;api_version=3"})
    get :index
    assert_equal @response.body, "index.v2.html.erb"
  end

  test "render the latest version of the partial" do
    @controller.request.stubs(:headers).returns({"HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;api_version=abc"})
    get :index
    assert_equal @response.body, "index.v2.html.erb"
  end
end

class CustomStrategyTest < ActionController::TestCase
  tests RendersController

  setup do
    ActionView::Template::Versions.extraction_strategy = lambda { |request| 2 }
  end

  test "renders version 2 of the partial based on the header Accept" do
    get :index
    assert_equal @response.body, "index.v2.html.erb"
  end
end

class MultipleStrategyTest < ActionController::TestCase
  tests RendersController

  setup do
    ActionView::Template::Versions.extraction_strategy = [:http_accept_parameter, :query_parameter]
  end

  test "renders version 1 of the partial based on the header Accept" do
    @controller.request.stubs(:headers).returns({"HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;api_version=1"})
    get :index
    assert_equal @response.body, "index.v1.html.erb"
  end

  test "renders the query parameter when accept parameter isn't available" do
    get :index, "api_version" => "1"
    assert_equal @response.body, "index.v1.html.erb"
  end

  test "renders the higher priority accept parameter version" do
    @controller.request.stubs(:headers).returns({"HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8;api_version=2"})
    get :index, "api_version" => "1"
    assert_equal @response.body, "index.v2.html.erb"
  end
end