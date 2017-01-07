require "path_expander"
require "flog"

module CC
  module Engine
    class Flog
      VERSION = "1.0.0"

      attr_accessor :dir
      attr_accessor :config
      attr_accessor :io
      attr_accessor :flog
      attr_accessor :files

      DEFAULTS = {
                  "include_paths" => ["."]
                 }

      def initialize(root, config = {}, io = STDOUT)
        self.dir    = root
        self.config = DEFAULTS.merge config
        self.io     = io
        self.flog   = ::Flog.new :all => true, :continue => true

        paths = config["include_paths"].dup
        expander = PathExpander.new paths, "**/*.{rb,rake}"
        self.files = expander.process.select { |s| s =~ /\.(?:rb|rake)$/ }
      end

      def run
        Dir.chdir dir do
          flog.flog(*files)

          flog.each_by_score do |name, score, call_list|
            location = flog.method_locations[name]

            next unless location # XXX#main is location-less, skip for now

            datum = "%s scored %.1f" % [name, score]

            warn issue(datum, location).inspect
            io.print issue(datum, location).to_json
            io.print "\0"
          end
        end
      end

      def issue datum, location
        file, line = location.split(":", 2)
        line = line.to_i
        {
         "type"        => "issue",
         "check_name"  => "Flog Score",
         "description" => datum,
         "categories"  => ["Complexity"],
         "location"    => {
                           "path"  => file,
                           "lines" => {"begin" => line, "end" => line}
                          }
        }
      end
    end
  end
end
