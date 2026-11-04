# brewfile.rb <Brewfile…>: the Brewfile part of check_dotfiles. Evaluates each Brewfile the way `brew bundle`
# reads it, once for every kind of Mac (none, home, work), and prints each entry as "<file> <kind> <type> <name>".
# The Mac's own ~/.config/dotfiles/Brewfile is left out: HOME points nowhere. A Ruby error or a command brew
# bundle doesn't know stops it with the message. Runs on macOS's own Ruby 2.6 as well as Homebrew's.
class Brewfile
  attr_reader :entries

  def initialize
    @entries = []
  end

  %w[tap brew cask mas vscode whalebrew go cargo uv flatpak].each do |type|
    define_method(type) { |name, *_options| @entries << [type, name] }
  end

  # in a method of its own, so the Brewfile's variables (its `kind`) can't overwrite the caller's
  def evaluate(__code, __path)
    instance_eval(__code, __path)
  end
end

home = "/nonexistent/check_dotfiles"
kind_file = File.join(home, ".config/dotfiles/kind")
ENV["HOME"] = home
read = File.method(:read)

ARGV.each do |path|
  %w[none home work].each do |mac|
    # the kind file, as setup_machine writes it; missing for "none"
    File.define_singleton_method(:read) do |file, *args|
      next read.call(file, *args) unless File.expand_path(file) == kind_file
      raise Errno::ENOENT, file if mac == "none"

      "#{mac}\n"
    end
    brewfile = Brewfile.new
    begin
      brewfile.evaluate(read.call(path), path)
    rescue ScriptError, StandardError => e
      warn "#{path}, for a #{mac} Mac: #{e.message}"
      exit 1
    ensure
      File.singleton_class.send(:remove_method, :read)
    end
    brewfile.entries.each { |type, name| puts "#{path} #{mac} #{type} #{name}" }
  end
end
