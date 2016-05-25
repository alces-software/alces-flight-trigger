
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
