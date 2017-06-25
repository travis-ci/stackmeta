# stackmeta

Gets the meta from the stack at Travis CI.  YMMV

## Usage

### Web API

#### stack summary

Show a summary for stack `travis-ci-sugilite-trusty-1496867314` as json:

``` bash
curl 'http://localhost:9292/travis-ci-sugilite-trusty-1496867314'
```

The same, in plaintext:

``` bash
curl -H 'Accept: text/plain' 'http://localhost:9292/travis-ci-sugilite-trusty-1496867314'

# or

curl 'http://localhost:9292/travis-ci-sugilite-trusty-1496867314?format=text'
```

#### stack summary with expanded item(s)

Expand individual item(s) in a stack summary:

``` bash
curl 'http://localhost:9292/travis-ci-sugilite-trusty-1496867314?items=dpkg-manifest.json,system_info.json'
```

The same, in plaintext:

``` bash
curl -H 'Accept: text/plain' 'http://localhost:9292/travis-ci-sugilite-trusty-1496867314?items=dpkg-manifest.json,system_info.json'

# or

curl 'http://localhost:9292/travis-ci-sugilite-trusty-1496867314?items=dpkg-manifest.json,system_info.json&format=text'
```

#### stack diff

Diff the dpkg manifest between two stacks:

``` bash
curl 'http://localhost:9292/diff/sugilite-trusty-1496867314/sugilite-trusty-1498161108?items=dpkg-manifest.json'
```

The same, in plaintext:

``` bash
curl -H 'Accept: text/plain' 'http://localhost:9292/diff/sugilite-trusty-1496867314/sugilite-trusty-1498161108?items=dpkg-manifest.json'

# or

curl 'http://localhost:9292/diff/sugilite-trusty-1496867314/sugilite-trusty-1498161108?items=dpkg-manifest.json&format=text'
```

## License

See [LICENSE](./LICENSE) :tada:
