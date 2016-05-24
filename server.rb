
require 'json'
require 'sinatra'

post '/trigger/:script' do
  data = JSON.parse(request.body.read)
  args = data['args']
  options = munge_options(data['options'])

  triggers_with_name(params[:script]).map do |trigger|
    system(trigger, *options, '--', *args)

    # Required to prevent error until returning useful response.
    'Hello World'
  end
end

def triggers_with_name(name)
  Dir.glob("/opt/clusterware/var/lib/trigger/*/triggers/#{name}")
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
