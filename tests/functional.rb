
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
    response = make_request('printer', standard_test_json)
    response_json = JSON.parse(response.body)

    expected_response = {"responses"=>[{"profile"=>"repo1", "contentType"=>"text/plain", "exitCode"=>0, "result"=>"-x\n--long-option\n20\n--\nfirst\nsecond argument\nHere is the stdin for the script\n"}, {"profile"=>"repo2", "contentType"=>"text/plain", "exitCode"=>1, "result"=>""}]}
    assert_equal response_json, expected_response
  end

  it 'returns result as json when first line is "#json"' do
    response = make_request('json_printer', standard_test_json)
    response_json = JSON.parse(response.body)

    expected_response = {"responses"=>[{"profile"=>"repo1", "exitCode"=>0, "contentType"=>"application/json", "result"=>{"args"=>["-x", "--long-option", "20", "--", "first", "second argument"], "stdin"=>"Here is the stdin for the script", "moreJson"=>{"foo"=>5, "bar"=>6}}}]}
    assert_equal response_json, expected_response
  end

  it 'validates request JSON contains needed properties' do
    test_json = JSON.parse(standard_test_json).
      delete_if {|k| k == 'args'}.
      to_json

    response = make_request('printer', test_json)
    response_json = JSON.parse(response.body)

    assert_equal '422', response.code
    assert_equal "The property '#/' did not contain a required property of 'args'",
      response_json['error']
  end

  it 'returns overall error if receives invalid request JSON' do
    invalid_json = 'foo'

    response = make_request('printer', invalid_json)
    response_json = JSON.parse(response.body)

    assert_equal '422', response.code
    assert_equal "Received invalid request JSON", response_json['error']
  end

  it 'returns trigger-level error if trigger script gives error' do
    response = make_request('bad_interpreter', standard_test_json)
    response_json = JSON.parse(response.body)
    trigger_response = response_json['responses'].first

    # Overall request is successful.
    assert_equal '200', response.code

    # Only makes sense for trigger response to have these keys.
    assert_equal ['profile', 'error'], trigger_response.keys
  end

  private

  def make_request(trigger, data)
    uri = URI.join(TEST_URI, '/trigger/', trigger)
    request = Net::HTTP::Post.new(uri)
    request.body = data

    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  end

  def standard_test_json
    load_test_data('standard.json')
  end

  def load_test_data(filename)
    File.read(File.join(test_data_path, filename))
  end

  def test_data_path
    File.join(File.dirname(__FILE__), 'test_data')
  end
end
