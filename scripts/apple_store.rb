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

def inspect_status
  app = api('get', "/v1/apps/#{APP_ID}")['data']
  abort 'Unexpected bundle ID' unless app['attributes']['bundleId'] == 'net.ryuya-dev.mnc'
  versions = api('get', "/v1/apps/#{APP_ID}/appStoreVersions?limit=10")['data']
  puts JSON.generate(kind: 'versions', versions: versions.map { |v| {id: v['id'], **v['attributes'].select { |k, _| %w[versionString platform appStoreState releaseType].include?(k) }} })
  builds = api('get', "/v1/builds?filter%5Bapp%5D=#{APP_ID}&limit=10&sort=-uploadedDate&include=preReleaseVersion")
  release_versions = (builds['included'] || []).map { |v| [v['id'], v['attributes']] }.to_h
  puts JSON.generate(kind: 'builds', builds: builds['data'].map { |b| {id: b['id'], **b['attributes'].select { |k, _| %w[version processingState uploadedDate expired].include?(k) }, release: release_versions[b.dig('relationships', 'preReleaseVersion', 'data', 'id')]} })
  reviews = api('get', "/v1/reviewSubmissions?filter%5Bapp%5D=#{APP_ID}&limit=10")
  puts JSON.generate(kind: 'reviews', submissions: reviews['data'].map { |r| {id: r['id'], **r['attributes']} })
  infos = api('get', "/v1/apps/#{APP_ID}/appInfos?limit=200")['data']
  infos.each do |info|
    rating = api('get', "/v1/appInfos/#{info['id']}/ageRatingDeclaration")['data']
    puts JSON.generate(kind: 'age_rating', app_info_id: info['id'],
      app_info_state: info['attributes']['appStoreState'], rating_id: rating['id'],
      controls: rating['attributes'].select { |k, _| %w[socialMedia messagingAndChat userGeneratedContent advertising].include?(k) })
  end
end

def release_version
  source = File.read(File.expand_path('../pubspec.yaml', __dir__))
  match = source.match(/^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$/)
  raise 'Invalid release version' unless match
  match.captures
end

def complete_age_rating
  facts = JSON.parse(File.read(File.expand_path('../fastlane/app-store/age-rating-facts.json', __dir__)))
  infos = api('get', "/v1/apps/#{APP_ID}/appInfos?limit=200")['data']
  info = infos.find { |i| %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED].include?(i['attributes']['appStoreState']) }
  raise 'No editable app information found for age declaration' unless info
  rating = api('get', "/v1/appInfos/#{info['id']}/ageRatingDeclaration")['data']
  missing = facts.reject do |key, value|
    current = rating['attributes'][key]
    raise 'Age declaration conflicts with checked-in app facts' unless current.nil? || current == value
    current == value
  end
  return if missing.empty?
  api('patch', "/v1/ageRatingDeclarations/#{rating['id']}", data: {
    type: 'ageRatingDeclarations', id: rating['id'], attributes: missing
  })
  updated = api('get', "/v1/appInfos/#{info['id']}/ageRatingDeclaration")['data']
  raise 'Age declaration update was not confirmed' unless facts.all? { |k, v| updated['attributes'][k] == v }
end

# Explicitly authorized replacement of the old macOS 2.5.1 review. This is a
# separate action; ordinary submit/inspect never cancel a pending review.
def replace_previous_macos_review
  version_name, = release_version
  raise 'Replacement is scoped to the 2.5.2 release' unless version_name == '2.5.2'
  app = api('get', "/v1/apps/#{APP_ID}")['data']
  raise 'Unexpected bundle ID' unless app['attributes']['bundleId'] == 'net.ryuya-dev.mnc'
  versions = api('get', "/v1/apps/#{APP_ID}/appStoreVersions?limit=200")['data']
  old = versions.find { |v| v['attributes']['platform'] == 'MAC_OS' && v['attributes']['versionString'] == '2.5.1' }
  raise 'Expected old macOS 2.5.1 version was not found' unless old
  if %w[IN_REVIEW WAITING_FOR_REVIEW].include?(old['attributes']['appStoreState'])
    reviews = api('get', "/v1/reviewSubmissions?filter%5Bapp%5D=#{APP_ID}&limit=200")['data']
    review = reviews.find { |r| r['attributes']['platform'] == 'MAC_OS' && %w[IN_REVIEW WAITING_FOR_REVIEW].include?(r['attributes']['state']) }
    raise 'Expected macOS review was not found' unless review
    items = api('get', "/v1/reviewSubmissions/#{review['id']}/items?include=appStoreVersion&limit=200")
    ids = (items['included'] || []).select { |i| i['type'] == 'appStoreVersions' }.map { |i| i['id'] }
    raise 'Review contains other items; refusing cancellation' unless items['data'].length == 1 && ids == [old['id']]
    api('patch', "/v1/reviewSubmissions/#{review['id']}", data: {
      type: 'reviewSubmissions', id: review['id'], attributes: {canceled: true}
    })
    60.times do
      old = api('get', "/v1/appStoreVersions/#{old['id']}")['data']
      break if old['attributes']['appStoreState'] == 'DEVELOPER_REJECTED'
      sleep 5
    end
  end
  raise 'Old version did not become editable after cancellation' unless old['attributes']['appStoreState'] == 'DEVELOPER_REJECTED'
  updated = api('patch', "/v1/appStoreVersions/#{old['id']}", data: {
    type: 'appStoreVersions', id: old['id'], attributes: {versionString: version_name}
  })['data']
  raise 'Replacement version was not confirmed' unless updated['attributes']['versionString'] == version_name
  {platform: 'MAC_OS', previous_version: '2.5.1', version: version_name,
   status: updated['attributes']['appStoreState'], previous_review_withdrawn: true}
end

# Returns a status rather than canceling another version's review. The caller
# can safely retry after build processing or an earlier review has completed.
def submit_update(platform)
  raise 'Unsupported platform' unless %w[IOS MAC_OS].include?(platform)
  version_name, build_number = release_version
  app = api('get', "/v1/apps/#{APP_ID}")['data']
  raise 'Unexpected bundle ID' unless app['attributes']['bundleId'] == 'net.ryuya-dev.mnc'
  versions = api('get', "/v1/apps/#{APP_ID}/appStoreVersions?limit=200")['data']
  versions = versions.select { |v| v['attributes']['platform'] == platform }
  target = versions.find { |v| v['attributes']['versionString'] == version_name }
  if target && %w[WAITING_FOR_REVIEW IN_REVIEW PENDING_APPLE_RELEASE PENDING_DEVELOPER_RELEASE READY_FOR_SALE].include?(target['attributes']['appStoreState'])
    linked = api('get', "/v1/appStoreVersions/#{target['id']}/build")['data']
    raise 'Submitted version has a different build' unless linked && linked['attributes']['version'] == build_number
    return {platform: platform, version: version_name, build: build_number,
            status: target['attributes']['appStoreState'], already_submitted: true}
  end
  previous = versions.find do |v|
    v['attributes']['versionString'] != version_name &&
      %w[WAITING_FOR_REVIEW IN_REVIEW PENDING_APPLE_RELEASE PENDING_DEVELOPER_RELEASE].include?(v['attributes']['appStoreState'])
  end
  if previous
    return {platform: platform, version: version_name, status: 'BLOCKED_BY_EXISTING_REVIEW',
            previous_version: previous['attributes']['versionString'],
            previous_state: previous['attributes']['appStoreState']}
  end
  builds = api('get', "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=#{build_number}&limit=200&include=preReleaseVersion")
  releases = (builds['included'] || []).map { |v| [v['id'], v['attributes']] }.to_h
  build = builds['data'].find do |b|
    release = releases[b.dig('relationships', 'preReleaseVersion', 'data', 'id')]
    b['attributes']['version'] == build_number && release &&
      release['version'] == version_name && release['platform'] == platform
  end
  raise 'Matching uploaded build is missing or still processing' unless build &&
    build['attributes']['processingState'] != 'PROCESSING'
  raise 'Matching build is invalid or expired' unless
    build['attributes']['processingState'] == 'VALID' && !build['attributes']['expired']
  complete_age_rating
  published = versions.find { |v| v['attributes']['appStoreState'] == 'READY_FOR_SALE' }
  raise 'Published version is required to preserve listing and review details' unless published
  if target
    raise 'Version is not editable' unless %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED].include?(target['attributes']['appStoreState'])
  else
    target = api('post', '/v1/appStoreVersions', data: {
      type: 'appStoreVersions', attributes: {
        versionString: version_name, platform: platform,
        releaseType: published['attributes']['releaseType'],
        copyright: published['attributes']['copyright']
      }.reject { |_, v| v.nil? },
      relationships: {app: {data: {type: 'apps', id: APP_ID}}}
    })['data']
  end
  source_locales = api('get', "/v1/appStoreVersions/#{published['id']}/appStoreVersionLocalizations?limit=200")['data']
  target_locales = api('get', "/v1/appStoreVersions/#{target['id']}/appStoreVersionLocalizations?limit=200")['data']
  metadata_root = File.expand_path("../fastlane/app-store/#{platform == 'IOS' ? 'ios' : 'macos'}/metadata", __dir__)
  %w[ja en-US].each do |locale|
    notes = File.read(File.join(metadata_root, locale, 'release_notes.txt')).strip
    raise 'Release notes are missing' if notes.empty?
    localization = target_locales.find { |l| l['attributes']['locale'] == locale }
    if localization
      api('patch', "/v1/appStoreVersionLocalizations/#{localization['id']}", data: {
        type: 'appStoreVersionLocalizations', id: localization['id'], attributes: {whatsNew: notes}
      })
    else
      source = source_locales.find { |l| l['attributes']['locale'] == locale }
      raise "Published #{locale} listing is missing" unless source
      attrs = source['attributes'].select { |k, v| %w[locale description keywords marketingUrl supportUrl promotionalText].include?(k) && !v.nil? }
      attrs['whatsNew'] = notes
      localization = api('post', '/v1/appStoreVersionLocalizations', data: {
        type: 'appStoreVersionLocalizations', attributes: attrs,
        relationships: {appStoreVersion: {data: {type: 'appStoreVersions', id: target['id']}}}
      })['data']
    end
    screenshots = api('get', "/v1/appStoreVersionLocalizations/#{localization['id']}/appScreenshotSets?include=appScreenshots&limit=200")
    raise "#{locale} screenshots were not carried over; listing needs attention" unless
      (screenshots['included'] || []).any? { |s| s['type'] == 'appScreenshots' }
  end
  # New versions normally inherit these details. Copy only if absent, without
  # printing the private reviewer contact information or changing it.
  detail = api('get', "/v1/appStoreVersions/#{target['id']}/appStoreReviewDetail")['data']
  unless detail
    source = api('get', "/v1/appStoreVersions/#{published['id']}/appStoreReviewDetail")['data']
    raise 'Existing review contact is missing' unless source
    attrs = source['attributes'].select { |k, v| %w[contactFirstName contactLastName contactPhone contactEmail demoAccountRequired demoAccountName demoAccountPassword notes].include?(k) && !v.nil? }
    api('post', '/v1/appStoreReviewDetails', data: {type: 'appStoreReviewDetails', attributes: attrs,
      relationships: {appStoreVersion: {data: {type: 'appStoreVersions', id: target['id']}}}})
  end
  if build['attributes']['usesNonExemptEncryption'].nil?
    plist = File.read(File.expand_path("../#{platform == 'IOS' ? 'ios' : 'macos'}/Runner/Info.plist", __dir__))
    raise 'Export compliance needs review' unless plist.match?(/<key>ITSAppUsesNonExemptEncryption<\/key>\s*<false\s*\/>/)
    api('patch', "/v1/builds/#{build['id']}", data: {type: 'builds', id: build['id'], attributes: {usesNonExemptEncryption: false}})
  end
  api('patch', "/v1/appStoreVersions/#{target['id']}/relationships/build", data: {type: 'builds', id: build['id']})
  linked = api('get', "/v1/appStoreVersions/#{target['id']}/build")['data']
  raise 'Selected build does not match release' unless linked && linked['id'] == build['id']
  reviews = api('get', "/v1/reviewSubmissions?filter%5Bapp%5D=#{APP_ID}&limit=200")['data']
  open_reviews = reviews.select { |r| r['attributes']['platform'] == platform && !%w[COMPLETE CANCELED].include?(r['attributes']['state']) }
  raise 'Unexpected existing review submission; refusing to replace it' if open_reviews.length > 1 ||
    open_reviews.any? { |r| r['attributes']['state'] != 'READY_FOR_REVIEW' }
  review = open_reviews.first || api('post', '/v1/reviewSubmissions', data: {
    type: 'reviewSubmissions', attributes: {platform: platform},
    relationships: {app: {data: {type: 'apps', id: APP_ID}}}
  })['data']
  items = api('get', "/v1/reviewSubmissions/#{review['id']}/items?include=appStoreVersion&limit=200")
  item_versions = (items['included'] || []).select { |i| i['type'] == 'appStoreVersions' }.map { |i| i['id'] }
  raise 'Review contains unrelated items; refusing to change them' unless items['data'].empty? ||
    (items['data'].length == 1 && item_versions == [target['id']])
  if items['data'].empty?
    api('post', '/v1/reviewSubmissionItems', data: {type: 'reviewSubmissionItems', relationships: {
      reviewSubmission: {data: {type: 'reviewSubmissions', id: review['id']}},
      appStoreVersion: {data: {type: 'appStoreVersions', id: target['id']}}
    }})
  end
  ready = false
  10.times do
    latest = api('get', "/v1/appStoreVersions/#{target['id']}")['data']
    ready = latest['attributes']['appVersionState'] == 'READY_FOR_REVIEW'
    break if ready
    sleep 5
  end
  raise 'Version has not become ready for review' unless ready
  api('patch', "/v1/reviewSubmissions/#{review['id']}", data: {
    type: 'reviewSubmissions', id: review['id'], attributes: {submitted: true}
  })
  final = api('get', "/v1/reviewSubmissions/#{review['id']}")['data']
  raise 'Submission did not enter the review queue' unless %w[WAITING_FOR_REVIEW IN_REVIEW].include?(final['attributes']['state'])
  {platform: platform, version: version_name, build: build_number, review_id: review['id'], status: final['attributes']['state']}
end

if $PROGRAM_NAME == __FILE__
  case ARGV.first || 'inspect'
  when 'inspect'
    inspect_status
  when 'submit'
    deadline = Time.now + 900
    loop do
      begin
        puts JSON.generate(kind: 'submission', **submit_update(ARGV[1] || 'IOS'))
        break
      rescue => error
        raise unless error.message == 'Matching uploaded build is missing or still processing' && Time.now < deadline
        puts JSON.generate(kind: 'waiting', platform: ARGV[1] || 'IOS',
                           status: 'WAITING_FOR_BUILD_PROCESSING')
        $stdout.flush
        sleep 30
      end
    end
  when 'replace_previous_macos'
    puts JSON.generate(kind: 'replacement', **replace_previous_macos_review)
  else
    abort 'Unsupported action'
  end
end
