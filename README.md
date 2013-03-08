[![Build Status](https://travis-ci.org/futures/icemelt.png?branch=master)](https://travis-ci.org/futures/icemelt)

This is a Sinatra application that mimics the AWS Glacier API (more or
less),  so we can do (cross-language/distributed) test-driven development against the Glacier API, without waiting hours (and spending $$$) to retrieve content.

```bash
$ thin start
```

Or, tweak the retrieve-archive delay (in seconds):

```bash
$ MAX_COMPLETION_TIME_DELAY=120 thin start
```

Then, you can point your AWS REST client at the local Glacier mock, e.g.:

```ruby
Fog::AWS::Glacier.new :aws_access_key_id => '', :aws_secret_access_key => '', :scheme => 'http', :host => 'localhost', :port => '3000'}
```

Note that the mock does not perform the same authorization and HMAC checking, just implements the REST endpoints.
