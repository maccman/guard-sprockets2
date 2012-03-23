require 'guard/sprockets2/version'
require 'guard'
require 'guard/guard'
require 'rake'
require 'sprockets'

module Guard
  class Sprockets2 < Guard
    def initialize(watchers = [], options = {})
      super
      @compiler = Compiler.new(options)
    end
    
    def start
      compile_assets
    end
    
    def run_all
      compile_assets
    end
    
    def run_on_change(paths = [])
      compile_assets
    end
    
    class Compiler
      def initialize(options = {})
        @sprockets = options[:sprockets]
        @assets_path = options[:assets_path]
        @precompile = options[:precompile]
        if defined?(Rails)
          @sprockets ||= Rails.application.assets
          @assets_path ||= File.join(Rails.public_path, Rails.application.config.assets.prefix)
          @precompile ||= Rails.application.config.assets.precompile
        else
          @assets_path ||= "#{Dir.pwd}/public/assets"
          @precompile ||= [ /\w+\.(?!js|css).+/, /application.(css|js)$/ ]
        end
      end
      
      def clean
      end
      
      def compile
        target = Pathname.new(@assets_path)
        @precompile.each do |path|
          @sprockets.each_logical_path do |logical_path|
            if path.is_a?(Regexp)
              next unless path.match(logical_path)
            else
              next unless File.fnmatch(path.to_s, logical_path)
            end

            if asset = @sprockets.find_asset(logical_path)
              filename = target.join(asset.logical_path)
              FileUtils.mkdir_p filename.dirname
              asset.write_to(filename)
            end
          end
        end
      end
    end
    
    protected
    
    def compile_assets
      @compiler.clean
      msg = "Compiling assets... "
      print msg unless ENV["GUARD_ENV"] == "test"
      Notifier.notify(msg, :title => 'Sprockets compile')
      time_taken = time do
        @compiler.compile
      end
      msg = "completed in #{time_taken} seconds"
      UI.info msg
      Notifier.notify(msg, :title => 'Sprockets compile')
    rescue ExecJS::ProgramError => e
      UI.error e.to_s
      puts e.backtrace.join("\n")
      Notifier.notify('Error compiling assets!', :title => 'Sprockets compile', :image => :error)
    end
    
    def time(&block)
      start = Time.now
      yield
      finish = Time.now
      finish - start
    end
  end
end