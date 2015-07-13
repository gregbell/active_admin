language: ruby
install:
  - time ./script/travis_cache download_bundle
  - time gem install bundler # use the very latest Bundler
  - time bundle install --without development --path=./bundle
  - bundle clean # delete now-outdated gems
  - time ./script/travis_cache download_app
  - time bundle exec rake setup
  - time ./script/travis_cache upload
script:
  - time bundle exec rake test_with_coveralls
rvm:
  - 1.9
  - 2.1
  - 2.2
env:
  matrix:
    - "RAILS=3.2.22"
    - "RAILS=4.1.11"
    - "RAILS=4.2.2"
  global:
    secure: lRYUGVUV94eqrR7C0b0hhvp+W76NkLRAn6jkJGCbRCEojbeb3HlgK1P+nTDeIuiDmXksJOG6VD3ZiZAn9Plznj7I/MFh+ijgvk8eWj9QNxA8riaSEPAu5VYtPA+uaw1olUt196U3qXH+SaXB4sx5wdIUXpd9qxWWWsW11ia0Jzs=
matrix:
  fast_finish: true
  exclude:
    - rvm: 2.2
      env: "RAILS=3.2.22"
    - rvm: 2.1
      env: "RAILS=4.1.11"
    - rvm: 2.1
      env: "RAILS=4.2.2"
notifications:
  irc:
    channels:
      - "irc.freenode.org#activeadmin"
    on_success: change
    on_failure: always
    skip_join: true
    template:
      - "(%{branch}/%{commit} by %{author}): %{message} (%{build_url})"
