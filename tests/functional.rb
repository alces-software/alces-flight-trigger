
require 'json'
require 'minitest/autorun'
require 'net/http'

describe '/trigger/:script' do

  TEST_URI = 'http://localhost:4567'

  def self.setup
    test_repos_path = File.join(File.dirname(__FILE__), 'test_repos')
    trigger_repos_path = '/opt/clusterware/var/lib/trigger'

    # Delete any existing trigger repos and replace with link to test trigger
    # repos.
    File.delete(trigger_repos_path)
    File.symlink(test_repos_path, trigger_repos_path)
  end
  setup

  it 'triggers scripts correctly and returns text response' do
    make_authenticated_request

    assert_success

    expected_response = {"responses"=>[{"profile"=>"repo1", "contentType"=>"text/plain", "exitCode"=>0, "result"=>"-x\n--long-option\n20\n--\nfirst\nsecond argument\nHere is the stdin for the script\n"}, {"profile"=>"repo2", "contentType"=>"text/plain", "exitCode"=>1, "result"=>""}]}
    assert_equal response_json, expected_response
  end

  it 'returns result as json when first line is "#json"' do
    @trigger = 'json_printer'
    make_authenticated_request

    assert_success

    expected_response = {"responses"=>[{"profile"=>"repo1", "exitCode"=>0, "contentType"=>"application/json", "result"=>{"args"=>["-x", "--long-option", "20", "--", "first", "second argument"], "stdin"=>"Here is the stdin for the script", "moreJson"=>{"foo"=>5, "bar"=>6}}}]}
    assert_equal response_json, expected_response
  end

  it 'validates request JSON contains needed properties' do
    @test_data = JSON.parse(standard_test_json).
      delete_if {|k| k == 'args'}.
      to_json
    make_authenticated_request

    assert_unprocessable_entity
    assert_equal "The property '#/' did not contain a required property of 'args'",
      response_json['error']
  end

  it 'returns overall error if receives invalid request JSON' do
    @test_data = 'foo'
    make_authenticated_request

    assert_unprocessable_entity
    assert_equal "Received invalid request JSON", response_json['error']
  end

  it 'returns trigger-level error if trigger script gives error' do
    @trigger = 'bad_interpreter'
    make_authenticated_request

    # Overall request should be successful.
    assert_success

    trigger_response = response_json['responses'].first

    # Only makes sense for trigger response to have these keys.
    assert_equal ['profile', 'error'], trigger_response.keys
  end

  it 'returns unauthorized if credentials not supplied' do
    make_unauthenticated_request
    assert_unauthorized
  end

  it 'returns unauthorized if invalid credentials supplied' do
    make_request_with_invalid_credentials
    assert_unauthorized
  end

  private

  def make_authenticated_request
    @request = request.tap do |request|
      request.basic_auth 'test_username', 'test_password'
    end
    make_request
  end

  def make_request_with_invalid_credentials
    @request = request.tap do |request|
      request.basic_auth 'bad_username', 'bad_password'
    end
    make_request
  end

  def test_data
    @test_data ||= standard_test_json
  end

  def uri
    @uri ||= URI.join(TEST_URI, '/trigger/', trigger)
  end

  def trigger
    @trigger ||= 'printer'
  end

  def request
    @request ||= Net::HTTP::Post.new(uri).tap do |request|
      request.body = test_data
    end
  end

  def make_request
    @response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  end
  alias make_unauthenticated_request make_request

  def standard_test_json
    load_test_data('standard.json')
  end

  def load_test_data(filename)
    File.read(File.join(test_data_path, filename))
  end

  def test_data_path
    File.join(File.dirname(__FILE__), 'test_data')
  end

  def response_json
    JSON.parse(@response.body)
  end

  def assert_success
    assert_equal '200', @response.code
  end

  def assert_unprocessable_entity
    assert_equal '422', @response.code
  end

  def assert_unauthorized
    assert_equal '401', @response.code
  end
end
