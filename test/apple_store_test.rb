require_relative '../scripts/apple_store'

# Offline guard tests: these fixtures never authenticate or access the network.
def api(method, path, body = nil)
  $requests << [method, path]
  raise 'Unexpected write in a guarded scenario' unless method == 'get'
  $fixtures.fetch(path) { raise "Unexpected read: #{path}" }
end
def version(id, platform, name, state)
  {'id' => id, 'attributes' => {'platform' => platform, 'versionString' => name,
    'appStoreState' => state, 'releaseType' => 'AFTER_APPROVAL'}}
end
def scenario(name, versions, expected_error: nil)
  $requests = []
  $fixtures = {
    "/v1/apps/#{APP_ID}" => {'data' => {'attributes' => {'bundleId' => 'net.ryuya-dev.mnc'}}},
    "/v1/apps/#{APP_ID}/appStoreVersions?limit=200" => {'data' => versions},
    "/v1/builds?filter%5Bapp%5D=#{APP_ID}&filter%5Bversion%5D=38&limit=200&include=preReleaseVersion" => {'data' => [], 'included' => []}
  }
  begin
    yield
    raise 'Expected a guard to reject the action' if expected_error
  rescue => error
    raise unless expected_error && error.message.include?(expected_error)
  end
  raise 'A guarded scenario attempted a write' unless $requests.all? { |method, _| method == 'get' }
  puts "PASS: #{name}"
end

raise 'Release version fixture needs updating' unless release_version == ['2.5.2', '38']
scenario('preserves another macOS version in review', [version('old', 'MAC_OS', '2.5.1', 'IN_REVIEW')]) do
  result = submit_update('MAC_OS')
  raise 'Existing review was not preserved' unless result[:status] == 'BLOCKED_BY_EXISTING_REVIEW'
end
scenario('does not resubmit an already submitted release', [version('target', 'IOS', '2.5.2', 'WAITING_FOR_REVIEW')]) do
  $fixtures['/v1/appStoreVersions/target/build'] = {'data' => {'attributes' => {'version' => '38'}}}
  raise 'Submission was not recognized' unless submit_update('IOS')[:already_submitted]
end
scenario('rejects an unexpected bundle ID', [], expected_error: 'Unexpected bundle ID') do
  $fixtures["/v1/apps/#{APP_ID}"]['data']['attributes']['bundleId'] = 'other.app'
  submit_update('IOS')
end
scenario('rejects a submitted release with the wrong build', [version('target', 'IOS', '2.5.2', 'WAITING_FOR_REVIEW')], expected_error: 'different build') do
  $fixtures['/v1/appStoreVersions/target/build'] = {'data' => {'attributes' => {'version' => '36'}}}
  submit_update('IOS')
end
scenario('does not mutate metadata before the new build is available', [], expected_error: 'Matching uploaded build') do
  submit_update('IOS')
end
scenario('does not confuse a macOS review with an iOS review', [version('old', 'MAC_OS', '2.5.1', 'IN_REVIEW')], expected_error: 'Matching uploaded build') do
  submit_update('IOS')
end
scenario('replacement refuses other version numbers', [version('old', 'MAC_OS', '2.5.0', 'IN_REVIEW')], expected_error: 'Expected old macOS 2.5.1') do
  replace_previous_macos_review
end
scenario('replacement refuses a review with unrelated items', [version('old', 'MAC_OS', '2.5.1', 'IN_REVIEW')], expected_error: 'Review contains other items') do
  $fixtures["/v1/reviewSubmissions?filter%5Bapp%5D=#{APP_ID}&limit=200"] = {'data' => [
    {'id' => 'review', 'attributes' => {'platform' => 'MAC_OS', 'state' => 'IN_REVIEW'}}
  ]}
  $fixtures['/v1/reviewSubmissions/review/items?include=appStoreVersion&limit=200'] = {
    'data' => [{'id' => 'item'}], 'included' => [{'type' => 'appStoreVersions', 'id' => 'unrelated'}]
  }
  replace_previous_macos_review
end
scenario('second platform can reuse an already-complete age declaration', []) do
  $fixtures["/v1/apps/#{APP_ID}/appInfos?limit=200"] = {'data' => [
    {'id' => 'info', 'attributes' => {'appStoreState' => 'WAITING_FOR_REVIEW'}}
  ]}
  $fixtures['/v1/appInfos/info/ageRatingDeclaration'] = {'data' => {
    'id' => 'rating', 'attributes' => {'socialMedia' => false, 'socialMediaAgeRestricted' => false}
  }}
  complete_age_rating
end
scenario('ordinary submission does not modify a locked incomplete age declaration', [], expected_error: 'Age declaration is locked') do
  $fixtures["/v1/apps/#{APP_ID}/appInfos?limit=200"] = {'data' => [
    {'id' => 'info', 'attributes' => {'appStoreState' => 'IN_REVIEW'}}
  ]}
  $fixtures['/v1/appInfos/info/ageRatingDeclaration'] = {'data' => {
    'id' => 'rating', 'attributes' => {'socialMedia' => nil, 'socialMediaAgeRestricted' => nil}
  }}
  complete_age_rating
end
