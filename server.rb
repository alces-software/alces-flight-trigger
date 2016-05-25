
require 'json'
require 'sinatra'
require 'open3'

TRIGGER_REPOS_DIR = "/opt/clusterware/var/lib/trigger/"

post '/trigger/:script' do
  data = JSON.parse(request.body.read)
  args = data['args']
  options = munge_options(data['options'])
  input = data['input']

  responses = []
  Dir.foreach(TRIGGER_REPOS_DIR) do |repo|
    trigger = File.join(TRIGGER_REPOS_DIR, repo, "/triggers/#{params[:script]}")
    if File.exists?(trigger)
      stdout, stderr, status = Open3.capture3(
        trigger, *options, '--', *args, stdin_data: input
      )

      trigger_response = {
        profile: repo,
        contentType: 'text/plain',
        exitCode: status.exitstatus,
        result: stdout,
      }
      responses << trigger_response
    end
  end

  response = {responses: responses}
  content_type :json
  response.to_json
end

def munge_options(options)
  options.map do |key, value|
    prefix = key.length == 1 ? '-' : '--'
    option = "#{prefix}#{key}"

    if value == true
      # No argument.
      argument = nil
    elsif !value
      # Ignore the option.
      return nil
    else
      argument = value.to_s
    end

    [option, argument]
  end
  .flatten
  .reject {|arg| arg.nil?}
end
