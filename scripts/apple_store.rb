require 'openssl'
require 'base64'
require 'json'
require 'net/http'
require 'uri'

APP_ID = '6757244924'
def b64(value)
  Base64.urlsafe_encode64(value, padding: false)
end
def token
  now = Time.now.to_i
  input = [b64({alg: 'ES256', kid: ENV.fetch('APP_STORE_CONNECT_API_KEY_ID'), typ: 'JWT'}.to_json),
           b64({iss: ENV.fetch('APP_STORE_CONNECT_ISSUER_ID'), iat: now,
                exp: now + 1100, aud: 'appstoreconnect-v1'}.to_json)].join('.')
  key = OpenSSL::PKey.read(Base64.decode64(ENV.fetch('APP_STORE_CONNECT_API_KEY_CONTENT')))
  der = key.sign(OpenSSL::Digest::SHA256.new, input)
  signature = OpenSSL::ASN1.decode(der).value.map { |n| [n.value.to_s(16).rjust(64, '0')].pack('H*') }.join
  input + '.' + b64(signature)
end
def api(method, path, body = nil)
  uri = URI('https://api.appstoreconnect.apple.com' + path)
  request = Net::HTTP.const_get(method.capitalize).new(uri)
  request['Authorization'] = 'Bearer ' + token
  if body
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(body)
  end
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
  raise "#{method} #{uri.path}: #{response.code} #{response.body.to_s[0, 2000]}" unless response.code.to_i.between?(200, 299)
  response.body.to_s.empty? ? {} : JSON.parse(response.body)
end

if ARGV.first.nil? || ARGV.first == 'inspect'
  app = api('get', "/v1/apps/#{APP_ID}")['data']
  abort 'Unexpected bundle ID' unless app['attributes']['bundleId'] == 'net.ryuya-dev.mnc'
  versions = api('get', "/v1/apps/#{APP_ID}/appStoreVersions?limit=10")['data']
  puts JSON.generate(kind: 'versions', versions: versions.map { |v| {id: v['id'], **v['attributes'].select { |k, _| %w[versionString platform appStoreState releaseType].include?(k) }} })
  builds = api('get', "/v1/builds?filter%5Bapp%5D=#{APP_ID}&limit=10&sort=-uploadedDate&include=preReleaseVersion")
  release_versions = (builds['included'] || []).map { |v| [v['id'], v['attributes']] }.to_h
  puts JSON.generate(kind: 'builds', builds: builds['data'].map { |b| {id: b['id'], **b['attributes'].select { |k, _| %w[version processingState uploadedDate expired].include?(k) }, release: release_versions[b.dig('relationships', 'preReleaseVersion', 'data', 'id')]} })
  reviews = api('get', "/v1/reviewSubmissions?filter%5Bapp%5D=#{APP_ID}&limit=10")
  puts JSON.generate(kind: 'reviews', submissions: reviews['data'].map { |r| {id: r['id'], **r['attributes']} })
else
  abort 'Unsupported action'
end
