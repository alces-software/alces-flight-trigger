
require 'json'
require 'json-schema'
require 'sinatra/base'
require 'open3'

class Server < Sinatra::Application
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

  before do
    content_type :json
  end

  post('/trigger/:script') do
    parse_trigger_request
    if @error
      return
    end

    response = {responses: trigger_responses}
    response.to_json
  end

  private

  def parse_trigger_request
    begin
      data = JSON.parse(request.body.read)
      JSON::Validator.validate!(TRIGGER_REQUEST_SCHEMA, data)
    rescue JSON::ParserError => e
      @error = "Received invalid request JSON"
    rescue JSON::Schema::ValidationError => e
      @error = e.message
    ensure
      if @error
        status 422
        body({error: @error}.to_json)
        return
      end
    end

    @args = data['args']
    @options = munge_options(data['options'])
    @input = data['input']
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

  def trigger_responses
    Dir.entries(TRIGGER_REPOS_DIR).map do |repo|
      trigger = File.join(TRIGGER_REPOS_DIR, repo, "/triggers/#{params[:script]}")
      if File.exists?(trigger)
        begin
          stdout, _stderr, status = Open3.capture3(
            trigger, *@options, '--', *@args, stdin_data: @input
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

        rescue => e
          {
            profile: repo,
            error: e.message,
          }
        else
          trigger_response
        end
      end
    end
    .reject {|arg| arg.nil?}
  end
end
