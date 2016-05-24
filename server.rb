
require 'sinatra'

def triggers_with_name(name)
  Dir.glob("/opt/clusterware/var/lib/trigger/*/triggers/#{name}")
end

post '/trigger/:script' do
  triggers_with_name(params[:script]).map do |trigger|
    `#{trigger}`
  end
end
