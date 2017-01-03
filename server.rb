
require 'json'
require 'json-schema'
require 'sinatra/base'
require 'open3'

class Server < Sinatra::Application
  TRIGGER_REPOS_DIR = "#{ENV['cw_ROOT']}/var/lib/triggers"
  CREDENTIALS_FILE = File.join(TRIGGER_REPOS_DIR, '.credentials')

  # TODO: Could validate structure more deeply e.g. that each arg and option key
  # is a simple value and not an object or array.
  TRIGGER_REQUEST_SCHEMA = {
    type: 'object',
    required: ['args', 'input', 'options'],
    properties: {
      args: {type: 'array'},
      input: {type: ['string', nil]},
      options: {type: 'object'},
    }
  }

  configure do
    set :server, :puma
  end

  use Rack::Auth::Basic, "Username and password required" do |username, password|
    username == credentials[:username] && password == credentials[:password]
  end

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

  def self.credentials
    username, password = File.readlines(CREDENTIALS_FILE).first.chomp.split(':')
    {
      username: username,
      password: password,
    }
  end

  def parse_trigger_request
    data = JSON.parse(request.body.read)
    JSON::Validator.validate!(TRIGGER_REQUEST_SCHEMA, data)

    @trigger_name = params[:script]
    @args = data['args']
    @options = munge_options(data['options'])
    @input = data['input']
  rescue JSON::ParserError => e
    @error = "Received invalid request JSON"
  rescue JSON::Schema::ValidationError => e
    @error = e.message
  ensure
    if @error
      status 422
      body({error: @error}.to_json)
    end
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
      run_trigger_for_repo(repo)
    end
    .reject {|arg| arg.nil?}
  end

  def run_trigger_for_repo(repo)
    trigger = File.join(TRIGGER_REPOS_DIR, repo, "/triggers/#{@trigger_name}")
    return nil if !File.exists?(trigger)

    stdout, exit_code = run_trigger(trigger)
    first_line, *rest = stdout.lines

    {
      profile: repo,
      exitCode: exit_code
    }
    .merge(
      json_output_indicator?(first_line) ?
      {
        contentType: 'application/json',
        result: JSON.parse(rest.join),
      }
      :
      {
        contentType: 'text/plain',
        result: stdout,
      }
    )
  rescue => e
    {
      profile: repo,
      error: e.message,
    }
  end

  def run_trigger(trigger)
    if development?
      puts
      puts "Running trigger '#{trigger}'"
      puts '=========='
      puts "Options: '#{@options}'"
      puts "Args: '#{@args}'"
      puts "Stdin: '#{@input}'"
      puts
    end

    stdout, stderr, status = Open3.capture3(
      trigger, *@options, *@args, stdin_data: @input
    )
    exit_code = status.exitstatus

    if development?
      puts "Result for trigger '#{trigger}'"
      puts '=========='
      puts "Exit code: '#{exit_code}'"
      puts "Stdout: '#{stdout}'"
      puts "Stderr: '#{stderr}'"
      puts
    end

    return [stdout, exit_code]
  end

  def development?
    ENV['RACK_ENV'] == 'development'
  end

  def json_output_indicator?(line)
    line && line.strip == '#json'
  end
end
