
require 'json'
require 'json-schema'
require 'sinatra'
require 'open3'

TRIGGER_REPOS_DIR = "/opt/clusterware/var/lib/trigger/"

# TODO: Could validate structure more deeply e.g. that each arg and option key
# is a simple value and not an object or array.
TRIGGER_REQUEST_SCHEMA = {
  type: 'object',
  required: ['args', 'input', 'options'],
  properties: {
    args: {type: 'array'},
    input: {type: 'string'},
    options: {type: 'object'},
  }
}

post '/trigger/:script' do
  content_type :json
  data = JSON.parse(request.body.read)

  begin
    JSON::Validator.validate!(TRIGGER_REQUEST_SCHEMA, data)
  rescue JSON::Schema::ValidationError => e
    status 422
    return {error: e.message}.to_json
  end

  args = data['args']
  options = munge_options(data['options'])
  input = data['input']

  responses = []
  Dir.foreach(TRIGGER_REPOS_DIR) do |repo|
    trigger = File.join(TRIGGER_REPOS_DIR, repo, "/triggers/#{params[:script]}")
    if File.exists?(trigger)
      stdout, _stderr, status = Open3.capture3(
        trigger, *options, '--', *args, stdin_data: input
      )

      trigger_response = {
        profile: repo,
        exitCode: status.exitstatus,
      }

      first_line, *rest = stdout.lines
      if first_line && first_line.strip == '#json'
        trigger_response.merge!({
          contentType: 'application/json',
          result: JSON.parse(rest.join),
        })
      else
        trigger_response.merge!({
          contentType: 'text/plain',
          result: stdout,
        })
      end

      responses << trigger_response
    end
  end

  response = {responses: responses}
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
