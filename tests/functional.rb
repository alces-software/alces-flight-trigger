
require 'json'
require 'minitest/autorun'
require 'net/http'

describe '/trigger/:script' do

  def self.setup
    test_repos_path = File.join(File.dirname(__FILE__), 'test_repos')
    trigger_repos_path = '/opt/clusterware/var/lib/trigger'

    # Delete any existing trigger repos and replace with link to test trigger
    # repos.
    File.delete(trigger_repos_path)
    File.symlink(test_repos_path, trigger_repos_path)
  end
  setup

  before do
    @http = Net::HTTP.new('localhost', 4567)
  end

  it 'triggers scripts correctly and returns text response' do
    response = @http.post('/trigger/printer', standard_test_json)
    response_json = JSON.parse(response.body)

    expected_response = {"responses"=>[{"profile"=>"repo1", "contentType"=>"text/plain", "exitCode"=>0, "result"=>"-x\n--long-option\n20\n--\nfirst\nsecond argument\nHere is the stdin for the script\n"}, {"profile"=>"repo2", "contentType"=>"text/plain", "exitCode"=>1, "result"=>""}]}
    assert_equal response_json, expected_response
  end

  it 'returns result as json when first line is "#json"' do
    response = @http.post('/trigger/json_printer', standard_test_json)
    response_json = JSON.parse(response.body)

    expected_response = {"responses"=>[{"profile"=>"repo1", "exitCode"=>0, "contentType"=>"application/json", "result"=>{"args"=>["-x", "--long-option", "20", "--", "first", "second argument"], "stdin"=>"Here is the stdin for the script", "moreJson"=>{"foo"=>5, "bar"=>6}}}]}
    assert_equal response_json, expected_response
  end

  it 'validates request JSON contains needed properties' do
    test_json = JSON.parse(standard_test_json).
      delete_if {|k| k == 'args'}.
      to_json

    response = @http.post('/trigger/printer', test_json)
    response_json = JSON.parse(response.body)

    assert_equal '422', response.code
    assert_equal "The property '#/' did not contain a required property of 'args'",
      response_json['error']
  end

  it 'returns error if receives invalid request JSON' do
    invalid_json = 'foo'

    response = @http.post('/trigger/printer', invalid_json)
    response_json = JSON.parse(response.body)

    assert_equal '422', response.code
    assert_equal "Received invalid request JSON", response_json['error']
  end

  private

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
