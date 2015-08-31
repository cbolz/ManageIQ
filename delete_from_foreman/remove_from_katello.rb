#
#            Automate Method
#

begin
  @method = 'remove_foreman'
  $evm.log("info", "#{@method} - EVM Automate Method Started")

	require 'rest-client'
	require 'json'

  def get_json(location)
    $evm.log("info", "Execute Query #{location} as user #{@foreman_user} with password #{@foreman_password}")

  	response = RestClient::Request.new(
  		:method => :get,
  		:url => location,
  		:verify_ssl => false,
  		:user => @foreman_user,
  		:password => @foreman_password,
  		:headers => { :accept => :json,
  		:content_type => :json }
  	).execute

  	results = JSON.parse(response.to_str)
  end

  def put_json(location, json_data)
  	response = RestClient::Request.new(
  		:method => :put,
  		:url => location,
  		:verify_ssl => false,
  		:user => @foreman_user,
  		:password => @foreman_password,
  		:headers => { :accept => :json,
  		:content_type => :json},
  		:payload => json_data
  	).execute
  	results = JSON.parse(response.to_str)
  end

  # Dump all of root's attributes to the log
  $evm.root.attributes.sort.each { |k, v| $evm.log("info", "#{@method} Root:<$evm.root> Attribute - #{k}: #{v}")}

  vm=$evm.root["vm"]
  if not vm.hostnames[0].nil?
		host=vm.hostnames[0]
		$evm.log("info", "Found FQDN #{host} for this VM")
	else
		host="#{vm.name}.example.com"
		$evm.log("info", "Found no FQDN for this VM, will try #{host} instead")
	end

	@foreman_host = $evm.object['foreman_host']
	@foreman_user = $evm.object['foreman_user']
	@foreman_password = $evm.object.decrypt('foreman_password')

	url = "https://#{@foreman_host}/api/v2/"
	katello_url = "https://#{@foreman_host}/katello/api/v2/"

	systems = get_json(katello_url+"systems")
  uuid = {}
  hostExists = false
  systems['results'].each do |system|
  	if system['name'].include? host
  		$evm.log("Host ID #{system['id']}")
  		$evm.log("Host UUID #{system['uuid']}")
  		uuid = system['uuid'].to_s
  		hostExists = true
      break
  	end
  end

  if !hostExists
    $evm.log("info", "Host #{host} not found on Satellite")
    exit MIQ_OK
  end

  uri=katello_url+"systems/"+uuid+"/"

  request = RestClient::Request.new(
  	method: :delete,
  	url: uri,
  	headers: @headers,
  	verify_ssl: OpenSSL::SSL::VERIFY_NONE
  )

  $evm.log("info","Calling DELETE URL #{uri}")
  result=request.execute
  $evm.log("info", "Result: #{result}")

  #
  # Exit method
  #
  $evm.log("info", "#{@method} - EVM Automate Method Ended")
  exit MIQ_OK

  #
  # Set Ruby rescue behavior
  #
rescue => err
  $evm.log("error", "#{@method} - [#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end

exit()
