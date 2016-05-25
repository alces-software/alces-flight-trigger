
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
    request_data = {
      options: {
        x: true,
        'long-option': 20,
      },
      args: [
        'first',
        'second argument',
      ],
      input: "Here is the stdin for the script",
    }.to_json

    response = @http.post('/trigger/printer', request_data)
    response_json = JSON.parse(response.body)

    expected_response = {"responses"=>[{"profile"=>"repo1", "contentType"=>"text/plain", "exitCode"=>0, "result"=>"-x\n--long-option\n20\n--\nfirst\nsecond argument\nHere is the stdin for the script\n"}, {"profile"=>"repo2", "contentType"=>"text/plain", "exitCode"=>1, "result"=>""}]}
    assert_equal response_json, expected_response
  end
end
