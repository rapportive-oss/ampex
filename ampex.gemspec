Gem::Specification.new do |s|
  s.name = "ampex"
  s.version = "1.1.1"
  s.platform = Gem::Platform::RUBY
  s.author = "Conrad Irwin"
  s.email = "conrad.irwin@gmail.com"
  s.homepage = "http://github.com/rapportive-oss/ampex"
  s.summary = "Provides a meta-variable X which can be used to create procs more prettily"
  s.description = "Why would you want to write { |x| x['one'] } when you can write &X['one'], why indeed."
  s.files = ["lib/ampex.rb", "README.markdown", "LICENSE.MIT"]
  s.require_path = "lib"
  s.add_dependency 'blankslate'
end
